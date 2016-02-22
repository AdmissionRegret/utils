#Env variables
$desktop=[Environment]::GetFolderPath("Desktop")
$domain="domain.org"
$root="\\10.10.10.15\users\"

$file=$desktop+"\User-Automation\names.csv"
$logfile=$desktop+"\User-Automation\usercreation\users.csv"
$passwordfile=$desktop+"\User-Automation\usercreation\pass.csv"
$temppass=$desktop+"\User-Automation\usercreation\temppass.csv"
Add-Content -path $temppass -value "username,password,school,title"

#email credentials
$secpasswd = cat \\10.10.10.15\users\clandry\desktop\scripts\usercreation\securestring.txt | convertto-securestring
$mycreds = New-Object System.Management.Automation.PSCredential ("noreply@$domain", $secpasswd)

Function USERCREATE {

	param (
		[string]$firstname,
		[string]$lastname,
		[string]$school,
		[string]$title,
		[string]$username,
		[string]$password
	 )
	 
	$firstname = $firstname.substring(0,1).toupper()+$firstname.substring(1).tolower()    
	$lastname = $lastname.substring(0,1).toupper()+$lastname.substring(1).tolower()

	#Check if user name is set, if not set and check if it is in use.
	IF($username) {            
		write-Host $lastname "Usernameis set, continuing"    
	} else {
		$username = $firstname.substring(0,1)+$lastname

		$error.clear()
		get-mailbox $username

		IF($error.count -eq "0") {            
			write-Host $username "is taken, changing"    
			$username = $firstname.substring(0,2)+$lastname	
			
			$error.clear()
			get-mailbox $username

			IF($error.count -eq "0") {            
				write-Host $username "is taken, changing"    
				$username = $firstname+"."+$lastname
			} else {
				write-Host $username "is not taken, continuing"
			}
		} else {
			write-Host $username "is not taken, continuing"
	}

		$username = $username.tolower()	
	}

	#Set fullname
	$Name=$Firstname+" "+$Lastname

	#Set password if not set
	IF($password) {            
		write-Host $lastname "Password is set, continuing"    
	} else {
		Write-Host $lastname "Password is not set, setting"
		$rand = get-random -minimum 1000 -maximum 9999
		$password = $firstname.substring(0,1).toupper()+$lastname.substring(0,3).tolower()+$rand
	}
	#Conevert password to securestring
	$accountpassword = convertto-securestring $password -asplaintext -force

	#Create upn
	$upn = $username+"@"+$domain

	#check school and set homedir/distro
	$school=$school.toupper()
	Switch ($school)
	{
		NOLA 	
			{ 
			$ou="OU=NewOrleans,OU=Users,OU=Staff,DC=CONTOSO,DC=local"
			}
		HOU
			{
			$ou="OU=Houston,OU=Users,OU=Staff,DC=CONTOSO,DC=local" 
			}	
		MANAGEMENT 
			{
			$ou="OU=NewOrleans,OU=Users,OU=Staff,DC=CONTOSO,DC=local"	
			}
		DEFAULT
			{
			exit
			}
	}

	$homedir=$root+$username

	#create user mailbox
	write-host "Creating mailbox for $username"
	New-MailUser -Name $name -FirstName $firstname -LastName $lastname -MicrosoftOnlineServicesID $upn -Password $accountpassword

	#create gapps account
	write-host "Creating google apps account for $username"
	\\10.10.10.10\installs\gam\gam.exe create user $username firstname $firstname lastname $lastname password $password

	#Create Active Directory user
	write-host "Creating AD account for $username"
	New-ADUser -SamAccountName $username -GivenName $firstname -Surname $lastname -DisplayName $name -Name $name -Path $ou -accountpassword $accountpassword -userprincipalname $upn -EmailAddress $upn -passwordneverexpires $true -enabled $true

	#Add user to staff group
	write-host "Adding $username to staff group"
	Add-ADGroupMember -Identity S-1-5-21-1474232603-1254341616-4058801820-1894 -Member $username

	#create userdrive and set permissions
	write-host "Creating userdrive for $username"
	New-Item -Name $username -ItemType Directory -Path $root | Out-Null
	$ACL = Get-Acl "$root\$UserName"
	$ACL.SetAccessRuleProtection($true, $true)
	$ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$NTDomain\$UserName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow")))
	Set-Acl "$root\$UserName" $ACL

	#Create temporary log files
	Add-Content -path $logfile -value "$firstname,$lastname,$Name,$username,$upn,$school,$homedir,$password,$accountpassword"
	Add-Content -path $passwordfile -value "$username,$password"
	Add-Content -path $temppass -value "$username,$password,$school,$title"

	#Set default printer
	$printer = Get-WmiObject -Query "Select * From Win32_Printer Where Name = 'NOLA-1-HR'"
	$printer.SetDefaultPrinter()

	#Create new user pdf and print to HR
	$htmllog = $desktop+"\User-Automation\usercreation\html\$username.html"
	$pdflog = $desktop+"\User-Automation\usercreation\html\$username.pdf"
	rm $htmllog
	rm $pdflog
	Add-Content $htmllog "`<html`>"
	Add-Content $htmllog "`<p align=center style='text-align:center'`>`<b style='mso-bidi-font-weight: normal'`>`<span style='font-size:30.0pt;line-height:107%'`>Welcome to Contoso.`</span`>`</b`>`</p`>"
	Add-Content $htmllog "`<p`>&nbsp;`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your logon name is: `<strong`>$username`</strong`>`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your Email address is: `<strong`>$upn`</strong`>`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your computer and email password is: `<strong`>$password`</strong`>`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>You can access email on your laptop from outlook as long as you have an internet connection.  You can also access your email from any computer by going to mail.office365.com`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Please be aware onsite Internet traffic is monitored and some sites may be blocked due to school policies.`</span`>`</p`>"
	Add-Content $htmllog "`<p`>&nbsp;`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>For ITSupport`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Low to Medium priority: email request to `<strong`>help@$domain`</strong`>`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Medium to High priority: call 123-456-7890.`</span`>`</p`>"
	Add-Content $htmllog "`<p`>&nbsp;`</p`>"
	Add-Content $htmllog "`<p`>&nbsp;`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Kind regards,`</span`>`</p`>"
	Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your Helpdesk`</span`>`</p`>"
	Add-Content $htmllog "`</html`>"

	& 'C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe' $htmllog $pdflog

	start-process -filepath $pdflog -verb print -passthru | %{sleep 10; $_} | kill

}

