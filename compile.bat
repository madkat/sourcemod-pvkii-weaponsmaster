@echo off

setlocal
set curr=%CD%

cd ../sourcemod-compiler
set compdir=%CD%
cd %curr%
"%compdir%/spcomp.exe" WeaponsMaster.sp -oWeaponsMaster.smx

cd %curr%
endlocal
