$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#Prompt to continue
$title = "Connect to exchange?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Connects to exchange."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does not connect to exchange."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

if ($result -eq "1") {
	exit
} else {
	Import-Module MSOnline
	$username = "!!!ADMIN EMAIL!!!"
	$password = cat $scriptPath\securestring.txt | convertto-securestring
	$O365Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
	$O365Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365Cred -Authentication Basic -AllowRedirection
	Import-PSSession $O365Session
	Connect-MsolService –Credential $O365Cred
}
