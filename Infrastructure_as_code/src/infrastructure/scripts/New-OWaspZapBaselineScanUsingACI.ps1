[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [System.String]
    $TargetScanUri,

    [Parameter()]
    [System.Int32]
    $SpiderTime = 1,

    [Parameter(Mandatory = $true)]
    [System.String]
    $ContainerGroupName,

    [Parameter()]
    [System.String]
    $OwaspImage = 'owasp/zap2docker-weekly',

    [Parameter(Mandatory = $true)]
    [System.String]
    $StorageAccountName,

    [Parameter()]
    [System.String]
    $StorageAccountSku = 'Standard_LRS',

    [Parameter()]
    [System.String]
    $StorageContainerName = 'reports',

    [Parameter(Mandatory = $true)]
    [System.String]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [System.String]
    $Location,

    [Parameter()]
    [System.String]
    $HtmlReportName = 'testresults.html',

    [Parameter()]
    [System.String]
    $XmlReportName = 'testresults.xml',

    [Parameter()]
    [System.Int32]
    $ContainerCpu = 1,

    [Parameter()]
    [System.Double]
    $ContainerMemoryInGb = 1.5
)

# Supporting functions
function Convert-OWaspZapXMLToNUnit
{
    [CmdletBinding()]
$xsltConvert = @'
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="sourceFolder"/>

  <xsl:variable name="NumberOfItems" select="count(OWASPZAPReport/site/alerts/alertitem)"/>
  <xsl:variable name="generatedDateTime" select="OWASPZAPReport/generated"/>

  <xsl:template match="/">
    <test-run id="1" name="OWASPReport" fullname="OWASPConvertReport" testcasecount="" result="Failed" total="{$NumberOfItems}" passed="0" failed="{$NumberOfItems}" inconclusive="0" skipped="0" asserts="{$NumberOfItems}" engine-version="3.9.0.0" clr-version="4.0.30319.42000" start-time="{$generatedDateTime}" end-time="{$generatedDateTime}" duration="0">
      <command-line>a</command-line>
      <test-suite type="Assembly" id="0-1005" name="OWASP" fullname="OWASP" runstate="Runnable" testcasecount="{$NumberOfItems}" result="Failed" site="Child" start-time="{$generatedDateTime}" end-time="{$generatedDateTime}" duration="0.352610" total="{$NumberOfItems}" passed="0" failed="{$NumberOfItems}" warnings="0" inconclusive="0" skipped="0" asserts="{$NumberOfItems}">

        <environment framework-version="3.11.0.0" clr-version="4.0.30319.42000" os-version="Microsoft Windows NT 10.0.17763.0" platform="Win32NT" cwd="C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" machine-name="Azure Hosted Agent" user="flacroix" user-domain="NORTHAMERICA" culture="en-US" uiculture="en-US" os-architecture="x86" />
        <test-suite type="TestSuite" id="0-1004" name="UnitTestDemoTest" fullname="UnitTestDemoTest" runstate="Runnable" testcasecount="2" result="Failed" site="Child" start-time="2019-02-01 17:03:03Z" end-time="2019-02-01 17:03:04Z" duration="0.526290" total="2" passed="1" failed="1" warnings="0" inconclusive="0" skipped="0" asserts="1">
          <test-suite type="TestFixture" id="0-1000" name="UnitTest1" fullname="UnitTestDemoTest.UnitTest1" classname="UnitTestDemoTest.UnitTest1" runstate="Runnable" testcasecount="2" result="Failed" site="Child" start-time="2019-02-01 17:03:03Z" end-time="2019-02-01 17:03:04Z" duration="0.495486" total="2" passed="1" failed="1" warnings="0" inconclusive="0" skipped="0" asserts="1">
            <attachments>
              <attachment>
                <descrition>
                  Original OWASP Report
                </descrition>
                <filePath>
                  <xsl:value-of select="$sourceFolder"/>\tests\OWASP-ZAP-Report.xml
                </filePath>
              </attachment>
              <attachment>
                <descrition>
                  Original OWASP Report 2
                </descrition>
                <filePath>
                  ($System.DefaultWorkingDirectory)\tests\OWASP-ZAP-Report.xml
                </filePath>
              </attachment>
            </attachments>
            <xsl:for-each select="OWASPZAPReport/site/alerts/alertitem">
            <test-case id="0-1001" name="{name}" fullname="{name}" methodname="Stub" classname="UnitTestDemoTest.UnitTest1" runstate="NotRunnable" seed="400881240" result="Failed" label="Invalid" start-time="{$generatedDateTime}" end-time="{$generatedDateTime}" duration="0" asserts="0">
              <failure>
                <message>
                  <xsl:value-of select="desc"/>.
                  <xsl:value-of select="solution"/>
                </message>
                <stack-trace>
                  <xsl:for-each select="instances/instance">
                    <xsl:value-of select="uri"/>, <xsl:value-of select="method"/>, <xsl:value-of select="param"/>,
                  </xsl:for-each>
                </stack-trace>
              </failure>
            </test-case>
            </xsl:for-each>
          </test-suite>
        </test-suite>
      </test-suite>
    </test-run>
  </xsl:template>
</xsl:stylesheet>
'@

}

