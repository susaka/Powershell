$creds = Get-Credential
$date = get-date -Format "yyyy-MM-dd"
$filename = "DCtest" + $date + ".txt"
$domainControllers = @('Example1.domain','Example2.domain')

foreach ($computer in $domainControllers)
{
  write-output "------------------------------" | out-file $filename -Append
  write-output "Connecting to $computer" | out-file $filename -Append
  write-output "------------------------------" | out-file $filename -Append
  write-output "" | out-file $filename -Append
  write-output "Connecting to $computer"

  try {
    invoke-command -credential $creds -computername $computer -scriptblock {
      write-output "---------------"
      write-output "REPLSUMMARY"
      repadmin /replsummary
      write-output "---------------"
      write-output ""
      write-output "---------------"
      write-output "Testing NTP"
      w32tm /query /status
      write-output "---------------"
      write-output ""
      write-output "---------------"
      write-output "Testing FSMO roles"
      dcdiag /test:FSMOCheck
      write-output "---------------"
      write-output ""
      write-output "---------------"
      write-output "Testing DC replication"
      dcdiag /test:Replications
      write-output "---------------"
      write-output ""
      write-output "---------------"
      write-output "Testing DNS"
      dcdiag /test:DNS /DnsAll
      write-output "---------------"
      write-output ""
    } | out-file $filename -Append
  }
  catch {
    Write-Output "Error occoured connecting to $computer" | out-file $filename -Append
    Write-Output $_ | out-file $filename -Append
  }
}