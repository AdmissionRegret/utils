$domain="contoso.org"

function func1 {
	#Set password
	$username = "***"
	$pass = "***"
	$username = read-host -prompt "Enter Username"
	$upn = $username+"@"+$domain
	$pass = read-host -prompt "Enter Password"

	if ($username -eq "***") {
	exit
	}
	if ($pass -eq "***") {
	exit
	}

	Set-MsolUserPassword -userPrincipalName $upn -NewPassword $pass -ForceChangePassword $false
}

function func2 {
	#Create group, Transport Rule, and adds users
	$name = "***"
	$email = "***" 
	$username = "***"
	$name = read-host -prompt "Enter Group Name"
	$email = read-host -prompt "Enter Email Address (Leave off @Domain)"
	$username = read-host -prompt "Enter Usernames you want added to the group seperated by spaces"
	$upn = $email+"@"+$domain
	$prepend = "["+$name+"] - "

	if ($name -eq "***") {
	exit
	}
	if ($email -eq "***") {
	exit
	}
	if ($username -eq "***") {
	exit
	}

	New-DistributionGroup -Name $name -DisplayName $name -PrimarySMTPAddress $upn

	#New-TransportRule -Name $name -AnyOfToCcHeader $upn -PrependSubject $prepend -ExceptIfSubjectOrBodyContainsWords $prepend

	$username -split ' ' | ForEach {Add-DistributionGroupMember -Identity $name -Member $_}
	
}

function func3 {
	#Adds entered user into entered groups
	$username = "***"
	$distro = "***"
	$username = read-host -prompt "Enter Username"
	$upn = $username+"@"+$domain
	$distro = read-host -prompt "Enter in groups separated by spaces"

	if ($username -eq "***") {
	exit
	}
	if ($distro -eq "***") {
	exit
	}

	$distro -split ' ' | ForEach {Add-DistributionGroupMember -Identity $_ -Member $upn}
		
	}

function func4 {
	#Set calendar permissions
	$user = "***"
	$user = read-host -prompt "Enter email address (do not include @domain.com"
	$upn=$user+"@"+$domain

	if ($user -eq "***") {
	exit
	}

	Set-MailboxFolderPermission -Identity ${upn}:\calendar -User Default -AccessRights Author

	Set-CalendarProcessing -Identity $upn -AddOrganizerToSubject $true -DeleteComments $false -DeleteSubject $false
}

function func5 {
	#Adds entered users into entered group
	$username = "***"
	$distro = "***"
	$username = read-host -prompt "Enter Usernames seperated by spaces"
	$distro = read-host -prompt "Enter in group name"

	if ($username -eq "***") {
	exit
	}
	if ($distro -eq "***") {
	exit
	}

	$username -split ' ' | ForEach {Add-DistributionGroupMember -Identity $distro -Member $_}
		
}

function func6 {
	$firstname = read-host -prompt "Enter First Name"
	$lastname = read-host -prompt "Enter Last Name"
	$firstname = $firstname.substring(0,1).toupper()+$firstname.substring(1).tolower()    
	$lastname = $lastname.substring(0,1).toupper()+$lastname.substring(1).tolower()
	$username = $firstname.substring(0,1)+$lastname
	$username = $username.tolower()

	$forward = read-host -prompt "Ented address to forward to without the domain"
	$forward = $forward+ "@"+$domain

	#Set fullname, username, password, and upn
	$Name=$Firstname+$Lastname
	$rand = get-random -minimum 1000 -maximum 9999
	$password = $firstname.substring(0,1).toupper()+$lastname.substring(0,3).tolower()+$rand
	$accountpassword = convertto-securestring $password -asplaintext -force
	$upn = $username+ "@"+$domain

	#Display entered information
	Write-host -foregroundcolor yellow -backgroundcolor red "Please verify following information"
	Write-host -foregroundcolor yellow -backgroundcolor red "First Name:" $firstname
	Write-host -foregroundcolor yellow -backgroundcolor red "Last Name:" $lastname
	Write-host -foregroundcolor yellow -backgroundcolor red "Full Name:" $Name
	Write-host -foregroundcolor yellow -backgroundcolor red "Username:" $username
	Write-host -foregroundcolor yellow -backgroundcolor red "Email Address:" $upn
	Write-host -foregroundcolor yellow -backgroundcolor red "School:" $school
	Write-host -foregroundcolor yellow -backgroundcolor red "User Drive Location:" $homedir
	write-host -foregroundcolor yellow -backgroundcolor red "Password:" $password
	write-host -foregroundcolor yellow -backgroundcolor red "Secure Password:"$accountpassword
	write-host -foregroundcolor yellow -backgroundcolor red "Forward Email:"$forward

	#Prompt to continue
	$title = "Confirm Data"

	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
		"Deletes all the files in the folder."

	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
		"Retains all the files in the folder."

	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

	if ($result -eq "1") {
	exit
	} else {
	write-host "Creating Accounts"
	}

	New-MailUser -Name $name -MicrosoftOnlineServicesID $upn -Password $accountpassword

	#Check to see if user is available in msol
	do {
	Write-host "Sleeping for 5 seconds"
	Start-Sleep -s 5
	Write-host "Waiting for MSOL to become ready"
	Get-Msoluser -userprincipalname $upn 
	$msolready=read-host -prompt "Was there an error?  Please enter Y or N"
	$msolready=$msolready.toupper()
	} until ($msolready -eq "N")

	set-msoluser -userprincipalname $upn -usagelocation "US" -passwordneverexpire $true
	Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses ""

	Set-Mailbox -Identity $username -DeliverToMailboxAndForward $true -ForwardingSMTP $forward
}

write-host {
	"Enter number of function you wish to perform."
	"1 - Reset user password" 
	"2 - Create new group"
	"3 - Add a user to one or more groups"
	"4 - Set room mailbox permissions"
	"5 - Add users to one group"
	"6 - Create mailbox and forward to user"
}
$choice = read-host
switch ($choice)
{
	1 	{
		func1
	}
	2 	{
		func2
	}
	3 	{
		func3
	}
	4	{
		func4
	}
	5	{
		func5
	}
	6	{
		func6
	}
}
