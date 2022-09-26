sp_revlogin alternative

http://www.sql-server-pro.com/sp_help_revlogin-alternative.html



param ([string]$Principal, [string]$Mirror) 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null 
$ErrorActionPreference = "Stop" 
$ps = New-Object Microsoft.SqlServer.Management.Smo.Server $Principal 
$ms = New-Object Microsoft.SqlServer.Management.Smo.Server $Mirror 
if (-not $ps.Databases.Count) 
{ 
        "Could not connect to $Principal" 
        return 
} 
if (-not $ms.Databases.Count) 
{ 
        "Could not connect to $Mirror" 
        return 
} 
"-------------------------------------------------------" 
"-- The following script should be run on $Mirror." 
"-------------------------------------------------------" 
foreach ($login in $ps.Logins) 
{ 
        if ("sa", "NT AUTHORITY\SYSTEM", "BUILTIN\ADMINISTRATORS" -contains $login.Name) 
        { 
                continue 
        } 
        $psid = "" 
        if ("WindowsGroup", "WindowsUser" -notcontains $login.LoginType) 
        { 
                $login.Sid | % {$psid += ("{0:X}" -f $_).PadLeft(2, "0")} 
                [byte[]] $phash = $ps.Databases["master"].ExecuteWithResults("select hash=cast(loginproperty('$($login.Name)', 'PasswordHash') as varbinary(256))").Tables[0].Rows[0].Hash
                $ppwd = "" 
                $phash | % {$ppwd += ("{0:X}" -f $_).PadLeft(2, "0")} 
        } 
        $defaultDatabase = "master" 
        $ms.Databases[$login.DefaultDatabase] | ? {$_.Status -eq "Normal"} | % {$defaultDatabase = $_.Name} 
        $dropped = $false 
        if ($ms.Logins[$login.Name]) 
        { 
                if ("WindowsGroup", "WindowsUser" -notcontains $login.LoginType) 
                { 
                        $msid = "" 
                        $ms.Logins[$login.Name].Sid | % {$msid += ("{0:X}" -f $_).PadLeft(2, "0")} 
                        if ($psid -ne $msid) 
                        { 
                                "drop login [$($login.Name)];" 
                                $dropped = $true 
                        } 
                        [byte[]] $mhash = $ms.Databases["master"].ExecuteWithResults("select hash=cast(loginproperty('$($login.Name)', 'PasswordHash') as varbinary(256))").Tables[0].Rows[0].Hash
                        $mpwd = "" 
                        $mhash | % {$mpwd += ("{0:X}" -f $_).PadLeft(2, "0")} 
                        if (-not $dropped -and $ppwd -ne $mpwd) 
                        { 
                                "alter login [$($login.Name)] with password = 0x$ppwd hashed;" 
                        } 
                } 
                if (-not $dropped -and $ms.Logins[$login.Name].DefaultDatabase -ne $defaultDatabase) 
                { 
                        "alter login [$($login.Name)] with default_database = [$defaultDatabase];" 
                } 
        } 
        
        if (-not $ms.Logins[$login.Name] -or $dropped) 
        { 
                if ("WindowsGroup", "WindowsUser" -contains $login.LoginType) 
                { 
                        "create login [$($login.Name)] from windows with default_database = [$defaultDatabase];" 
                } 
                else 
                { 
                        if ($login.PasswordExpirationEnabled) 
                        { 
                                $checkExpiration = "on" 
                        } 
                        else 
                        { 
                                $checkExpiration = "off" 
                        } 
                        if ($login.PasswordPolicyEnforced) 
                        { 
                                $checkPolicy = "on" 
                        } 
                        else 
                        { 
                                $checkPolicy = "off" 
                        } 
                        "create login [$($login.Name)] with password = 0x$ppwd hashed, sid = 0x$psid, default_database = [$defaultDatabase], check_policy = $checkPolicy, check_expiration = $checkExpiration;"
                        if ($login.DenyWindowsLogin) 
                        { 
                                "deny connect sql to [$($login.Name)];" 
                        } 
                        if (-not $login.HasAccess) 
                        { 
                                "revoke connect sql to [$($login.Name)];" 
                        } 
                        if ($login.IsDisabled) 
                        { 
                                "alter login [$($login.Name)] disable;" 
                        } 
                } 
        } 
        foreach ($role in $ps.Roles | ? {$_.Name -ne "public"}) 
        { 
                $addRole = $false 
                if (-not $ms.Logins[$login.Name]) 
                { 
                        $addRole = $login.IsMember($role.Name) 
                } 
                elseif ($dropped -or -not $ms.Logins[$login.Name].IsMember($role.Name)) 
                { 
                        $addRole = $login.IsMember($role.Name) 
                } 
                if ($addRole) 
                { 
                        "exec sp_addsrvrolemember @loginame = N'$($login.Name)', @rolename = N'$($role.Name)';" 
                } 
        } 
        
        foreach ($db in $ms.Databases | ? {$_.Status -eq "Normal"}) 
        { 
                $user = $null 
                $user = $db.Users | ? {$_.Login -eq $login.Name} 
                if ($user) 
                { 
                        if ($psid -ne "") 
                        { 
                                $usid = "" 
                                $user.Sid | % {$usid += ("{0:X}" -f $_).PadLeft(2, "0")} 
                                if ($usid -ne $psid) 
                                { 
                                        "use $($db.Name); alter user [$($user.Name)] with login = [$($login.Name)];" 
                                } 
                        } 
                } 
        } 
} 
#if in principal databases, but not on mirror, add user 
$principalUsers = $ps.Databases | 
        ? {$_.Status -eq "Normal"} | 
        % {$db = $_.Name; $_.Users | ? {$_.Login -ne ""} | 
        Select @{n="Database";e={$db}}, Name, Login} 
