param (
    [Parameter()]
    [System.String]
    $TemplateFile,

    [Parameter()]
    [System.String]
    $TemplateParameterFile,

    [Parameter()]
    [System.String]
    $ResourceGroupName,

    [Parameter()]
    [System.String]
    $ReportPath
)

if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue))
{
    Write-Host -Object "Resource Group $ResourceGroupName does not exist." -ForegroundColor Green
    return
}

$whatIfResult = Get-AzResourceGroupDeploymentWhatIfResult `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $TemplateParameterFile `
    -ResourceGroupName $ResourceGroupName `
    -ResultFormat FullResourcePayloads

foreach ($change in $whatIfResult.Changes) {
    switch ($change.ChangeType) {
        'NoChange' {
            $TextPrefix = ''
            $Text = 'No Change: Resource already deployed is the same as the template'
        }
        'Modify' {
            $TextPrefix = '##[warning]'
            $Text = 'Modify: Resource will be Updated by the template'
        }
        'Create' {
            $TextPrefix = '##[section]'
            $Text = 'Create: Resource does not exist in the resource group and will be deployed'
        }
        'Ignore' {
            $TextPrefix = ''
            $Text = 'Ignore: Resource exists in Azure but not in the template'
        }
        'Delete' {
            $TextPrefix = '##[error]'
            $Text = 'Delete: Resource exists in Azure but not in the template, Resource will be deleted'
        }
    }

    Write-Host -Object "$($TextPrefix)$($change.ChangeType) $($change.RelativeResourceId)"
    Write-Host -Object "$($TextPrefix)$($Text)"
    Write-Host -Object " `r`n"
}

$whatIfOutput = $whatIfResult | Out-String

# Get rid of ANSI colour codes that appear in output
# from Get-AzResourceGroupDeploymentWhatIfResult
$whatIfOutput = $whatIfOutput -replace '\x1b\[[0-9;]*m',''

if ($ReportPath) {
    Set-Content -Value $whatIfOutput -Path $ReportPath -Force
} else {
    Write-Host -Object $whatIfOutput
}
