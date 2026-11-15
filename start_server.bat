@echo off
title Escape the Digital Room - server
cd /d "%~dp0"
set EDR_OPEN=1
python server.py %*
echo.
echo The server has stopped. Press any key to close this window.
pause >nul
