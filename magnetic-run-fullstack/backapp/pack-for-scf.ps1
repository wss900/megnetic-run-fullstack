# 在「资源管理器」里右键 powershell 运行，或: cd backapp; .\pack-for-scf.ps1
# 生成 scf-deploy.zip：解压后第一层必须是 scf_bootstrap、backend、magrun（不能多一层 backapp 文件夹）
$here = $PSScriptRoot
$out = Join-Path (Split-Path $here -Parent) "scf-deploy.zip"
if (Test-Path $out) { Remove-Item $out -Force }
$items = @(
    (Join-Path $here "scf_bootstrap"),
    (Join-Path $here "backend"),
    (Join-Path $here "magrun"),
    (Join-Path $here "requirements.txt")
)
foreach ($p in $items) {
    if (-not (Test-Path $p)) { throw "缺少: $p" }
}
Compress-Archive -LiteralPath $items -DestinationPath $out -Force
Write-Host "已生成: $out"
Write-Host "上传前请用压缩软件打开 zip，确认根目录直接看到 scf_bootstrap（没有 backapp 这一层）。"
