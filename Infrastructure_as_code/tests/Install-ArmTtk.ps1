$armTemplateToolKitFolder = "$ENV:Temp\arm-template-toolkit"
$armTemplateToolkitDownloadPath = "$armTemplateToolKitFolder\arm-template-toolkit.zip"
$armTemplateToolkitModuleManifestPath = "$armTemplateToolKitFolder\arm-ttk\arm-ttk.psd1"

<#
    Download the ARM-TTK if it does not already exist and expand it
    to a temporary folder
#>
if (-not (Test-Path -Path $armTemplateToolkitModuleManifestPath)) {
    Write-Verbose -Message 'Downloading ARM-TTK...'
    $webClient = New-Object -TypeName System.Net.WebClient
    $webClient.DownloadFile('https://azurequickstartsservice.blob.core.windows.net/ttk/latest/arm-template-toolkit.zip', $armTemplateToolkitDownloadPath)

    Write-Verbose -Message 'Extracting ARM-TTK...'
    Expand-Archive -Path $armTemplateToolkitDownloadPath -DestinationPath $armTemplateToolKitFolder -Force
}

Import-Module -Name $armTemplateToolkitModuleManifestPath