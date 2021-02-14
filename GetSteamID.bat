@echo off
setlocal ENABLEDELAYEDEXPANSION
title Get SteamInfo - Boo@LinkNeverDie.Com
call :intro


:: ============
:: MENU DRIVEN
:: ============

echo Hi %username%,
echo.
echo Please choose a way to extract your SteamID:
echo.
echo 1. Offline
echo 2. Online
echo.
set /p userchoice=Your choice is 

:: Pre-set variable
set suname=n/a
set suid=n/a
set sid=n/a
set sid32=n/a
set sid64=n/a

:: Goto chosen option
if %userchoice%==1 goto off_m
if %userchoice%==2 goto onl_m
exit


:: ========================================================================
:: Offline mode - You need to have Steam application installed and logined
:: ========================================================================

:off_m
reg query "HKCU\SOFTWARE\Valve\Steam" /v "AutoLoginUser">nul 2>&1
if %errorlevel% neq 0 goto fail
for /F "tokens=2*" %%A in ('reg query "HKCU\SOFTWARE\Valve\Steam" /v "SteamPath"') DO set SteamPath=%%B\config

cd /d "%SteamPath%"
set skip_time=-1
set skip_line=-1
set found=0
:loopF
set /a "skip_time+=1"
set /a "skip_line+=8"
for /f "skip=%skip_line% tokens=2*" %%A in (loginusers.vdf) do (
	echo %%A | find "1" >nul
	if !errorlevel! neq 0 goto loopF
	set found=1
	goto loopF_done
	)
:loopF_done
if not %found%==1 goto fail

:: set sid64
set /a "skip_line=%skip_time%*8+2"
for /f "skip=%skip_line% tokens=1" %%A in (loginusers.vdf) do (
	set sid64=%%A
	goto sid64_done
	)
:sid64_done
set sid64=%sid64:"=%

:: set suid
set /a "skip_line+=2"
for /f "skip=%skip_line% tokens=2*" %%A in (loginusers.vdf) do (
	set suid=%%A
	goto suid_done
	)
:suid_done
set suid=%suid:"=%

:: set sname
set /a "skip_line+=1"
for /f "skip=%skip_line% tokens=1*" %%A in (loginusers.vdf) do (
	set sname=%%B
	goto sname_done
	)
:sname_done
set sname=%sname:"=%
goto convert64


:: ==========================================================
:: Online mode - You need to provide your Steam profile url
:: ==========================================================

:onl_m
:: Get steamid64 by url
echo.
set /p steamprofile=Enter your Steam profile url: 

echo %steamprofile% | findstr /r "^https://steamcommunity.com/id/[A-Za-z0-9]*/*" >nul
if %errorlevel% equ 0 goto goodurl
echo %steamprofile% | findstr /r "^https://steamcommunity.com/profiles/[0-9]*/*" >nul
if %errorlevel% neq 0 goto badurl

:goodurl
for /f "skip=1 tokens=3 delims=^<^>" %%a in ('curl -s "%steamprofile%?xml=1.xml"') DO (
	set sid64=%%a
	goto m2_sid64_done
	)
	
:m2_sid64_done
for /f "skip=2 tokens=5 delims=^<^>[]" %%a in ('curl -s "%steamprofile%?xml=1.xml"') DO (
	set sname=%%a
	goto convert64
	)
	
	
:: ===========================================
:: Convert SteamID64 to SteamID and SteamID32
:: ===========================================
:convert64
for /f %%A in ('powershell %sid64% -shr 56') do set X=%%A
for /f %%A in ('powershell %sid64% -shl 32 -shr 33') do set sid=%%A
for /f %%A in ('powershell %sid64% -shl 32 -shr 32') do set sid32=%%A
set /a "Y=%sid32%&1"


:: ===================
:: Display the result
:: ===================
cls
call :intro
echo.
echo 			==================================
echo 				STEAM ACCOUNT INFO
echo 			==================================
echo.
echo 			Profile name: %sname%
echo.
echo 			Account name: %suid%
echo.
echo 			SteamID     : STEAM_%X%:%Y%:%sid%
echo.
echo 			SteamID32   : [U:1:%sid32%]
echo.
echo 			SteamID64   : %sid64%
echo.
echo 			==================================
echo.
pause
exit


:: ========================
:: Some errors might occur
:: ========================

:badurl
echo.
echo Operation Failed!
echo Error: Steam profile url is invalid
echo.
pause
exit

:fail
echo.
echo Operation Failed!
echo Hint: You need to install Steam application and login your Steam account.
echo.
pause
exit


:: ========================================================================
::  Intro - I make this for Members@LinkNeverDie.Com
:: ========================================================================

:intro
echo 	 _    _      _   _  _                 ___  _       ___           
echo 	^| ^|  (_)_ _ ^| ^|_^| \^| ^|_____ _____ _ _^|   \(_)___  / __^|___ _ __  
echo 	^| ^|__^| ^| ' \^| / / .` / -_) V / -_) '_^| ^|) ^| / -_)^| (__/ _ \ '  \ 
echo 	^|____^|_^|_^|^|_^|_\_\_^|\_\___^|\_/\___^|_^| ^|___/^|_\___(_)___\___/_^|_^|_^|
echo.
echo 		--------------------Get-SteamID--------------------
echo.
exit /b
