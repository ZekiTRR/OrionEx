param(
    [string]$WhitelistRegex = ""
)

$ErrorActionPreference = 'SilentlyContinue'


function MatchBinaryRoblox([byte[]]$bytes) {
    if ($null -eq $bytes -or $bytes.Length -lt 6) { return $false }
    
    try {
        $asciiStr = [System.Text.Encoding]::ASCII.GetString($bytes)
        if ($asciiStr -match "(?i)roblox") { return $true }
    } catch {}
    
    try {
        $uniStr = [System.Text.Encoding]::Unicode.GetString($bytes)
        if ($uniStr -match "(?i)roblox") { return $true }
    } catch {}
    
    try {
        $uniBEStr = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes)
        if ($uniBEStr -match "(?i)roblox") { return $true }
    } catch {}

    try {
        $utf8Str = [System.Text.Encoding]::UTF8.GetString($bytes)
        if ($utf8Str -match "(?i)roblox") { return $true }
    } catch {}

    
    try {
        $hex = [System.BitConverter]::ToString($bytes)
        
        if ($hex -match "(72|52)-(6F|4F)-(62|42)-(6C|4C)-(6F|4F)-(78|58)") { return $true }
        if ($hex -match "(72|52)-00-(6F|4F)-00-(62|42)-00-(6C|4C)-00-(6F|4F)-00-(78|58)-00") { return $true }
        if ($hex -match "00-(72|52)-00-(6F|4F)-00-(62|42)-00-(6C|4C)-00-(6F|4F)-00-(78|58)") { return $true }
    } catch {}

    return $false
}


