@echo off

echo Adding Printers Please Wait

REM Remove printers
rundll32 printui.dll,PrintUIEntry /dl /n "Office" /q
rundll32 printui.dll,PrintUIEntry /dl /n "Workroom" /q

REM Add ports
Cscript %windir%/System32/Printing_Admin_Scripts/en-US/Prnport.vbs -a -r 10.50.1.20 -h 10.50.1.20 -o raw
Cscript %windir%/System32/Printing_Admin_Scripts/en-US/Prnport.vbs -a -r 10.50.1.24 -h 10.50.1.24 -o raw

cls

echo  *******************************      *******************************
echo *                               *    *                               *
echo * Adding Printers Do Not Close! *    * Adding Printers Do Not Close! *
echo *                               *    *                               *
echo  *******************************      *******************************

echo  *******************************      *******************************
echo *                               *    *                               *
echo * Adding Printers Do Not Close! *    * Adding Printers Do Not Close! *
echo *                               *    *                               *
echo  *******************************      *******************************

echo  *******************************      *******************************
echo *                               *    *                               *
echo * Adding Printers Do Not Close! *    * Adding Printers Do Not Close! *
echo *                               *    *                               *
echo  *******************************      *******************************

echo  *******************************      *******************************
echo *                               *    *                               *
echo * Adding Printers Do Not Close! *    * Adding Printers Do Not Close! *
echo *                               *    *                               *
echo  *******************************      *******************************

REM check if 64 bit
IF EXIST "C:\Program Files (x86)" (
	goto 64bit
) ELSE (
	goto 32bit
)


REM Add 64 bit printers
:64bit
rundll32 printui.dll,PrintUIEntry /if /b "Office" /f "\\10.4.1.10\Printer Drivers\Konica Drivers\950_64 bit pcl\950_pcl6_win7_764_v2000_efigs_ja_sc_tc_ko_inst\Drivers\PCL\EN\Win_x64\KOBZDJ__.inf" /r "10.50.1.24" /m "KONICA MINOLTA 950 PCL"
rundll32 printui.dll,PrintUIEntry /if /b "Workroom" /f "\\10.4.1.10\Printer Drivers\Konica Drivers\950_64 bit pcl\950_pcl6_win7_764_v2000_efigs_ja_sc_tc_ko_inst\Drivers\PCL\EN\Win_x64\KOBZDJ__.inf" /r "10.50.1.26" /m "KONICA MINOLTA 950 PCL"
goto end

REM Add 32 bit printers
:32bit
rundll32 printui.dll,PrintUIEntry /if /b "Office" /f "\\dc01\Printer Drivers\Konica Drivers\950_pcl6_32\Drivers\PCL\EN\Win_x86\KOBZDJ__.inf" /r "10.50.1.24" /m "KONICA MINOLTA 950 PCL"
rundll32 printui.dll,PrintUIEntry /if /b "Workroom" /f "\\dc01\Printer Drivers\Konica Drivers\950_pcl6_32\Drivers\PCL\EN\Win_x86\KOBZDJ__.inf" /r "10.50.1.26" /m "KONICA MINOLTA 950 PCL"

:end
