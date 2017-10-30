#Env variables
$desktop=[Environment]::GetFolderPath("Desktop")
$domain="contoso.org"
$root="\\10.10.10.15\users\"

Function DISABLE {

	param (
		[string]$username,
		[string]$deleteemail
	)

	$Log = $desktop + "\User-Automation\DisabledUsers\" + $username + ".txt"

	write-host 'Disabling accounts for ' $username

	$upn = $username+"@"+$domain

	Disable-ADAccount -Identity $username
	Get-ADUser $username | Move-ADObject -TargetPath 'OU=Accounts,OU=Disabled,DC=contoso,Dc=local'

	$User = Get-ADUser $username -Properties memberOf

	$Groups = $User.memberOf |ForEach-Object {
		Get-ADGroup $_
	} 

	Out-File $Log -Append -InputObject $User.memberOf -Encoding utf8

	$Groups | ForEach-Object {Remove-ADGroupMember -Identity $_ -Members $User -Confirm:$false}



	\\10.10.10.10\installs\gam\gam.exe delete user $username

	IF($deleteemail -eq "yes"){
		write-Host "Deleting "$username"'s email account"
		Remove-MsolUser -UserPrincipalName $upn -force
	} else {
		write-Host "Not deleting "$username"'s email account"
		
		$rand = get-random -minimum 100000 -maximum 999999
		$password = $firstname.substring(0,4).toupper()+$lastname.substring(0,4).tolower()+$rand
		
		Set-MsolUserPassword -userPrincipalName $upn -NewPassword $password -ForceChangePassword $false
			
		$mailbox=get-mailbox $upn
		$dgs= Get-DistributionGroup
	 
		foreach($dg in $dgs){
			
			$DGMs = Get-DistributionGroupMember -identity $dg.Identity
			foreach ($dgm in $DGMs){
				if ($dgm.name -eq $mailbox.name){
			   
					write-host $upn 'Found In Group' $dg.identity
					Out-File $Log -Append -InputObject $upn" Found In Group "$dg.identity -encoding utf8
					Remove-DistributionGroupMember $dg.Name -Member $upn -confirm:$false
				}
			}
		}
	}

}
Import-Csv $desktop\User-Automation\disable.csv | ForEach-Object {DISABLE -username $_.username -deleteemail $_.deleteemail}
