
param(
    [string]$Technique
)

while ($true) {

    if ($Technique) {
        Write-Host "Running MITRE technique: $Technique"
        .\generator.ps1 -Mode MITRE -Technique $Technique
    }
    else {
        Write-Host "Running ALL MITRE techniques"
        .\generator.ps1 -Mode MITRE
    }
    }