# Main function code
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if ($null -eq $resourceGroup)
{
    Write-Verbose -Message ('Creating resource group "{0}" in "{1}".' -f $ResourceGroupName, $Location)

    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue

if ($null -eq $storageAccount)
{
    Write-Verbose -Message ('Creating storage account "{0}" as "{1}".' -f $StorageAccountName, $StorageAccountSku)

    $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -SkuName $StorageAccountSku
}

# Create the Container in the Storage account
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey
$storageContainer = Get-AzStorageContainer -Context $storageContext -Name $StorageContainerName -ErrorAction SilentlyContinue

if ($null -eq $storageContainer) {
    Write-Verbose -Message ('Creating storage account container "{0}".' -f $StorageContainerName)

    $storageContainer = New-AzStorageContainer -Context $storageContext -Name $storageContainerName
}

# Generate SAS Token for report file upload
$containerSasToken = $storageContainer | New-AzStorageContainerSasToken -Permission rw

# Generate script to execute to initialize Zap and perform scan
$zapScript = @"
#!/bin/bash
(zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.key=abcd -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true) &
mkdir output && ln -s output wrk && sleep 30
(/zap/zap-baseline.py -t $TargetScanUri -d -m $SpiderTime -x $XmlReportName -r $HtmlReportName) &
sleep 10
wget --method=PUT --header=`"x-ms-blob-type: BlockBlob`" --body-file=output/$xmlReportName `"https://$StorageAccountName.blob.core.windows.net/$StorageContainerName/$($XmlReportName)$containerSasToken
wget --method=PUT --header=`"x-ms-blob-type: BlockBlob`" --body-file=output/$HtmlReportName `"https://$StorageAccountName.blob.core.windows.net/$StorageContainerName/$($HtmlReportName)$containerSasToken
"@ -replace "`r`n","`n"

Write-Verbose -Message ('Writing zapscript.sh to storage container "{0}".' -f $storageContainerName)
Write-Verbose -Message ($zapScript | Out-String)

$zapScriptPath = "$ENV:Temp\zapscript.sh"
$zapScript | Set-Content -Path $zapScriptPath -Force
$null = Set-AzStorageBlobContent -Context $storageContext -Container $storageContainerName -File $zapScriptPath -Blob 'zapscript.sh'
$null = Remove-Item -Path $zapScriptPath -Force

# Create the OWasp container
$containerGroup = Get-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $ContainerGroupName -ErrorAction SilentlyContinue

if ($null -ne $containerGroup) {
    $null = Remove-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $ContainerGroupName -Confirm:$false
}

$containerCommandLine = "/bin/bash -c 'wget -O - `"https://$StorageAccountName.blob.core.windows.net/$StorageContainerName/zapscript.sh$containerSasToken`" | bash'"
Write-Verbose -Message ('Creating container group "{0}".' -f $ContainerGroupName)

New-AzContainerGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName `
    -Image $OwaspImage `
    -RestartPolicy Never `
    -Cpu $ContainerCpu `
    -MemoryInGB $ContainerMemoryInGb `
    -OsType Linux `
    -Command $containerCommandLine `
    -Location $Location

# Get-OWaspZapReportFile

# Convert-OWaspZapReportFile

# Clean up by removing resource group
$null = Remove-AzResourceGroup -Name $ResourceGroupName
