@echo off

REM Check for administrator rights
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    REM Administrator rights detected
) ELSE (
    echo No administrator rights recognized.
    echo PROCESS IS STOPPED!
    exit
)

REM Create log directory on Desktop
set "logDir=%USERPROFILE%\Desktop\WinRep_Logs"
if not exist "%logDir%" mkdir "%logDir%"

REM Ensure master log file is initialized
set "masterLog=%logDir%\MasterLog.log"
echo Log created on %date% at %time% > "%masterLog%"

REM Check if PowerShell has already been added to PATH
set "powershellPath=C:\Windows\System32\WindowsPowerShell\v1.0"
if exist "%TEMP%\WinRep_PowerShellAdded.flag" (
    echo PowerShell is already in the PATH. Skipping addition. >> "%masterLog%"
) else (
    REM Add PowerShell to PATH if not already present
    echo Adding PowerShell to PATH...
    setx PATH "%PATH%;%powershellPath%"
    echo PowerShell has been added to the PATH. Restarting script... >> "%masterLog%"
    echo. > "%TEMP%\WinRep_PowerShellAdded.flag"
    start "" "%~f0"
    exit
    )
)
REM Ask user for run type
echo Please select the type of run:
echo 1. Standard (Update drivers, Repair Windows image, Verify and repair system files, Perform Windows Update)
echo 2. Full (Includes all steps)
echo 3. Exit
set /p runType="Enter your choice (1, 2, or 3): "
if "%runType%"=="1" (
    REM Standard run selected
    call :StandardRun
    goto :eof
) else if "%runType%"=="2" (
    REM Full run selected
    call :FullRun
    goto :eof
) else if "%runType%"=="3" (
    echo Exiting...
    exit
) else (
    echo Invalid input. Please enter 1, 2, or 3.
    goto :eof
)

:StandardRun
REM Standard run logic
echo Starting Standard Run...
call :UpdateDrivers
echo Completed Update Drivers.
call :RepairWindowsImage
echo Completed Repair Windows Image.
call :VerifyAndRepairSystemFiles
echo Completed Verify and Repair System Files.
call :PerformWindowsUpdate
echo Completed Perform Windows Update.
echo Standard run completed.
goto :eof

:FullRun
REM Full run logic
echo Starting Full Run...
call :UpdateDrivers
echo Completed Update Drivers.
call :CheckAndRepairDisk
echo Completed Check and Repair Disk.
call :RepairWindowsImage
echo Completed Repair Windows Image.
call :VerifyAndRepairSystemFiles
echo Completed Verify and Repair System Files.
call :PerformWindowsUpdate
echo Completed Perform Windows Update.
call :RepairBootConfigData
echo Completed Repair Boot Configuration Data.
echo Full run completed.
goto :eof

REM Define functions for each command section
:UpdateDrivers
echo Updating Drivers...
pnputil /scan-devices >> "%masterLog%" 2>&1
if %errorlevel% equ 0 (
    echo Drivers were successfully updated. >> "%masterLog%"
) else (
    echo Driver update failed. >> "%masterLog%"
)
goto :eof

:CheckAndRepairDisk
echo Checking and Repairing Disk...
chkdsk /f /r C: >> "%logDir%\DiskCheck.log" 2>&1
if %errorlevel% equ 0 (
    echo Disk check completed successfully. >> "%masterLog%"
) else (
    echo CHKDSK could not fix all errors or failed. See DiskCheck.log for details. >> "%masterLog%"
)
goto :eof

:RepairWindowsImage
echo Repairing Windows Image...
DISM /Online /Cleanup-Image /RestoreHealth /LogPath:"%logDir%\DISM.log" >> "%masterLog%" 2>&1
if %errorlevel% equ 0 (
    echo Windows image was successfully repaired. >> "%masterLog%"
) else (
    echo DISM repair failed. See DISM.log for details. >> "%masterLog%"
)
goto :eof

:VerifyAndRepairSystemFiles
echo Verifying and Repairing System Files...
sfc /scannow > "%logDir%\SFC.log" 2>&1
if %errorlevel% equ 0 (
    echo System files were successfully verified and repaired. >> "%masterLog%"
) else (
    echo SFC could not fix some errors or the scan failed. See SFC.log for details. >> "%masterLog%"
)
goto :eof

:PerformWindowsUpdate
echo Performing Windows Update...
powershell -command "try { Install-Module PSWindowsUpdate -Force -SkipPublisherCheck; Import-Module PSWindowsUpdate; Get-WindowsUpdate -Install -AcceptAll -AutoReboot } catch { Write-Output 'Error: Unable to install or import PSWindowsUpdate module.'; exit 1 }" >> "%logDir%\WindowsUpdate.log" 2>&1
if %errorlevel% equ 0 (
    echo Windows Update completed. >> "%masterLog%"
) else (
    echo Windows Update failed. See WindowsUpdate.log for details. >> "%masterLog%"
)
goto :eof

:RepairBootConfigData
echo Repairing Boot Configuration Data...
bcdedit /export C:\BCD_Backup >> "%logDir%\BootRepair.log" 2>&1
bootrec /fixmbr >> "%logDir%\BootRepair.log" 2>&1
bootrec /fixboot >> "%logDir%\BootRepair.log" 2>&1
bootrec /scanos >> "%logDir%\BootRepair.log" 2>&1
bootrec /rebuildbcd >> "%logDir%\BootRepair.log" 2>&1
if %errorlevel% equ 0 (
    echo Boot configuration data repaired successfully. >> "%masterLog%"
) else (
    echo Boot repair failed. See BootRepair.log for details. >> "%masterLog%"
)
goto :eof

echo Script execution completed.
goto :eof