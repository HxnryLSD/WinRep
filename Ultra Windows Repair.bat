@echo off

timeout 2 > nul

NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (

echo. 
echo Administrator rights Detected!
echo. 

) ELSE (

echo. 
echo No Administrator rights recognized.
echo PROCESS IS STOPPED!
echo. 

timeout 6 > nul
exit

)


timeout 2 > nul

echo Starting Repair ...

pnputil /scan-devices
if %errorlevel% equ 0 (
    echo Treiber wurden erfolgreich aktualisiert.
) else (
    echo Treiberaktualisierung schlug fehl.
)

chkdsk /f C:
if %errorlevel% equ 0 (
    echo Festplattenüberprüfung erfolgreich abgeschlossen.
) else (
    echo CHKDSK konnte nicht alle Fehler beheben oder schlug fehl.
)

DISM /Online /Cleanup-Image /RestoreHealth
if %errorlevel% equ 0 (
    echo Windows-Abbild wurde erfolgreich repariert.
) else (
    echo DISM-Reparatur schlug fehl.
)

sfc /scannow
if %errorlevel% equ 0 (
    echo Systemdateien wurden erfolgreich überprüft und repariert.
) else (
    echo SFC konnte einige Fehler nicht beheben oder der Scan schlug fehl.
)

powershell -command "Install-Module PSWindowsUpdate -Force -SkipPublisherCheck; Import-Module PSWindowsUpdate; Get-WindowsUpdate -Install -AcceptAll -AutoReboot"
if %errorlevel% equ 0 (
    echo Windows Update abgeschlossen.
) else (
    echo Windows Update schlug fehl.
)


echo. 
echo Finished
echo. 

pause