@echo off
setlocal EnableDelayedExpansion
title SSH Infrastructure Connect
color 0A

REM ===== Auto-create servers.txt if missing =====
if not exist servers.txt (
    echo servers.txt not found. Creating default file...
    (
    echo root@127.0.0.1:22,Localhost Example
    ) > servers.txt
    echo Default servers.txt created!
    pause
)

:MENU
cls
echo ==================================
echo         SSH SERVER MENU
echo ==================================
echo.

set count=0

REM ===== Read servers.txt dynamically =====
for /f "usebackq tokens=1,2 delims=," %%A in ("servers.txt") do (
    if /i not "%%A"=="exampleuser@ipadress:port" (
        set /a count+=1
        set "entry!count!=%%A"
        set "name!count!=%%B"
        echo [!count!] %%B - %%A
    )
)

REM ===== No valid servers found =====
if %count%==0 (
    echo No servers found in your list.
    echo.
    echo [A] Add a new server
    echo [Q] Quit
    echo.
    set /p choice=Select: 
    if /I "!choice!"=="Q" exit
    if /I "!choice!"=="A" goto ADDSERVER
    goto MENU
)

echo.
echo [A] Add a new server
echo [D] Delete a server
echo [Q] Quit
echo.

set /p choice=Select (Number, A, D, or Q): 

if /I "%choice%"=="Q" exit
if /I "%choice%"=="A" goto ADDSERVER
if /I "%choice%"=="D" goto DELETESERVER
if "%choice%"=="" goto MENU

REM ===== Numeric Validation =====
set "var="&for /f "delims=0123456789" %%i in ("%choice%") do set var=%%i
if defined var goto INVALID
if %choice% GTR %count% goto INVALID
if %choice% LSS 1 goto INVALID

set index=%choice%
goto CONNECT

:DELETESERVER
cls
echo ===============================
echo       DELETE A SERVER
echo ===============================
echo.

for /L %%i in (1,1,%count%) do (
    echo [%%i] !name%%i! ^(!entry%%i!^)
)

echo.
set /p delchoice=Enter the number to delete (or M for menu): 
if /I "%delchoice%"=="M" goto MENU

if "%delchoice%"=="" goto DELETESERVER
set "var="&for /f "delims=0123456789" %%i in ("%delchoice%") do set var=%%i
if defined var goto DELETESERVER
if %delchoice% GTR %count% goto DELETESERVER
if %delchoice% LSS 1 goto DELETESERVER

set target=!entry%delchoice%!
set targetName=!name%delchoice%!

echo.
echo WARNING: Are you sure you want to delete "%targetName%"? (Y/N)
set /p confirm=
if /I not "%confirm%"=="Y" goto MENU

type nul > servers.txt.tmp
for /f "usebackq tokens=1,2 delims=," %%A in ("servers.txt") do (
    if /i not "%%A"=="%target%" (
        echo %%A,%%B>>servers.txt.tmp
    )
)
move /y servers.txt.tmp servers.txt >nul
echo.
echo Server "%targetName%" removed.
timeout /t 2 >nul
goto MENU

:CONNECT
set "server=!entry%index%!"

REM ===== Parse user, ip, and port (%%U=user, %%V=ip, %%W=port) =====
for /f "tokens=1,2,3 delims=@:" %%U in ("!server!") do (
    set "ssh_user=%%U"
    set "ssh_ip=%%V"
    set "ssh_port=%%W"
)

REM Fallback if port is missing
if "!ssh_port!"=="" set "ssh_port=22"

cls
echo ==================================
echo       ESTABLISHING CONNECTION
echo ==================================
echo User: !ssh_user!
echo Host: !ssh_ip!
echo Port: !ssh_port!
echo Name: !name%index%!
echo ==================================
echo.

ssh -p !ssh_port! !ssh_user!@!ssh_ip!

echo.
echo Connection closed.
pause
goto MENU

:ADDSERVER
cls
echo ===============================
echo         ADD NEW SERVER
echo ===============================
echo.
echo Format: user@ip:port (e.g. root@192.168.1.1:22)
set /p newserver=Enter server: 
set /p newname=Enter server name: 

echo !newserver! | findstr /r ".*@.*:.*" >nul
if errorlevel 1 (
    echo Invalid format. Use user@ip:port
    timeout /t 3 >nul
    goto ADDSERVER
)

echo !newserver!,!newname!>>servers.txt
echo Server added!
timeout /t 1 >nul
goto MENU

:INVALID
echo Invalid choice.
timeout /t 2 >nul
goto MENU