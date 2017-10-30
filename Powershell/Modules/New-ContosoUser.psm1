<#
.Synopsis
   Create users for New Orleans College Prep
.DESCRIPTION
   Create AD user and sync to Google Apps / AzureAD
.EXAMPLE
   New-ContosoUser -GivenName Dan -Surname Woods -Department LA -Title "Sales Manager"
#>
function New-ContosoUser
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # The users First Name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('FirstName')]
        [Alias('First')]
        $GivenName,

        # The users Last Name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('LastName')]
        [Alias('Last')]
        $SurName,

        # THe School the user will be at
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('School')]
        [ValidateSet("NY", "LA", "NO")]
        $Department,

        # The users title
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $Title,

        # Optional: Force module to use this username
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $Username,

        # Optional: Force module to use this password
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $Password,

        # Optional: Skip HR printout sheet.
        [Parameter(Mandatory=$false)]
        [Switch]$SkipHRPrint
    )

    Begin
    {
        Write-Verbose "Setting Environment Variables"
        $desktop=[Environment]::GetFolderPath("Desktop")
        $domain="contoso.com"
        $root="\\10.1.10.15\users\"

        Write-Verbose "Setting file locations"
        $temppass=$desktop+"\User-Automation\usercreation\temppass.csv"
        $azure=$desktop+"\User-Automation\usercreation\usernames.csv"
        $sigfile=$desktop+"\User-Automation\usercreation\sigs.csv"

        Write-Verbose "Setting headers if files are empty"
        if (Get-Content $temppass){
            Write-Verbose "Header already set for temppass file"
        } else {
            Write-Verbose "Setting header for temppass file"
            Add-Content -path $temppass -value "GivenName,SurName,username,password,school,title"
        }

        if (Get-Content $azure){
            Write-Verbose "Header already set for azure file"
        } else {
            Write-Verbose "Setting header for azure file"
            Add-Content -path $azure -value "userprincipalname"
        }

        if (Get-Content $sigfile){
            Write-Verbose "Header already set for sig file"
        } else {
            Write-Verbose "Setting header for sig file"
            Add-Content -path $sigfile -value "email,sig"
        }
        

    }
    Process
    {
    	    	
	    Write-Verbose "Setting first, last, and job title to title case"
	    $TextInfo = (Get-Culture).TextInfo
	    $GivenName = $TextInfo.ToTitleCase($GivenName)
	    $SurName = $TextInfo.ToTitleCase($SurName)
	    $title = $TextInfo.ToTitleCase($title)

        Write-Verbose "Removing apostrophes from names"
        $GivenName = $GivenName -replace "'"
        $SurName =  $SurName -replace "'"
	
	    Write-Verbose "Checking if username was defined in user file"
	    IF($Username) {            
		    Write-Verbose "$SurName Username is set, continuing"
	    } else {
		    Write-Verbose "Setting username to first initial + lastname and checking if it is taken"
		    $username = $GivenName.substring(0,1)+$SurName
		    if (!(get-aduser $username -ErrorAction SilentlyContinue))
		    {
			    Write-Verbose "$username is not taken, continuing..."
		    } else {
			    Write-Verbose "Setting username to first 2 initials + lastname and checking if it is taken"
			    Write-Verbose "$username is taken, changing"    
			    $username = $GivenName.substring(0,2)+$SurName	
			    if (!(get-aduser $username -ErrorAction SilentlyContinue))
			    {
				    Write-Verbose "$username is not taken, continuing..."
			    } else {
				    Write-Verbose "$username is still taken, changing..." 
                    Write-Verbose "Setting username to firstname.lastname"
				    $username = $GivenName+"."+$SurName
			        if (!(get-aduser $username -ErrorAction SilentlyContinue))
                    {
                        Write-Verbose "$username is not taken, continuing..."
                    } else {
                        Write-Verbose "$username is taken, quitting"
                        return
                        
                    }
                }
		    }
	    }
	
	    Write-Verbose "Setting username to lower case and removing apostrophes"
	    $username=$username.tolower() -replace "'",""
	
	    Write-Verbose "Setting fullname"
	    $Name=$GivenName+" "+$SurName

	    Write-Verbose "Checking if password was defined in user file"
	    IF($password) {            
		    Write-Verbose "$SurName Password is set, continuing"    
	    } else {
		    
			Write-Verbose "$SurName Password is not set, setting..."
			$rand = get-random -minimum 1000 -maximum 9999
			$password = $GivenName.substring(0,1).toupper()+$SurName.substring(0,3).tolower()+$rand
		    
	    }

	    Write-Verbose "Setting user principal name"
	    $upn = $username+ "@contoso.com"

	    Write-Verbose "Setting department variable to uppercase"
	    $Department=$Department.toupper()

	    Write-Verbose "Checking department and setting details"
	    Switch ($Department)
	    {
		    NY 	
			    {
                IF($title -like "*intern*") {
                    $ou="REPLACE WITH INTERN OU"
			    } ELSE {    
                    $ou="REPLACE WITH DEPARTMENT OU"
			    }
                $address="REPLACE WITH OFFICE ADDRESS"
			    $phone="REPLACE WITH PHONE NUMBER"
			    $sname="REPLACE WITH OFFICE/COMPANY NAME"
			    $logo="REPLACE WITH OFFICE/COMPANY LOGO"
                }
		    LA
			    {
                IF($title -like "*intern*") {
                    $ou="OU=Interns,OU=LA,OU=Users,DC=contoso,DC=com"
			    } ELSE {    
                    $ou="OU=LA,OU=Users,DC=contoso,DC=local"
			    }
			    $address="48 Meadowbrook Mall Road, Los Angeles, CA 90017"
			    $phone="310-870-5380" 
			    $sname="Contoso Ltd."
			    $logo=""
                }
	    }
	
	    Write-Verbose "Setting home directory"
	    $homedir=$root+$username

	    Write-Verbose "Creating AD account for $username"
	    New-ADUser `
        -SamAccountName $username `
        -GivenName $GivenName `
        -Surname $SurName `
        -DisplayName $name `
        -Name $name `
        -Path $ou `
        -accountpassword (convertto-securestring $password -asplaintext -force) `
        -userprincipalname $upn `
        -EmailAddress $upn `
        -passwordneverexpires $false `
        -enabled $true `
        -Title $title `
        -Department $sname
		
		Set-ADUser -Identity $username -ChangePasswordAtNextLogon $true

	    Write-Verbose "Adding $username to staff group"
	    Add-ADGroupMember -Identity S-1-5-21-1498526603-1254341818-4058654820-1489 -Member $username
	

        Write-Verbose "Creating userdrive for $username"
	    New-Item -Name $username -ItemType Directory -Path $root | Out-Null
	    $ACL = Get-Acl "$root\$UserName"
	    $ACL.SetAccessRuleProtection($true, $true)
	    $ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
	    $ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$NTDomain\$UserName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow")))
	    Set-Acl "$root\$UserName" $ACL
        
        IF ($SkipHRPrint -eq $True) {
            Write-Verbose "Skipping new hire welcome sheet"
        } ELSE {
            Write-Verbose "Printing new hire welcome sheet"
		    $printer = Get-WmiObject -Query "Select * From Win32_Printer Where Name = 'LCCP-1-PrettyGirl'"
		    $printer.SetDefaultPrinter()

		    $htmllog = $desktop+"\User-Automation\usercreation\html\$username.html"
		    $pdflog = $desktop+"\User-Automation\usercreation\html\$username.pdf"
		    rm $htmllog -ErrorAction SilentlyContinue
		    rm $pdflog -ErrorAction SilentlyContinue
		    Add-Content $htmllog "`<html`>"
		    Add-Content $htmllog "`<p align=center style='text-align:center'`>`<b style='mso-bidi-font-weight: normal'`>`<span style='font-size:30.0pt;line-height:107%'`>Welcome to Contoso Ltd.`</span`>`</b`>`</p`>"
		    Add-Content $htmllog "`<p`>&nbsp;`</p`>"
		    Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your logon name is: `<strong`>$username`</strong`>`</span`>`</p`>"
		    Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your Email address is: `<strong`>$upn`</strong`>`</span`>`</p`>"
		    Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Your computer and email password is: `<strong`>$password`</strong`>`</span`>`</p`>"
		    Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>You can access your email from any computer by going to mail.google.com`</span`>`</p`>"
		    Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>`</span`>`</p`>"
		    Add-Content $htmllog "`<p`>`<span style='font-size:20.0pt;line-height:107%'`>Please be aware onsite Internet traffic is monitored and some sites may be blocked due to policies.`</span`>`</p`>"
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

	    

	    Write-Verbose "Setting signature"
	    $sig="`"<div dir='ltr'><div><div dir='ltr'><div><div dir='ltr'><div dir='ltr'><div dir='ltr'><div><p>&nbsp;</p><table border='0'><tbody><tr><td><img src='$logo' alt='logo' height='101' /></td><td><p><strong>$name</strong>&nbsp;<br /><em>$title</em><em>, $sname</em><br /> <a href='tel:$phone' target='_blank'>$phone</a>&nbsp;|&nbsp;<a style='font-size: 12.8px;' href='mailto:$upn' target='_blank'>$upn</a><br />$address<br /><a href='http://contoso.com/' target='_blank'>contoso.com</a>&nbsp;</p></div></div></div></div></div></div></div>`""
	
	
	    Write-Verbose "Adding content to csv files"
	    Add-Content -path $temppass -value "$GivenName,$SurName,$username,$password,$Department,$title"
	    Add-Content -path $azure -value "$upn"
	    Add-Content -path $sigfile -value "$upn,$sig"

    }
    End
    {
        #Remove-Item $htmllog
        Remove-Item $pdflog
    }
}