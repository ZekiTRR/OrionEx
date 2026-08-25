@echo off
setlocal enabledelayedexpansion

if "%~1"=="/change_mac" goto :change_mac_only_auto
if "%~1"=="/restore_mac" goto :restore_mac_auto
if "%~1"=="/clean_roblox" goto :clean_roblox_auto

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "%* ", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
)
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )

:main_menu
cls
echo 1. roblox script
echo 2. show current mac address
echo 3. change mac address only
echo 4. restore default mac address
echo 5. exit
set /p menu_choice="Select an option: "

if "%menu_choice%"=="1" goto :roblox_script
if "%menu_choice%"=="2" goto :show_mac
if "%menu_choice%"=="3" goto :change_mac_only
if "%menu_choice%"=="4" goto :restore_mac
if "%menu_choice%"=="5" exit
goto :main_menu

:show_mac
cls
echo current MAC Addresses by Device:
echo.
getmac /v /fo list | findstr /R /C:"Connection Name" /C:"Physical Address"
echo.
pause
goto :main_menu

:change_mac_only
call :spoof_logic
pause
goto :main_menu

:restore_mac
echo restoring hardware MAC address...
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /v "NetworkAddress" ^| findstr "HKEY_LOCAL_MACHINE"') do (
    reg delete "%%i" /v "NetworkAddress" /f >nul 2>&1
)
powershell -Command "$a = Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1; if ($a) { Disable-NetAdapter -Name $a.Name -Confirm:$false; Enable-NetAdapter -Name $a.Name -Confirm:$false }"
timeout /t 8 >nul
echo checking connection stability...
:restore_ping_check
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (timeout /t 2 /nobreak >nul & goto :restore_ping_check)
echo connection stable
echo restore complete.
pause
goto :main_menu

:roblox_script
echo starting
taskkill /f /im RobloxPlayerBeta.exe >nul 2>&1
echo deleted - RobloxPlayerBeta.exe Process
taskkill /f /im RobloxStudioBeta.exe >nul 2>&1
echo deleted - RobloxStudioBeta.exe Process
taskkill /f /im RobloxPlayerLauncher.exe >nul 2>&1
echo deleted - RobloxPlayerLauncher.exe Process

set "ps_file=%TEMP%\rbx_cleaner.ps1"
del "%ps_file%" >nul 2>&1

