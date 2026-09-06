@echo off
title Frontline Liberation - Build Missions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Build-Missions.ps1" -OpenOutput
if errorlevel 1 (
    echo.
    echo The mission build failed. See the message above.
    pause
    exit /b 1
)
exit /b 0
