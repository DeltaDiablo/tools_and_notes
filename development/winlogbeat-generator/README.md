# generate-winlogbeat-load.ps1

A PowerShell script that writes synthetic Windows Event Log entries covering every ECS event category that Winlogbeat detects. Useful for validating Winlogbeat → Elasticsearch/ECS pipelines without needing to generate real security activity on the host.

---

## What it generates

Each run produces randomly distributed events across 19 Winlogbeat detection points:

| Generator | Windows Event ID(s) | ECS Category |
| --- | --- | --- |
| Logon / Logoff | 4624, 4625, 4634 | `authentication` |
| Process Create / Terminate | 4688, 4689 | `process` |
| Network Connection | Sysmon 3 | `network` |
| File Create / Modify / Delete | Sysmon 11, 2, 23 | `file` |
| Registry Create / Change / Delete | Sysmon 12, 13, 14 | `registry` |
| DNS Query | Sysmon 22 | `network` |
| User / Group Management | 4720–4726, 4732, 4733 | `iam` |
| Service Install / State Change | 7045, 7036 | `process` / `configuration` |
| PowerShell ScriptBlock | 4104 | `process` |
| Scheduled Task Created / Updated | 4698, 4702 | `iam` / `configuration` |
| Driver / Image Load | Sysmon 6 | `driver` |
| WMI Filter / Consumer / Binding | Sysmon 19, 20, 21 | `process` |
| Explicit Credential Use | 4648 | `authentication` |
| Lateral Movement Indicator | Sysmon 1 | `intrusion_detection` |
| NTLM Authentication | 4776 | `authentication` |
| Object / File Access Audit | 4663 | `file` |
| Service Install (Security log) | 4697 | `process` / `configuration` |

Every event includes `host.os.type: windows`, `winlog.channel`, `winlog.event_id`, and `winlog.computer_name` so ECS pipelines correctly identify them as originating from a Windows machine.

---

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- The `WinlogbeatLoadTest` event source must exist in the **Application** log.
  Run the script **once as Administrator** to register it automatically, or register it manually:

```powershell
# Run once as Administrator
New-EventLog -LogName Application -Source WinlogbeatLoadTest
```

> **Non-admin fallback:** If the script is run without elevation and the source has not been registered yet, it will automatically fall back to an existing source such as `Windows PowerShell`.

---

## Configuration

Edit the top of the script to adjust volume:

```powershell
$TotalEvents = 1000   # total number of events to write
$BatchSize   = 100    # events written per loop iteration
$SleepMs     = 50     # milliseconds to pause between batches (0 = max speed)
```

---

## How to run

### Standard run (1 000 events, default settings)

```powershell
.\generate-winlogbeat-load.ps1
```

### Run as Administrator (required once to register the event source)

```powershell
Start-Process pwsh -Verb RunAs -ArgumentList "-File `"$PWD\generate-winlogbeat-load.ps1`""
```

### High-volume run (no pauses)

Edit `$SleepMs = 0` and `$TotalEvents = 10000`, then:

```powershell
.\generate-winlogbeat-load.ps1
```

### Run from any directory

```powershell
pwsh -File "C:\location\to\file\\generate-winlogbeat-load.ps1"
```

---

## Verifying events were written

Open Event Viewer or use PowerShell to confirm entries landed in the Application log:

```powershell
Get-EventLog -LogName Application -Source WinlogbeatLoadTest -Newest 10 |
    Select-Object TimeGenerated, EventID, Message |
    Format-List
```

---

## Expected output

```text
Starting ECS event generation across all Winlogbeat detection points...
  Generators : 19 event types
  Total      : 1000 events  |  Batch: 100  |  Delay: 50ms
  Generated 500 / 1000 events...
  Generated 1000 / 1000 events...
Completed 1000 events in 00:00:05.1234567
```
