function Get-ActiveCount
{
	$staffou="OU=Users,OU=Staff,DC=contoso,DC=local"
	$staffusers=Get-ADUser -filter 'Enabled -eq $true' -SearchBase $staffou
	$stuou="OU=Students,DC=contoso,DC=local"
	$stuusers=Get-ADUser -filter 'Enabled -eq $true' -SearchBase $stuou
	write-host "Current Staff count:"$staffusers.count
	write-host "Current Student count:"$stuusers.count
}