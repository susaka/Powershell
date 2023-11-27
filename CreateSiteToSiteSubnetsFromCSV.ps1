#EXPECTED CSV FORMAT
#UR-navn;Site-nummer;Site-navn;IP / subnet;Formål;;;;;;;
###
#Eksempel
#UR-navn;Site-nummer;Site-navn;IP / subnet;Formål;;;;;;;

# FIND og importer CSV filen på lokal computeren ved hjælp af en form
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
$null = $FileBrowser.ShowDialog()
$SubnetsCSV = Import-Csv -path $FileBrowser.FileName -Delimiter ";"

#Få korrekte credentials
$credsDC = Get-Credential -Message "DOA bruger"
$DCName = "v-inet02"

#Få en oversigt over eksisterende subnet
$subnetsDC = get-AdReplicationSubnet -filter * -Server $DCName -Credential $credsDC

#Opretter logfil
$date = Get-Date -Format "dd/MM/yyyy"
$filename = "SubnetReport_$date.txt"
Write-Output "Logfile for Subnet from CSV" | Out-File -FilePath .\$filename
Write-Output $date | Out-File -FilePath .\$filename -Append

#Sammenlign eksisterende subnets med dem fra CSV fil
foreach ($lineCSV in $SubnetsCSV)
{
  $exist = $false
  Foreach ($lineDC in $subnetsDC)
  {
    $siteDC = $lineDC.Site
    $IPDC = $lineDC.Name

    $siteCSV0 = $lineCSV.'Site-nummer'
    $siteCSVFinal = "CN=" + $siteCSV0 + ",CN=Sites,CN=Configuration,DC=INTOPS,DC=DK"
    $IPCSV = $lineCSV.'IP / Subnet'

    #sammenligner sites og subnet
    if ($siteCSVFinal -eq $siteDC -and $IPCSV -eq $IPDC)
    {
      $exist = $true
    }
  }
  # Opret subnet hvis det ikke allerede eksistere
  $location0 = $lineCSV.'Site-nummer'
  $locationFinal = "CN=" + $location0 + ",CN=Sites,CN=Configuration,DC=INTOPS,DC=DK"
  $IP = $lineCSV.'IP / Subnet'
  $Descript0 = $lineCSV.'UR-navn'
  $Descript1 = $lineCSV.'Formaal'
  $DescriptFinal = "$Descript0 $location0 $Descript1"  
 
  if ($exist)
  {  
    Write-Output "IP'en: $IP på sitet: $locationFinal med beskrivelsen: $DescriptFinal - Eksisterer!" | Out-File -FilePath .\$filename -Append
  }
  else
  {
    write-output "Opretter $IP på site: $locationFinal med beskrivelsen $DescriptFinal" | Out-File -FilePath .\$filename -Append
    try { New-AdReplicationSubnet -name $IP -site $locationFinal -Description $DescriptFinal -Server $DCName -Credential $credsDC }
    catch {Write-Output "Fejl ved oprettelse! - Error besked: $_" | Out-File -FilePath .\$filename -Append}
  }
}