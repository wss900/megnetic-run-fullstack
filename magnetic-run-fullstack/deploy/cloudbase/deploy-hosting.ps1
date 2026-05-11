# 构建并部署前端到云开发「静态网站托管」子目录 magnetic-run/（与现有 CORS、访问习惯一致）。
# 用法: cd deploy/cloudbase; .\deploy-hosting.ps1
# 依赖: Node.js、npm；需已登录 CloudBase CLI（npx 会拉取 @cloudbase/cli）。
#
# 若改为根路径部署: 将 $CloudPath 改为 "" 或 "/"，构建时设 $ViteBase = "/"

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
$frontend = Join-Path $repoRoot "frontend"
$envId = "wss-magnetic-run-d2exalr53438f7f"
$CloudPath = "magnetic-run"
$ViteBase = "/magnetic-run/"
$ViteApi = "https://wss-magnetic-run-d2exalr53438f7f.service.tcloudbase.com/my-api"

$env:VITE_BASE_PATH = $ViteBase
$env:VITE_API_BASE = $ViteApi

Push-Location $frontend
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build failed: $LASTEXITCODE" }
}
finally {
    Pop-Location
}

Write-Host "Uploading to static hosting: cloudPath=$CloudPath ..."
Push-Location $frontend
try {
    # 用 cmd 管道喂换行，避免 npx 卡在交互；避免 PowerShell 把 CLI 的 stderr 当终止错误
    cmd /c "echo.| npx --yes --package=@cloudbase/cli tcb hosting deploy ./dist $CloudPath -e $envId --yes --json"
    if ($LASTEXITCODE -ne 0) { throw "tcb hosting deploy failed: $LASTEXITCODE" }
}
finally {
    Pop-Location
}

$domain = "https://wss-magnetic-run-d2exalr53438f7f-1430921364.tcloudbaseapp.com"
Write-Host "Done. Open: ${domain}/${CloudPath}/"
