@echo off
echo Backing up n8n workflows to H: drive...
for /f "tokens=2 delims==." %%a in ("wmic os get localdatetime /value") do set dt=%%a
set stamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%
if not exist "%~dp0backups" mkdir "%~dp0backups"
docker run --rm -v n8n_data:/data -v "%~dp0backups:/backup" alpine tar czf "/backup/n8n_backup_%stamp%.tar.gz" -C /data .
if %errorlevel%==0 (
 echo Backup saved to: %~dp0backups
) else (
 echo FAILED - is Docker running and n8n_data volume present?
)
pause
