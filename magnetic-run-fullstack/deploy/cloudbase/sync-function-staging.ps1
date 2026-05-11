# 同步 backend + magrun 到 CloudBase MCP / 控制台上传用的 cloudfunctions/apihd 目录。
# 用法: cd deploy/cloudbase; .\sync-function-staging.ps1
# 然后用 MCP manageFunctions updateFunctionCode，functionRootPath 指向本目录下的 cloudfunctions 绝对路径。

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
$fnDir = Join-Path $here "cloudfunctions\apihd"

New-Item -ItemType Directory -Path $fnDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $here "scf_bootstrap") -Destination (Join-Path $fnDir "scf_bootstrap") -Force
$bootDst = Join-Path $fnDir "scf_bootstrap"
$boot = [System.IO.File]::ReadAllText($bootDst)
$boot = $boot -replace "`r`n", "`n" -replace "`r", "`n"
$utf8nobom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($bootDst, $boot.TrimEnd() + "`n", $utf8nobom)
Copy-Item -LiteralPath (Join-Path $repoRoot "backend\requirements.txt") -Destination (Join-Path $fnDir "requirements.txt") -Force

$beSrc = Join-Path $repoRoot "backend"
$beDst = Join-Path $fnDir "backend"
$mgSrc = Join-Path $repoRoot "magrun"
$mgDst = Join-Path $fnDir "magrun"

New-Item -ItemType Directory -Path $beDst -Force | Out-Null
New-Item -ItemType Directory -Path $mgDst -Force | Out-Null
robocopy $beSrc $beDst /MIR /XD .venv __pycache__ .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -gt 7) { throw "robocopy backend failed: $LASTEXITCODE" }
robocopy $mgSrc $mgDst /MIR /XD __pycache__ .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -gt 7) { throw "robocopy magrun failed: $LASTEXITCODE" }

$cfRoot = Join-Path $here "cloudfunctions"
Write-Host "OK. functionRootPath for MCP:"
Write-Host (Resolve-Path $cfRoot).Path
