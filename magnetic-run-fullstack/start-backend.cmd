@echo off
title Magnetic Run — Backend API
cd /d "%~dp0backend"
if errorlevel 1 (
  echo Failed to open backend folder.
  pause
  exit /b 1
)

where python >nul 2>nul
if errorlevel 1 (
  echo.
  echo [错误] 找不到 python。请安装 Python 3 并勾选 “Add to PATH”，然后重试。
  echo.
  pause
  exit /b 1
)

if not exist .venv\Scripts\python.exe (
  echo [后端] 创建虚拟环境并安装依赖...
  python -m venv .venv
  call .venv\Scripts\pip install -r requirements.txt
  if errorlevel 1 (
    echo.
    echo [错误] pip install 失败，见上方报错。
    pause
    exit /b 1
  )
)

echo.
echo [后端] 目录: %cd%
echo [后端] 启动 API: http://127.0.0.1:8000  文档: http://127.0.0.1:8000/docs
echo [后端] 请保持本窗口运行；前端 Vite 会把 /api 代理到这里。
echo.
call .venv\Scripts\uvicorn.exe main:app --reload --host 127.0.0.1 --port 8000
if errorlevel 1 (
  echo.
  echo [错误] uvicorn 退出异常。若提示端口占用，请关闭占用 8000 的程序后重试。
  pause
)
