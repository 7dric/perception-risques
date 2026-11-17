@echo off
rem Runs a command on Windows from the repository root, with Node.js on the PATH.
rem Useful from WSL, whose network is unreliable for npm:  cmd.exe /c tools\winrun.cmd npm test
set "PATH=C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"
cd /d "%~dp0.."
%*
