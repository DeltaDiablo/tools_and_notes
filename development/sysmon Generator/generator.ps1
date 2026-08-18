param(
    [string]$ConfigPath = ".\config.json",
    [string]$Mode = "Standard",
    [string]$Technique
)

# ========= MITRE MODE =========
if ($Mode -eq "MITRE") {

    Start-Process cmd.exe -ArgumentList "/c powershell -NoProfile -Command $($t.action)"

    $mitreConfig = Get-Content ".\mitre_config.json" | ConvertFrom-Json

    foreach ($t in $mitreConfig.techniques) {

        if ($Technique -and $t.id -ne $Technique) {
            continue
        }

        Write-Host "Running MITRE Technique: $($t.id) - $($t.name)"

        # Tag for Elastic
        $env:MITRE_TEST = $t.id

        if ($t.action) {
            Start-Process cmd.exe -ArgumentList "/c $($t.action)"
        }

        if ($t.registry) {

            if (!(Test-Path $t.registry.path)) {
                New-Item -Path $t.registry.path -Force | Out-Null
            }

            New-ItemProperty `
                -Path $t.registry.path `
                -Name $t.registry.name `
                -Value $t.registry.value `
                -Force | Out-Null
        }

        Start-Sleep -Seconds $mitreConfig.delay
    }

    return
}

# ========= STANDARD MODE =========
$config = Get-Content $ConfigPath | ConvertFrom-Json

foreach ($test in $config.tests) {

    Write-Host "Running test: $($test.type)"

    switch ($test.type) {

        "ProcessCreate" {
            Start-Process $test.binary -WindowStyle Hidden -PassThru | Out-Null
        }

        "FileCreate" {
            New-Item -Path $test.path -ItemType File -Force
        }

        "Network" {
            try {
                Invoke-WebRequest -Uri $test.url -UseBasicParsing | Out-Null
            } catch {}
        }

        "Registry" {
            if (!(Test-Path $test.path)) {
                New-Item -Path $test.path -Force | Out-Null
            }

            New-ItemProperty -Path $test.path -Name $test.name -Value $test.value -Force | Out-Null
        }

        "DNS" {
            Resolve-DnsName $test.domain | Out-Null
        }
    }

    Start-Sleep -Seconds $config.delay
}