$mirrorUsers = $ms.Databases | 
        ? {$_.Status -eq "Normal"} | 
        % {$db = $_.Name; $_.Users | ? {$_.Login -ne ""} | 
        Select @{n="Database";e={$db}}, Name, Login} 
foreach ($user in $principalUsers) 
{ 
        if (-not ($ms.Databases | ? {$_.Status -eq "Normal" -and $_.Name -eq $user.Database})) 
        { 
                continue 
        } 
        if ($ms.Databases[$user.Database].Users[$user.Name]) 
        { 
                continue 
        } 
        if (-not $ps.Logins[$user.Login]) 
        { 
                continue 
        } 
        "use [$($user.Database)]; create user [$($user.Name)] for login [$($user.Login)];" 
} 
#if in principal databases, but not on mirror, add to roles 
$principalDbRoles = $ps.Databases | 
        ? {$_.Status -eq "Normal"} | 
        % {$db = $_.Name; $roles = $_.Roles; $roles | 
                % {$role = $_.Name; $_.EnumMembers() | ? {-not $roles[$_]} | 
                        Select @{n="Database";e={$db}}, @{n="Role";e={$role}}, @{n="Member";e={$_}}}} 
$mirrorDbRoles = $ms.Databases | 
        ? {$_.Status -eq "Normal"} | 
        % {$db = $_.Name; $roles = $_.Roles; $roles | 
                % {$role = $_.Name; $_.EnumMembers() | ? {-not $roles[$_]} | 
                        Select @{n="Database";e={$db}}, @{n="Role";e={$role}}, @{n="Member";e={$_}}}} 
        $lookup = @{} 
$mirrorDbRoles | % {$lookup.$($_.Database + ":" + $_.Role + ":" + $_.Member) = 1} 
foreach ($dbRole in $principalDbRoles) 
{ 
        if (-not $lookup.ContainsKey("$($dbRole.Database):$($dbRole.Role):$($dbRole.Member)")) 
        { 
                if (-not ($ms.Databases | ? {$_.Status -eq "Normal" -and $_.Name -eq $dbRole.Database})) 
                { 
                        continue 
                } 
                "use [$($dbRole.Database)]; exec sp_addrolemember N'$($dbRole.Role)', N'$($dbRole.Member)';" 
        } 
}


Copy this into a text file, and save as "ScriptLoginDiffs.ps1". 
 From within PowerShell, run the script as follows: 

PS C:\> .\ScriptLoginDiffs.ps1 -Principal Server1\Inst1 -Mirror Server2\Inst2


The output is displayed to the console, but can be redirected to a file as follows: 

PS C:\> .\ScriptLoginDiffs.ps1 -Principal Server1\Inst1 -Mirror Server2\Inst2 > NewLogins.sql