function SweepRegistryKey([Microsoft.Win32.RegistryKey]$key, [string]$path) {
    if ($null -eq $key) { return }
    
    
    try {
        $valNames = $key.GetValueNames()
        foreach ($vn in $valNames) {
            $match = $false
            if ($vn -match "(?i)roblox") {
                $match = $true
            } else {
                $val = $key.GetValue($vn, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                if ($null -ne $val) {
                    if ($val -is [string] -and $val -match "(?i)roblox") {
                        $match = $true
                    } elseif ($val -is [array] -or $val.GetType().IsArray) {
                        if (MatchBinaryRoblox $val) {
                            $match = $true
                        }
                    }
                }
            }
            
            if ($match) {
                Write-Output "deleted registry value - $vn from $path"
                try { $key.DeleteValue($vn, $false) } catch {}
            }
        }
    } catch {}
    
    
    try {
        $subKeys = $key.GetSubKeyNames()
        foreach ($sk in $subKeys) {
            $subPath = "$path\$sk"
            if ($sk -match "(?i)roblox") {
                Write-Output "deleted registry key - $subPath"
                try { $key.DeleteSubKeyTree($sk, $false) } catch {}
            } else {
                try {
                    $subKey = $key.OpenSubKey($sk, $true)
                    if ($null -ne $subKey) {
                        SweepRegistryKey $subKey $subPath
                        $subKey.Close()
                    }
                } catch {}
            }
        }
    } catch {}
}


Write-Output "Cleaning Files & Folders..."
$users = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue
$dirs = @('C:\ProgramData', 'C:\Program Files (x86)', 'C:\Program Files', 'C:\Windows\Prefetch', 'C:\v2\data\cache')
foreach ($u in $users) {
    $dirs += "$($u.FullName)\AppData\Local"
    $dirs += "$($u.FullName)\AppData\Roaming"
    $dirs += "$($u.FullName)\Desktop"
    $dirs += "$($u.FullName)\Downloads"
    $dirs += "$($u.FullName)\Documents"
    $dirs += "$($u.FullName)\Music"
    $dirs += "$($u.FullName)\Videos"
    $dirs += "$($u.FullName)\Pictures"
    $dirs += "$($u.FullName)\Saved Games"
    $dirs += "$($u.FullName)\Contacts"
    $dirs += "$($u.FullName)\Links"
    $dirs += "$($u.FullName)\Searches"
    $dirs += "$($u.FullName)\Favorites"
    
    
    $oneDrive = "$($u.FullName)\OneDrive"
    if (Test-Path $oneDrive) {
        $dirs += "$oneDrive\Desktop"
        $dirs += "$oneDrive\Documents"
        $dirs += "$oneDrive\Pictures"
        $dirs += "$oneDrive\Music"
        $dirs += "$oneDrive\Videos"
    }
}

foreach ($d in $dirs) {
    if (Test-Path $d) {
        Get-ChildItem -Path $d -Recurse -Filter '*roblox*' -ErrorAction SilentlyContinue | Where-Object { 
            if ([string]::IsNullOrWhiteSpace($WhitelistRegex)) { $true }
            else { $_.FullName -notmatch $WhitelistRegex }
        } | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} | ForEach-Object {
            $t = $_.FullName
            if (Test-Path -LiteralPath $t) {
                if (Test-Path -LiteralPath $t -PathType Container) {
                    Get-ChildItem -Path $t -Recurse -ErrorAction SilentlyContinue | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} | ForEach-Object {
                        Write-Output ("deleted file/folder - " + $_.FullName)
                    }
                }
                Write-Output ("deleted file/folder - " + $t)
                Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}


Write-Output "Cleaning Registry..."


try {
    $hkcuSoft = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software", $true)
    SweepRegistryKey $hkcuSoft "HKEY_CURRENT_USER\Software"
    if ($null -ne $hkcuSoft) { $hkcuSoft.Close() }
} catch {}


try {
    $hkcuSys = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("System", $true)
    SweepRegistryKey $hkcuSys "HKEY_CURRENT_USER\System"
    if ($null -ne $hkcuSys) { $hkcuSys.Close() }
} catch {}


try {
    $hkcuCp = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Control Panel", $true)
    SweepRegistryKey $hkcuCp "HKEY_CURRENT_USER\Control Panel"
    if ($null -ne $hkcuCp) { $hkcuCp.Close() }
} catch {}


try {
    $hkcuEnv = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
    SweepRegistryKey $hkcuEnv "HKEY_CURRENT_USER\Environment"
    if ($null -ne $hkcuEnv) { $hkcuEnv.Close() }
} catch {}
try {
    $hkcuVenv = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Volatile Environment", $true)
    SweepRegistryKey $hkcuVenv "HKEY_CURRENT_USER\Volatile Environment"
    if ($null -ne $hkcuVenv) { $hkcuVenv.Close() }
} catch {}


try {
    $userHives = Get-ChildItem -Path 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match 'S-1-5-21' -and $_.PSChildName -notmatch '_Classes' }
    foreach ($h in $userHives) {
        $sid = $h.PSChildName
        try {
            $userKey = [Microsoft.Win32.Registry]::Users.OpenSubKey($sid, $true)
            if ($null -ne $userKey) {
                
                try {
                    $uSoft = $userKey.OpenSubKey("Software", $true)
                    SweepRegistryKey $uSoft "HKEY_USERS\$sid\Software"
                    if ($null -ne $uSoft) { $uSoft.Close() }
                } catch {}
                
                
                try {
                    $uSys = $userKey.OpenSubKey("System", $true)
                    SweepRegistryKey $uSys "HKEY_USERS\$sid\System"
                    if ($null -ne $uSys) { $uSys.Close() }
                } catch {}
                
                
                try {
                    $uCp = $userKey.OpenSubKey("Control Panel", $true)
                    SweepRegistryKey $uCp "HKEY_USERS\$sid\Control Panel"
                    if ($null -ne $uCp) { $uCp.Close() }
                } catch {}
                
                
                try {
                    $uEnv = $userKey.OpenSubKey("Environment", $true)
                    SweepRegistryKey $uEnv "HKEY_USERS\$sid\Environment"
                    if ($null -ne $uEnv) { $uEnv.Close() }
                } catch {}
                try {
                    $uVenv = $userKey.OpenSubKey("Volatile Environment", $true)
                    SweepRegistryKey $uVenv "HKEY_USERS\$sid\Volatile Environment"
                    if ($null -ne $uVenv) { $uVenv.Close() }
                } catch {}
                
                $userKey.Close()
            }
        } catch {}
    }
} catch {}


try {
    $hkcr = [Microsoft.Win32.Registry]::ClassesRoot
    $hkcrNames = $hkcr.GetSubKeyNames()
    foreach ($n in $hkcrNames) {
        if ($n -match "(?i)roblox") {
            Write-Output "deleted registry key - HKEY_CLASSES_ROOT\$n"
            try { $hkcr.DeleteSubKeyTree($n, $false) } catch {}
        }
    }
} catch {}


try {
    $hklmSoft = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE", $true)
    if ($null -ne $hklmSoft) {
        $targets = @(
            "Microsoft\Windows\CurrentVersion\Uninstall",
            "WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "Microsoft\Internet Explorer\ProtocolExecute",
            "WOW6432Node\Microsoft\Internet Explorer\ProtocolExecute",
            "Microsoft\RADAR\HeapLeakDetection\DiagnosedApplications",
            "RegisteredApplications",
            "WOW6432Node\RegisteredApplications",
            "Microsoft\Windows\CurrentVersion\UFH\ARP",
            "Microsoft\WindowsSelfHost"
        )
        foreach ($t in $targets) {
            try {
                $subKey = $hklmSoft.OpenSubKey($t, $true)
                if ($null -ne $subKey) {
                    SweepRegistryKey $subKey "HKEY_LOCAL_MACHINE\SOFTWARE\$t"
                    $subKey.Close()
                }
            } catch {}
        }
        
        
        try {
            $hklmClasses = $hklmSoft.OpenSubKey("Classes", $true)
            if ($null -ne $hklmClasses) {
                $hklmClassNames = $hklmClasses.GetSubKeyNames()
                foreach ($n in $hklmClassNames) {
                    if ($n -match "(?i)roblox") {
                        Write-Output "deleted registry key - HKEY_LOCAL_MACHINE\SOFTWARE\Classes\$n"
                        try { $hklmClasses.DeleteSubKeyTree($n, $false) } catch {}
                    }
                }
                $hklmClasses.Close()
            }
        } catch {}
        
        $hklmSoft.Close()
    }
} catch {}


try {
    $hklmSys = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM", $true)
    if ($null -ne $hklmSys) {
        $sysTargets = @(
            "CurrentControlSet\Services\bam\State\UserSettings",
            "ControlSet001\Services\bam\State\UserSettings",
            "CurrentControlSet\Services\bam\UserSettings",
            "ControlSet001\Services\bam\UserSettings"
        )
        foreach ($st in $sysTargets) {
            try {
                $subKey = $hklmSys.OpenSubKey($st, $true)
                if ($null -ne $subKey) {
                    SweepRegistryKey $subKey "HKEY_LOCAL_MACHINE\SYSTEM\$st"
                    $subKey.Close()
                }
            } catch {}
        }
        $hklmSys.Close()
    }
} catch {}
