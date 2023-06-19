@echo off
::Paste the server key from https://platform.plutonium.pw/serverkeys here
set key=
::RemoteCONtrol password, needed for most management tools like IW4MADMIN and B3. Do not skip if you installing IW4MADMIN.
set rcon_password=
::Name of the config file the server should use.
set cfg=dedicated.cfg
::Name of the server shown in the title of the cmd window. This will NOT bet shown ingame.
set name=PlutoniumT6MP Bot Warfare
::Port used by the server (default: 4976)
set port=4980
::What ip to bind too
set ip=0.0.0.0
:: current dir of this .bat file
SET mypath=%~dp0
SET mypath=%mypath:~0,-1%
::Only change this when you don't want to keep the bat files in the game folder. MOST WON'T NEED TO EDIT THIS!  %cd%
set gamepath=%mypath%
::Your plutonium install path (leave default!)
set pluto_path=%localappdata%\Plutonium
:: Gamemode; oneof t4sp, t4mp, t5sp, t5mp, iw5mp, t6mp, t6zm
set pluto_game_mode=t6mp
:: Other things to send to cmd
set cmd_extras=
:: Exe dedi path (leave default!)
set exe_path=bin\plutonium-bootstrapper-win32.exe


title PlutoniumT6MP - %name% - Server restarter
echo Visit plutonium.pw / Join the Discord (a6JM2Tv) for NEWS and Updates!
echo Server "%name%" will load "%cfg%" and listen on port "%port%" UDP with IP "%ip%"!
echo To shut down the server close this window first!
echo (%date%)  -  (%time%) %name% server start.

cd /D %pluto_path%
:server
start /wait /abovenormal "%name%" "%exe_path%" %pluto_game_mode% "%gamepath%" -dedicated -sv_config "%cfg%" -key "%key%" -net_ip "%ip%" -net_port "%port%" -rcon_password "%rcon_password%" %cmd_extras%
echo (%date%)  -  (%time%) WARNING: %name% server closed or dropped... server restarts.
goto server
