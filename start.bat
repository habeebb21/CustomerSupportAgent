@echo off
echo Starting n8n with public URL...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
pause