>>"%ps_file%" echo $ErrorActionPreference = 'SilentlyContinue'
>>"%ps_file%" echo function LogKey($p^) { Write-Host ("deleted registry key - " + ($p -replace '^.*::', ''^)^) }
>>"%ps_file%" echo function LogVal($n, $p^) { Write-Host ("deleted registry value - $n from " + ($p -replace '^.*::', ''^)^) }
>>"%ps_file%" echo Write-Host "Cleaning Files ^& Folders..."
>>"%ps_file%" echo $users = Get-ChildItem -Path 'C:\Users' -Directory
>>"%ps_file%" echo $dirs = @('C:\ProgramData', 'C:\Program Files (x86)', 'C:\Program Files', 'C:\Windows\Prefetch', 'C:\v2\data\cache'^)
>>"%ps_file%" echo foreach ($u in $users^) { $dirs += "$($u.FullName)\AppData\Local"; $dirs += "$($u.FullName)\AppData\Roaming"; $dirs += "$($u.FullName)\Desktop"; $dirs += "$($u.FullName)\Downloads" }
>>"%ps_file%" echo foreach ($d in $dirs^) { if (Test-Path $d^) { Get-ChildItem -Path $d -Recurse -Filter '*roblox*' -ErrorAction SilentlyContinue ^| Where-Object { $_.FullName -notmatch '(?i)\\Desktop^|\\zen^|\\Mozilla\\Firefox^|\\Google\\Chrome' } ^| Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} ^| ForEach-Object { $t=$_.FullName; if (Test-Path -LiteralPath $t^) { if (Test-Path -LiteralPath $t -PathType Container^) { Get-ChildItem -Path $t -Recurse -ErrorAction SilentlyContinue ^| Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} ^| ForEach-Object { Write-Host ("deleted file/folder - " + $_.FullName^) } }; Write-Host ("deleted file/folder - " + $t^); Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue } } } }
>>"%ps_file%" echo Write-Host "Cleaning Registry Keys..."
>>"%ps_file%" echo $regPaths = @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\ProtocolExecute', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\ProtocolExecute', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RADAR\HeapLeakDetection\DiagnosedApplications', 'Registry::HKEY_CLASSES_ROOT'^)
>>"%ps_file%" echo $userHives = Get-ChildItem -Path 'Registry::HKEY_USERS' ^| Where-Object { $_.PSChildName -match 'S-1-5-21' -and $_.PSChildName -notmatch '_Classes' }
>>"%ps_file%" echo foreach ($h in $userHives^) {
>>"%ps_file%" echo    $regPaths += "$($h.PSPath)\Software"
>>"%ps_file%" echo    $regPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\Uninstall"
>>"%ps_file%" echo    $regPaths += "$($h.PSPath)\Software\Microsoft\Internet Explorer\ProtocolExecute"
>>"%ps_file%" echo    $regPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\NonPackaged"
>>"%ps_file%" echo }
>>"%ps_file%" echo foreach ($r in $regPaths^) { if (Test-Path $r^) { Get-ChildItem -Path $r -ErrorAction SilentlyContinue ^| Where-Object { $_.PSChildName -match '(?i)roblox' } ^| ForEach-Object { $t=$_.PSPath; Get-ChildItem -Path $t -Recurse -ErrorAction SilentlyContinue ^| Sort-Object -Property @{Expression={$_.PSPath.Length}; Descending=$true} ^| ForEach-Object { LogKey $_.PSPath }; LogKey $t; Remove-Item -Path $t -Recurse -Force -ErrorAction SilentlyContinue } } }
>>"%ps_file%" echo foreach ($h in $userHives^) { $rbxCorp = "$($h.PSPath)\Software\ROBLOX Corporation"; if (Test-Path $rbxCorp^) { Get-ChildItem -Path $rbxCorp -Recurse -ErrorAction SilentlyContinue ^| Sort-Object -Property @{Expression={$_.PSPath.Length}; Descending=$true} ^| ForEach-Object { LogKey $_.PSPath }; LogKey $rbxCorp; Remove-Item -Path $rbxCorp -Recurse -Force -ErrorAction SilentlyContinue } }
>>"%ps_file%" echo foreach ($h in $userHives^) { $compatStore = "$($h.PSPath)\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"; if (Test-Path $compatStore^) { Get-ItemProperty -Path $compatStore -ErrorAction SilentlyContinue ^| Get-Member -MemberType NoteProperty ^| Where-Object { $_.Name -match '(?i)roblox' } ^| ForEach-Object { Write-Host ("deleted registry value - " + $_.Name + " from " + ($compatStore -replace '^.*::', ''^)^); Remove-ItemProperty -Path $compatStore -Name $_.Name -Force -ErrorAction SilentlyContinue } } }
>>"%ps_file%" echo Write-Host "Cleaning Registry Values ^& Strings..."
>>"%ps_file%" echo $valPaths = @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\RegisteredApplications', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\RegisteredApplications', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\ARP'^)
>>"%ps_file%" echo foreach ($h in $userHives^) {
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\RegisteredApplications"
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts"
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched"
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView"
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\Run"
>>"%ps_file%" echo    $valPaths += "$($h.PSPath)\Software\Microsoft\Windows\CurrentVersion\RunNotification"
>>"%ps_file%" echo }
>>"%ps_file%" echo foreach ($v in $valPaths^) { if (Test-Path $v^) { $props = Get-ItemProperty -Path $v -ErrorAction SilentlyContinue; if ($props^) { $props.PSObject.Properties ^| Where-Object { $_.Name -match '(?i)roblox' -or ([string]$_.Value -match '(?i)roblox'^) } ^| ForEach-Object { if ($_.Name -notmatch 'PSPath^|PSParentPath^|PSChildName^|PSDrive^|PSProvider'^) { LogVal $_.Name $v; Remove-ItemProperty -Path $v -Name $_.Name -Force -ErrorAction SilentlyContinue } } } } }
>>"%ps_file%" echo Write-Host "Cleaning BagMRU Binary Cache..."
>>"%ps_file%" echo foreach ($h in $userHives^) {
>>"%ps_file%" echo    $bagPath = "$($h.PSPath)\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
>>"%ps_file%" echo    if (Test-Path $bagPath^) { Get-ChildItem -Path $bagPath -Recurse -ErrorAction SilentlyContinue ^| ForEach-Object { $key = $_.PSPath; Get-ItemProperty -Path $key -ErrorAction SilentlyContinue ^| Get-Member -MemberType NoteProperty ^| ForEach-Object { $val = Get-ItemPropertyValue -Path $key -Name $_.Name -ErrorAction SilentlyContinue; if ($val -is [byte[]]^) { $str = [System.Text.Encoding]::Unicode.GetString($val^) + [System.Text.Encoding]::ASCII.GetString($val^); if ($str -match '(?i)roblox'^) { Write-Host ("deleted binary data - " + $_.Name + " from " + ($key -replace '^.*::', ''^)^); Remove-ItemProperty -Path $key -Name $_.Name -Force -ErrorAction SilentlyContinue } } } } }
>>"%ps_file%" echo }

