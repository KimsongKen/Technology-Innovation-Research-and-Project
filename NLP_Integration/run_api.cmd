@echo off
REM Runs run_api.ps1 without changing your global ExecutionPolicy (Bypass applies only to this PowerShell child process).
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_api.ps1" %*
