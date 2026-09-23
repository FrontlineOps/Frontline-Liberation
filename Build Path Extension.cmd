@echo off
title Frontline Liberation - Build Path Extension
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Build-PathExtension.ps1"
if errorlevel 1 (
    echo.
    echo The path extension build failed. See the message above.
    pause
    exit /b 1
)
echo.
echo Built: %~dp0.build\path-extension\@FrontlinePath
pause
exit /b 0
