<#
.Synopsis
   Enables user accounts given username
.DESCRIPTION
   Enables user account, moves to department ou, and moves all disabled users files to user share
.EXAMPLE
   Enable-ContosoUser -username dwoods -department "NY"
#>
function Enable-ContosoUser
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Username help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $username,

        # Department help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Alias('School')]
        [ValidateSet("NY", "LA", "NO")]
        $Department

    )

    Begin
    {
        $desktop=[Environment]::GetFolderPath("Desktop")
        $root="\\10.1.10.15\users\"
        $disableroot="\\10.1.10.15\h$\disabled-users\"

		#Import Modules
        Import-Module AADGraph
                
        #Setup Azure connection
        Load-ActiveDirectoryAuthenticationLibrary
    }
    Process
    {

        $log = $desktop + "\User-Automation\EnabledUsers\" + $user + ".txt"
        $source=$root+$username
        $disabledest=$disableroot+$username
        $upn=$username+"@contoso.com"

        #check department and set ou, address, department name, and phone
	    Switch ($Department)
	    {
		    NY 	
			    { 
			    $ou="OU=NY,OU=Users,DC=Contoso,DC=com"

                }
		    LA
			    {
			    $ou="OU=LA,OU=Users,DC=Contoso,DC=com"

                }
		    NO
			    { 
			    $ou="OU=NO,OU=Users,DC=Contoso,DC=com"

                }
	    }
        
        
        write-verbose "Enabling accounts for $username"
        
        Enable-ADAccount -Identity $username
        Get-ADUser $username | Move-ADObject -TargetPath $ou
        
        #Set password to first 4 of username + random 4 numbers with first letter capitalized
	    Write-Verbose "$SurName Password is not set, setting..."
		$rand = get-random -minimum 1000 -maximum 9999
		$password = $Username.substring(0,1).toupper()+$Username.substring(1,3).tolower()+$rand
        
        Set-ADAccountPassword -Identity $username -NewPassword (ConvertTo-SecureString $password -AsPlainText -Force) -reset 
		Set-ADUser -Identity $username -ChangePasswordAtNextLogon $true

        Write-Verbose "Adding $username to staff group"
	    Add-ADGroupMember -Identity S-1-5-21-1498526603-1254341818-4058654820-1489 -Member $username

                
        Write-Verbose "Copy user files from disabled root"
        
        robocopy /e /NFL /NDL /R:0 /Move $disabledest\ $source

        $ACL = Get-Acl "$root\template"
	    $ACL.SetAccessRuleProtection($true, $true)
	    $ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$NTDomain\$UserName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow")))
	    Set-Acl "$source" $ACL

        icacls.exe $source /setowner "contoso\$username" /T
		
		#Set default printer and print out new hire welcome sheet.
		$printer = Get-WmiObject -Query "Select * From Win32_Printer Where Name = 'Printer1'"
		$printer.SetDefaultPrinter()

		$htmllog = $desktop+"\User-Automation\usercreation\html\$username.html"
		$pdflog = $desktop+"\User-Automation\usercreation\html\$username.pdf"
		rm $htmllog -ErrorAction SilentlyContinue
		rm $pdflog -ErrorAction SilentlyContinue
		Add-Content $htmllog "`<html`>"
		Add-Content $htmllog "`<p align=center style='text-align:center'`>`<b style='mso-bidi-font-weight: normal'`>`<span style='font-size:30.0pt;line-height:107%'`>Welcome to New Orleans College Prep.`</span`>`</b`>`</p`>"
		Add-Content $htmllog "`<p`>&nbsp;`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your logon name is: `<strong`>$username`</strong`>`</span`>`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your Email address is: `<strong`>$upn`</strong`>`</span`>`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your computer and email password is: `<strong`>$password`</strong`>`</span`>`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>You can access your email from any computer by going to mail.google.com`</span`>`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>`</span`>`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Please be aware onsite Internet traffic is monitored and some sites may be blocked due to school policies.`</span`>`</p`>"
		Add-Content $htmllog "`<p`>&nbsp;`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>To log into your laptop first click on `<strong`>Other User`</strong`>, then enter your logon name and password from above.`</span`>`</p`>"
		Add-Content $htmllog "`<p`>&nbsp;`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>For ITSupport: email request to `<strong`>help@contoso.com`</strong`>`</span`>`</p`>"
		Add-Content $htmllog "`<p`>&nbsp;`</p`>"
		Add-Content $htmllog "`<p`>&nbsp;`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Kind regards,`</span`>`</p`>"
		Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your Helpdesk`</span`>`</p`>"
		Add-Content $htmllog "`</html`>"

		& 'C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe' $htmllog $pdflog

		start-process -filepath $pdflog -verb print -passthru | %{sleep 10; $_} | kill
        
    }
    End
    {
		Remove-Item $htmllog
		Remove-Item $pdflog
		Sync-ContosoUser -SkipHREmail
		$global:authenticationResult = Get-AuthenticationResult
		$user = get-aaduser -Id $upn;Set-AppRoleAssignmentsGoogle -userId $user.Objectid
    }
}

