 Powershell script to get users that haven't logged in for 180 days and check for empty OUs.

#Variables
$credsDC = Get-Credential
$date = Get-date
$dateFormat= Get-date -Format "dd/MM/yyyy"
$Filename = "OldUsers_And_EmptyOUs_" + $dateFormat + ".txt"
$PSDefaultParameterValues['out-file:width'] = 2000

$server = 'DC_HOSTANME'
$SearchBase = 'OU=ExampleOU,OU=Domain Users,DC=EXAMPLE,DC=LOCAL' #LDAP style path to OU
$DisabledUsers = 'OU=_Disabled Users,' + $SearchBase # Path to OU for disabled users
$GuestOU = 'OU=Guests,OU=LOCATION,' + $SearchBase

$OUs = get-ADOrganizationalUnit -Credential $credsDC -Server $server -Filter * -SearchBase $SearchBase
$Users = Get-ADUser -Credential $credsDC -Server $server -Filter * -SearchBase $SearchBase -Properties *

# Find all old users and add to list in file
$OldUsers = @()

foreach ($User in $Users)
{
  if ($User.Enabled -eq $false -and $User.LastLogonDate -le $date.AddDays(-180) -and $User.DistinguishedName -notmatch $DisabledUsers -and $User.DistinguishedName -notmatch $GuestOU)
  {
    $OldUsers += $User
  }
}

# Find all empty OUs and to list in file
$EmptyOUs = @()

foreach ($OU in $OUs)
{
  $IsEmpty = $true
  foreach ($OUuser in $Users)
  {
    if ($OUuser.DistinguishedName -match $OU.DistinguishedName -and $OldUsers -notcontains $OUuser)
    {
      $IsEmpty = $false
    }
  }

  if ($IsEmpty)
  {
    $EmptyOUs += $OU
  }
}

# Format output file
Write-Output '########################################' | out-file -FilePath $Filename
Write-Output "Finding old users and empty OUs" | out-file -FilePath $Filename -Append
Write-Output "Run date: $date" | out-file -FilePath $Filename -Append
Write-Output '########################################' | out-file -FilePath $Filename -Append
Write-Output "Printing found old users" | out-file -FilePath $Filename -Append
Write-Output '########################################' | out-file -FilePath $Filename -Append
Write-Output $OldUsers | Select-Object -Property Name,whenCreated,LastLogonDate,DistinguishedName |Sort-Object -Property LastLogonDate| Format-Table -AutoSize -Wrap | out-file -FilePath $Filename -Append
Write-Output '########################################' | out-file -FilePath $Filename -Append
Write-Output '########################################' | out-file -FilePath $Filename -Append
Write-Output "Printing found empty OUs" | out-file -FilePath $Filename -Append
Write-Output '########################################' | out-file -FilePath $Filename -Append
Write-Output $EmptyOUs | Select-Object -Property Name,DistinguishedName | Format-Table -AutoSize -Wrap | out-file -FilePath $Filename -Append
Write-Output '########################################' | out-file -FilePath $Filename -Append