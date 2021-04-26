& "$PSScriptRoot\Install-ArmTtk.ps1"

Get-ChildItem -Path "$PSScriptRoot\..\src\infrastructure\all\*.json" | Test-AzTemplate