Function USERCREATE2 {

	param (
		[string]$username,
		[string]$school,
		[string]$title
	)

	IF($title) {            
		Write-Host $lastname "Title is set, continuing"    
	} else {
		Write-Host $lastname "Title is not set, setting to temp"
		$title="PLEASE UPDATE"
	}


	#Set fullname, username, password, and upn
	$upn = $username+"@"+$domain

	#Prompt for School
	$school=$school.toupper()

	#check school and set homedir/distro
	Switch ($school)
	{
		NOLA 
			{ 
			$distro="NOLA@$domain/LCCP-calendar@$domain"
			$office="New Orleans, LA"
			}
		HOU 
			{ 
			$distro="HOU@$domain/HOU-calendar@$domain"
			$office="Houston, TX"		
			}
		MANAGEMENT 
			{
			$distro="NOLA@$domain/HOU@$domain"
			$office="New Orleans, LA"
			}
	}

	#Set msol location and assign license
	write-host "Setting location and assigning license for $username"
	set-msoluser -userprincipalname $upn -usagelocation "US" -passwordneverexpires $true -office $office -department $office -title $title
	Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses ""
	set-clutter -identity $username -enable $false

	#add user to distros
	write-host "Adding $username to all"
	Add-DistributionGroupMember -Identity "all@$domain" -Member $upn

	write-host "Adding $username to school distro"
	$distro -split '/' | ForEach {Add-DistributionGroupMember -Identity $_ -Member $upn}

}

Import-Csv $file | ForEach-Object {USERCREATE -firstname $_.first -lastname $_.last -school $_.school -title $_.title -username $_.username -password $_.password}


(gc $passwordfile)[-1] > c:\tempname.csv
Import-Csv C:\tempname.csv
$csv = Import-Csv C:\tempname.csv -Header username,password

$uname=$csv.username    
$userpn = $csv.username+"@"+$domain

#Check to see if last user is available in msol
do {
	$error.clear()
	Write-host "Sleeping for 5 seconds"
	Start-Sleep -s 5
	Write-host "Waiting for MSOL to become ready"
	Get-Msoluser -userprincipalname $userpn
} until ($error.count -eq "0")

remove-item c:\tempname.csv

Import-Csv $temppass | ForEach-Object {USERCREATE2 -username $_.username -school $_.school -title $_.title}

$pass= import-csv $temppass | select username,password| ConvertTo-Html -Fragment
Send-MailMessage -To "hr@$domain" -Cc "me@$domain" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "New users" -Port "587" -Body "$pass" -From "me@$domain" -BodyAsHtml

#Prompt to continue
$title = "Send Verizon Email?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Sends email."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does not send email."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

if ($result -eq "1") {
	Write-host "Will not send email"
} else {
	$users= import-csv $file | select first,last| ConvertTo-Html -Fragment
	Send-MailMessage -To "Carrier Rep" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "New phone lines" -Port "587" -Body "Hey **NAME**,<br><br>Can we get lines added for the following?<br>$users<br><br>Thanks!" -From "me@$domain" -BodyAsHtml
}

#cleanup
rm $temppass
