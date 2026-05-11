# 在 Windows 上为 @cloudbase/cli 打补丁：压缩云函数代码时 ZIP 内路径统一为 / ，
# 避免 Linux 解压后没有 backend/ 目录，导致 uvicorn 加载 backend.main:app 报 ModuleNotFoundError，
# 网关表现为 x-cloudbase-upstream-status-code: 443。
#
# 用法（部署前执行一次，或在 npx 更新 CLI 缓存后重跑）:
#   cd deploy/cloudbase
#   .\patch-cloudbase-cli-zip.ps1
#
# 会扫描 %LOCALAPPDATA%\npm-cache\_npx 下所有 @cloudbase\cli\dist\standalone\cli.js 副本。

$ErrorActionPreference = "Stop"
$marker = "walkPosixCloudBaseWinFix"

# 不用中文注释做字面匹配，避免脚本编码与 cli.js 不一致导致匹配失败
$oldCompressRegex = '(?ms)^\s{8}// append files from a glob pattern\s*\r?\n\s{8}archive\.glob\(pattern, \{\s*\r?\n\s{12}//[^\r\n]*\r?\n\s{12}cwd: dirPath,\s*\r?\n\s{12}ignore: ignore,\s*\r?\n\s{12}dot: true\s*\r?\n\s{8}\}\);'

$newCompress = @'
        // ZIP entry names use '/' (patched by magnetic-run patch-cloudbase-cli-zip.ps1 for Windows)
        (function walkPosixCloudBaseWinFix(ar, baseDir, relPrefix, ign) {
            function ignored(rel) {
                if (!ign || !ign.length) return false;
                for (const raw of ign) {
                    const g = String(raw).replace(/\\/g, '/');
                    if (!g) continue;
                    if (g === 'node_modules' || g === 'node_modules/**/*') {
                        if (rel === 'node_modules' || rel.startsWith('node_modules/')) return true;
                        continue;
                    }
                    if (rel === g || rel.startsWith(g + '/')) return true;
                }
                return false;
            }
            let entries;
            try {
                entries = fs_extra_1.default.readdirSync(baseDir, { withFileTypes: true });
            }
            catch (e) {
                return;
            }
            for (const ent of entries) {
                const rel = relPrefix ? relPrefix + '/' + ent.name : ent.name;
                if (ignored(rel)) continue;
                if (ent.name === '__pycache__') continue;
                const abs = path_1.default.join(baseDir, ent.name);
                if (ent.isDirectory()) {
                    walkPosixCloudBaseWinFix(ar, abs, rel, ign);
                }
                else if (ent.isFile()) {
                    ar.file(abs, { name: rel });
                }
            }
        })(archive, path_1.default.resolve(dirPath), '', ignore || []);
'@

$oldZipFilesRegex = "(?ms)^\s{16}if \(fs_1\.default\.statSync\(filePath\)\.isDirectory\(\)\) \{\s*\r?\n\s{20}// append files from a glob pattern\s*\r?\n\s{20}archive\.glob\('\*\*/\*', \{\s*\r?\n\s{24}//[^\r\n]*\r?\n\s{24}cwd: filePath,\s*\r?\n\s{24}ignore: ignore,\s*\r?\n\s{24}dot: true\s*\r?\n\s{20}\}\);\s*\r?\n\s{16}\}"

$newZipFiles = @'
                if (fs_1.default.statSync(filePath).isDirectory()) {
                    (function walkPosixCloudBaseWinFix(ar, baseDir, relPrefix, ign) {
                        function ignored(rel) {
                            if (!ign || !ign.length) return false;
                            for (const raw of ign) {
                                const g = String(raw).replace(/\\/g, '/');
                                if (!g) continue;
                                if (g === 'node_modules' || g === 'node_modules/**/*') {
                                    if (rel === 'node_modules' || rel.startsWith('node_modules/')) return true;
                                    continue;
                                }
                                if (rel === g || rel.startsWith(g + '/')) return true;
                            }
                            return false;
                        }
                        let entries;
                        try {
                            entries = fs_1.default.readdirSync(baseDir, { withFileTypes: true });
                        }
                        catch (e) {
                            return;
                        }
                        for (const ent of entries) {
                            const rel = relPrefix ? relPrefix + '/' + ent.name : ent.name;
                            if (ignored(rel)) continue;
                            if (ent.name === '__pycache__') continue;
                            const abs = path_1.default.join(baseDir, ent.name);
                            if (ent.isDirectory()) {
                                walkPosixCloudBaseWinFix(ar, abs, rel, ign);
                            }
                            else if (ent.isFile()) {
                                ar.file(abs, { name: rel });
                            }
                        }
                    })(archive, path_1.default.resolve(filePath), '', ignore || []);
                }
'@

$root = Join-Path $env:LOCALAPPDATA "npm-cache\_npx"
if (-not (Test-Path $root)) {
    Write-Host "No npx cache at $root; skip."
    exit 0
}

$files = Get-ChildItem -Path $root -Recurse -Filter "cli.js" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '@cloudbase\\cli\\dist\\standalone\\cli\.js$' }

if (-not $files) {
    Write-Host "No @cloudbase/cli dist/standalone/cli.js under $root. Run npx @cloudbase/cli once, then re-run this script."
    exit 0
}

function Normalize-Lf([string] $s) {
    return ($s -replace "`r`n", "`n").TrimEnd("`r", "`n")
}

$newC = Normalize-Lf $newCompress
$newZ = Normalize-Lf $newZipFiles

foreach ($f in $files) {
    $raw = [System.IO.File]::ReadAllText($f.FullName)
    $text = Normalize-Lf $raw
    if ($text.Contains($marker)) {
        Write-Host "Already patched: $($f.FullName)"
        continue
    }
    if ($text -notmatch $oldCompressRegex) {
        Write-Host "WARN: compressToZip blob not found (CLI version changed?): $($f.FullName)"
        continue
    }
    if ($text -notmatch $oldZipFilesRegex) {
        Write-Host "WARN: zipFiles blob not found: $($f.FullName)"
        continue
    }
    # compressToZip 在 bundle 内重复 3 次，全部替换
    $text2 = [regex]::Replace($text, $oldCompressRegex, $newC)
    $text2 = [regex]::Replace($text2, $oldZipFilesRegex, $newZ, 1)
    # 写回时保留原文件换行风格（多为 CRLF）
    $out = if ($raw.Contains("`r`n")) { ($text2 -replace "(?<!`r)`n", "`r`n") } else { $text2 }
    [System.IO.File]::WriteAllText($f.FullName, $out)
    Write-Host "Patched: $($f.FullName)"
}

Write-Host "Done."
