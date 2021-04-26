& "$PSScriptRoot\Install-ArmTtk.ps1"

Test-AzTemplate -TemplatePath "$PSScriptRoot\..\src\infrastructure\fail\ttk-fail"
