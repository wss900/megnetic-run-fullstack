@echo off
title Magnetic Run - Production
cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
  where py >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] python not found. Install Python 3 and add to PATH.
    pause
    exit /b 1
  )
  py -3 "%~dp0start_prod.py"
) else (
  python "%~dp0start_prod.py"
)
if errorlevel 1 pause
