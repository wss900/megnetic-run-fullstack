@echo off
title Magnetic Run — Frontend
cd /d "%~dp0frontend"
if errorlevel 1 (
  echo Failed to open frontend folder.
  pause
  exit /b 1
)

where npm >nul 2>nul
if errorlevel 1 (
  echo.
  echo [错误] 找不到 npm。请先安装 Node.js，并勾选 “Add to PATH”，然后重新打开终端再试。
  echo 下载: https://nodejs.org/
  echo.
  pause
  exit /b 1
)

echo.
echo [前端] 目录: %cd%
echo.

if not exist node_modules (
  echo [前端] 首次运行，正在 npm install ...
  call npm install
  if errorlevel 1 (
    echo.
    echo [错误] npm install 失败，见上方报错。
    pause
    exit /b 1
  )
)

echo [前端] 启动开发服务器 (Vite)。按 Ctrl+C 可停止。
echo [前端] 浏览器打开: http://localhost:5173/
echo.
call npm run dev
if errorlevel 1 (
  echo.
  echo [错误] 启动失败，见上方报错。
  pause
)