powershell -ExecutionPolicy Bypass -File "%ps_file%"
del "%ps_file%" >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" /v "AppCompatCache" /f >nul 2>&1
echo deleted - AppCompatCache System Memory
echo done
echo.

set /p spoof_prompt="change mac address? (y/n): "
if /i "%spoof_prompt%"=="y" (call :spoof_logic)

set /p choice="install roblox? (y/n): "
if /i "%choice%" NEQ "y" goto :main_menu

:install_loop
echo installing roblox...
set "temp_dir=%TEMP%\roblox"
if exist "%temp_dir%" rmdir /s /q "%temp_dir%"
mkdir "%temp_dir%"
curl -L -s -o "%temp_dir%\RobloxPlayerLauncher.exe" "https://www.roblox.com/download/client"
powershell -Command "Start-Process -FilePath '%temp_dir%\RobloxPlayerLauncher.exe' -ArgumentList '-silent' -WindowStyle Hidden" >nul 2>&1
set "timer=0"
:wait_install
timeout /t 2 /nobreak >nul
tasklist | find /i "RobloxPlayerLauncher.exe" >nul
if not errorlevel 1 goto wait_install

:folder_check
if exist "%LOCALAPPDATA%\Roblox" (
    goto install_success_label
)
set /a timer+=2
if !timer! LSS 30 (
    timeout /t 2 /nobreak >nul
    goto folder_check
)
echo installation failed.
set /p retry_choice="retry? y/n: "
if /i "!retry_choice!"=="y" goto install_loop
goto :main_menu

:install_success_label
echo suppressing auto-launch...
for /L %%i in (1,1,5) do (
    taskkill /f /im RobloxPlayerBeta.exe >nul 2>&1
    taskkill /f /im RobloxPlayerLauncher.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
)
rmdir /s /q "%temp_dir%" >nul 2>&1
echo deleted temp installer - %temp_dir%
echo roblox installed

