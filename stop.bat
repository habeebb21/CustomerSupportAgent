@echo off
echo Stopping n8n and ngrok...
cd /d "%~dp0"
docker compose down
echo Done. All containers stopped.
pause
