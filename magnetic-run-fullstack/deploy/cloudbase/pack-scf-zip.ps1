# 从仓库 canonical 路径打云函数 zip，避免 backapp 与 backend 不同步。
# 用法: cd deploy/cloudbase; .\pack-scf-zip.ps1
# 产出: 仓库根目录下的 scf-deploy.zip（根内含 scf_bootstrap、scf_site_packages、backend、magrun、frontend/dist、requirements.txt）
# 打包前请先执行: .\install-scf-site-packages.ps1
# 在 Windows 上用 npx @cloudbase/cli 上传目录时，CLI 默认 zip 会用反斜杠作路径分隔符，Linux 解压后 import backend 会失败；部署前请执行一次: .\patch-cloudbase-cli-zip.ps1（会修补本机 npx 缓存里的 cli.js）。
#
# 控制台需配（云函数环境变量）:
#   HTTP_ROUTE_PREFIX=/my-api
#   CORS_ORIGINS=https://你的静态站域名.tcloudbaseapp.com
# 超时建议 >= 60s；内存按套餐加大；开启「自动安装依赖」并保证根目录有 requirements.txt

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Add-ZipFileEntry {
    param(
        [System.IO.Compression.ZipArchive] $Archive,
        [string] $DiskPath,
        [string] $EntryName
    )
    $name = $EntryName.Replace('\', '/')
    $entry = $Archive.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    try {
        $fileStream = [System.IO.File]::OpenRead($DiskPath)
        try {
            $fileStream.CopyTo($entryStream)
        }
        finally {
            $fileStream.Dispose()
        }
    }
    finally {
        $entryStream.Dispose()
    }
}

function Add-ZipDirectoryTree {
    param(
        [System.IO.Compression.ZipArchive] $Archive,
        [string] $FolderPath,
        [string] $EntryPrefix
    )
    $root = [System.IO.Path]::GetFullPath($FolderPath).TrimEnd('\')
    $prefix = $EntryPrefix.Trim('/').Replace('\', '/')
    Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($root.Length).TrimStart('\')
        $entryPath = ($prefix + '/' + $rel).Replace('\', '/')
        Add-ZipFileEntry -Archive $Archive -DiskPath $_.FullName -EntryName $entryPath
    }
}

$here = $PSScriptRoot
$bootstrapSrc = Join-Path $here "scf_bootstrap"
$boot = [System.IO.File]::ReadAllText($bootstrapSrc)
$boot = $boot -replace "`r`n", "`n" -replace "`r", "`n"
$utf8nobom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($bootstrapSrc, $boot.TrimEnd() + "`n", $utf8nobom)
$repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
$out = Join-Path $repoRoot "scf-deploy.zip"
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("magrun-scf-" + [Guid]::NewGuid().ToString("n"))

New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $site = Join-Path $here "scf_site_packages"
    if (-not (Test-Path $site)) {
        throw "缺少目录 scf_site_packages。请先在本目录执行: .\install-scf-site-packages.ps1"
    }

    Copy-Item -LiteralPath (Join-Path $here "scf_bootstrap") -Destination (Join-Path $temp "scf_bootstrap") -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "backend\requirements.txt") -Destination (Join-Path $temp "requirements.txt") -Force

    $siteDst = Join-Path $temp "scf_site_packages"
    New-Item -ItemType Directory -Path $siteDst | Out-Null
    robocopy $site $siteDst /MIR /XD __pycache__ .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy scf_site_packages failed: $LASTEXITCODE" }

    $beSrc = Join-Path $repoRoot "backend"
    $beDst = Join-Path $temp "backend"
    New-Item -ItemType Directory -Path $beDst | Out-Null
    robocopy $beSrc $beDst /E /XD .venv __pycache__ .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy backend failed: $LASTEXITCODE" }

    $mgSrc = Join-Path $repoRoot "magrun"
    $mgDst = Join-Path $temp "magrun"
    New-Item -ItemType Directory -Path $mgDst | Out-Null
    robocopy $mgSrc $mgDst /E /XD __pycache__ .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy magrun failed: $LASTEXITCODE" }

    # Same parent as backend on CloudBase: ROOT is repo root next to backend/; FRONTEND_DIST = ROOT/frontend/dist (backend/main.py).
    $feRoot = Join-Path $repoRoot "frontend"
    $feDistSrc = Join-Path $feRoot "dist"
    $feIndex = Join-Path $feDistSrc "index.html"
    if (-not (Test-Path $feIndex)) {
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            throw "Missing frontend/dist/index.html and npm not in PATH. Run: cd frontend; npm install; npm run build"
        }
        Write-Host "Missing frontend/dist; running npm run build in frontend/ ..."
        Push-Location $feRoot
        try {
            if (Test-Path (Join-Path $feRoot "package-lock.json")) {
                npm ci 2>&1 | Out-Host
            }
            else {
                npm install 2>&1 | Out-Host
            }
            if ($LASTEXITCODE -ne 0) { throw "frontend npm install/ci failed: $LASTEXITCODE" }
            npm run build 2>&1 | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "frontend npm run build failed: $LASTEXITCODE" }
        }
        finally {
            Pop-Location
        }
    }
    if (-not (Test-Path $feIndex)) {
        throw "frontend/dist/index.html still missing. Run: cd frontend; npm run build"
    }
    $feDstTree = Join-Path $temp $(Join-Path "frontend" "dist")
    New-Item -ItemType Directory -Path (Split-Path $feDstTree -Parent) -Force | Out-Null
    robocopy $feDistSrc $feDstTree /MIR /XD .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy frontend dist failed: $LASTEXITCODE" }
    if ($global:LASTEXITCODE -lt 8) { $global:LASTEXITCODE = 0 }

    if (Test-Path $out) { Remove-Item $out -Force }
    # Compress-Archive 在 Windows 下会把路径写成 backend\main.py；Linux 解压后可能没有 backend/ 目录，导致 import backend 失败。此处统一用 / 作为 ZIP 内路径分隔符。
    $zipStream = [System.IO.File]::Open($out, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
        try {
            Add-ZipFileEntry -Archive $archive -DiskPath (Join-Path $temp "scf_bootstrap") -EntryName "scf_bootstrap"
            Add-ZipDirectoryTree -Archive $archive -FolderPath (Join-Path $temp "scf_site_packages") -EntryPrefix "scf_site_packages"
            Add-ZipDirectoryTree -Archive $archive -FolderPath (Join-Path $temp "backend") -EntryPrefix "backend"
            Add-ZipDirectoryTree -Archive $archive -FolderPath (Join-Path $temp "magrun") -EntryPrefix "magrun"
            Add-ZipDirectoryTree -Archive $archive -FolderPath (Join-Path $temp $(Join-Path "frontend" "dist")) -EntryPrefix "frontend/dist"
            Add-ZipFileEntry -Archive $archive -DiskPath (Join-Path $temp "requirements.txt") -EntryName "requirements.txt"
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $zipStream.Dispose()
    }
    Write-Host "OK: $out"
    Write-Host "Zip root should include: scf_bootstrap, scf_site_packages, backend, magrun, frontend/dist, requirements.txt"
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