set /p import_choice="import settings? (y/n): "
if /i "%import_choice%"=="y" (
    echo downloading settings...
    taskkill /f /im RobloxPlayerBeta.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
        del /f /q "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" >nul 2>&1
        echo deleted default auto-generated settings file.
    )
    curl -k -L -s -o "%TEMP%\GlobalBasicSettings_13.xml" "https://gist.githubusercontent.com/okdude42/3030c5f3581d8c57bb7b00d939487fd9/raw/e0a3b8c697a4b9e1e8b90f1d7e00aa549807bf37/GlobalBasicSettings_13.xml"
    if exist "%TEMP%\GlobalBasicSettings_13.xml" (
        for %%A in ("%TEMP%\GlobalBasicSettings_13.xml") do (
            if %%~zA gtr 0 (
                copy /y "%TEMP%\GlobalBasicSettings_13.xml" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" >nul
                echo settings imported successfully.
            ) else (
                echo failed: the downloaded settings file was empty.
            )
        )
    ) else (
        echo failed: could not download settings from the link.
    )
)
echo configuring shortcuts and cleaning studio...
taskkill /f /im RobloxStudioBeta.exe >nul 2>&1
if exist "%LOCALAPPDATA%\Roblox\Versions" (
    for /d %%d in ("%LOCALAPPDATA%\Roblox\Versions\*") do (
        if exist "%%d\RobloxStudioBeta.exe" rmdir /s /q "%%d" >nul 2>&1
    )
)
del /q "%USERPROFILE%\Desktop\Roblox Player.lnk" >nul 2>&1
del /q "%USERPROFILE%\Desktop\Roblox Studio.lnk" >nul 2>&1
del /q "%PUBLIC%\Desktop\Roblox Player.lnk" >nul 2>&1
del /q "%PUBLIC%\Desktop\Roblox Studio.lnk" >nul 2>&1

if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Roblox" mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Roblox"
for /d %%d in ("%LOCALAPPDATA%\Roblox\Versions\*") do (
    if exist "%%d\RobloxPlayerBeta.exe" set "launcher_path=%%d\RobloxPlayerBeta.exe"
)
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\Roblox\Roblox Player.lnk'); $sc.TargetPath = '%launcher_path%'; $sc.Save()"
echo.
echo press enter to close
pause >nul
exit

:spoof_logic
echo identifying active network adapter...
for /f "tokens=*" %%a in ('powershell -Command "(Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1).Name"') do set "adapter_name=%%a"
if "!adapter_name!"=="" (echo [!] No active physical adapter found. & exit /b)
for /f "tokens=3 delims=," %%a in ('getmac /v /fo csv ^| findstr /i "!adapter_name!"') do set "old_mac=%%~a"
set "hex=0123456789ABCDEF"
set "laa=26AE"
set /a "r1=!random! %% 4"
set "rand_mac=0!laa:~%r1%,1!"
for /L %%i in (1,1,10) do (
    set /a "idx=!random! %% 16"
    for %%j in (!idx!) do set "rand_mac=!rand_mac!!hex:~%%j,1!"
)
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "00*" /k ^| findstr "HKEY_LOCAL_MACHINE"') do (
    reg query "%%i" /v "DriverDesc" >nul 2>&1
    if !errorlevel! == 0 (reg add "%%i" /v "NetworkAddress" /t REG_SZ /d "!rand_mac!" /f >nul 2>&1)
)
echo restarting !adapter_name!...
powershell -Command "Disable-NetAdapter -Name '!adapter_name!' -Confirm:$false; Enable-NetAdapter -Name '!adapter_name!' -Confirm:$false"
timeout /t 8 >nul
for /f "tokens=3 delims=," %%a in ('getmac /v /fo csv ^| findstr /i "!adapter_name!"') do set "new_mac=%%~a"
if "!old_mac!"=="!new_mac!" (echo [!] MAC failed to change. & exit /b)
echo MAC changed to !new_mac!.
echo checking connection stability...
:ping_check
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (timeout /t 2 /nobreak >nul & goto :ping_check)
echo connection stable
exit /b

:change_mac_only_auto
set "adapter_name=%~2"
set "result_file=C:\Users\Public\zenith_result.txt"
if "!adapter_name!"=="" (
    for /f "tokens=*" %%a in ('powershell -Command "(Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1).InterfaceDescription"') do set "adapter_name=%%a"
)
if "!adapter_name!"=="" (
    echo FAIL> "!result_file!"
    exit
)
set "hex=0123456789ABCDEF"
set "laa=26AE"
set /a "r1=!random! %% 4"
set "rand_mac=0!laa:~%r1%,1!"
for /L %%i in (1,1,10) do (
    set /a "idx=!random! %% 16"
    for %%j in (!idx!) do set "rand_mac=!rand_mac!!hex:~%%j,1!"
)
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "00*" /k ^| findstr "HKEY_LOCAL_MACHINE"') do (
    reg query "%%i" /v "DriverDesc" >nul 2>&1
    if !errorlevel! == 0 (reg add "%%i" /v "NetworkAddress" /t REG_SZ /d "!rand_mac!" /f >nul 2>&1)
)
echo Restarting !adapter_name!...
powershell -Command "Disable-NetAdapter -InterfaceDescription '!adapter_name!' -Confirm:$false; Enable-NetAdapter -InterfaceDescription '!adapter_name!' -Confirm:$false"
timeout /t 8 >nul
:ping_check_auto_1
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (timeout /t 2 /nobreak >nul & goto :ping_check_auto_1)
for /f "tokens=3 delims=," %%a in ('getmac /v /fo csv ^| findstr /i "!adapter_name!"') do set "new_mac=%%~a"
if "!new_mac!"=="" set "new_mac=!rand_mac!"
echo !new_mac!> "!result_file!"
exit

:restore_mac_auto
set "adapter_name=%~2"
set "result_file=C:\Users\Public\zenith_result.txt"
if "!adapter_name!"=="" (
    for /f "tokens=*" %%a in ('powershell -Command "(Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1).InterfaceDescription"') do set "adapter_name=%%a"
)
if "!adapter_name!"=="" (
    echo FAIL> "!result_file!"
    exit
)
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /v "NetworkAddress" ^| findstr "HKEY_LOCAL_MACHINE"') do (
    reg delete "%%i" /v "NetworkAddress" /f >nul 2>&1
)
echo Restarting !adapter_name!...
powershell -Command "Disable-NetAdapter -InterfaceDescription '!adapter_name!' -Confirm:$false; Enable-NetAdapter -InterfaceDescription '!adapter_name!' -Confirm:$false"
timeout /t 8 >nul
:ping_check_auto_2
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (timeout /t 2 /nobreak >nul & goto :ping_check_auto_2)
for /f "tokens=3 delims=," %%a in ('getmac /v /fo csv ^| findstr /i "!adapter_name!"') do set "new_mac=%%~a"
if "!new_mac!"=="" set "new_mac=Default"
echo !new_mac!> "!result_file!"
exit

:clean_roblox_auto
set "whitelist_regex=%~2"
set "result_file=C:\Users\Public\zenith_result.txt"
set "temp_result=%TEMP%\zen_clean_res.txt"
if exist "!temp_result!" del /q "!temp_result!" >nul 2>&1
if exist "!result_file!" del /q "!result_file!" >nul 2>&1

taskkill /f /im RobloxPlayerBeta.exe >nul 2>&1
echo deleted - RobloxPlayerBeta.exe Process >> "!temp_result!"
taskkill /f /im RobloxStudioBeta.exe >nul 2>&1
echo deleted - RobloxStudioBeta.exe Process >> "!temp_result!"
taskkill /f /im RobloxPlayerLauncher.exe >nul 2>&1
echo deleted - RobloxPlayerLauncher.exe Process >> "!temp_result!"

powershell -ExecutionPolicy Bypass -File "%~dp0rbx_cleaner.ps1" -WhitelistRegex "!whitelist_regex!" >> "!temp_result!"
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" /v "AppCompatCache" /f >nul 2>&1
echo deleted - AppCompatCache System Memory >> "!temp_result!"
move /y "!temp_result!" "!result_file!" >nul 2>&1
exit
