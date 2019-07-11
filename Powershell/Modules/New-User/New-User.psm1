<#
.Synopsis
   Create users
.DESCRIPTION
   Create AD user and sync to Google Apps / AzureAD
   If no details are specified the script will pull details from $Desktop\User-Automation\names.csv
.EXAMPLE
   New-User -GivenName Cory -Surname Micheal -Department LA -Title "Network Administrator"
#>
function New-User
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # The users First Name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('FirstName')]
        [Alias('First')]
        $GivenName,

        # The users Last Name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('LastName')]
        [Alias('Last')]
        $SurName,

        # The School the user will be at
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('School')]
        [ValidateSet("LA", "TX")]
        $Department,

        # The users title
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $Title,

        # Optional: Skip HR printout sheet.
        [Parameter(Mandatory=$false)]
        [Switch]$SkipHRPrint
    )

    Begin
    {
		$Elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
		if ( -not $Elevated ) {
			throw "This module requires elevation."
		}
		
        Write-Verbose "Importing needed modules"
        Import-Module ActiveDirectory

        Write-Verbose "Setting Environment Variables"
        $desktop=[Environment]::GetFolderPath("Desktop")
        $domain="contoso.org"
        $root="\\10.1.10.15\users\"
        $TextInfo = (Get-Culture).TextInfo

        Write-Verbose "Setting file locations"
        $temppass=$desktop+"\User-Automation\usercreation\temppass.csv"
        $azure=$desktop+"\User-Automation\usercreation\usernames.csv"
        $sigfile=$desktop+"\User-Automation\usercreation\sigs.csv"

        Write-Verbose "Connecting to Helpdesk MySQL Server"
        [system.reflection.assembly]::LoadWithPartialName("MySql.Data")
        $sqlcn = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
        $sqlcn.ConnectionString = "SERVER=10.1.10.10;DATABASE=supportpal;UID=usercreation;PWD=password;SslMode=none"
        $sqlcn.Open()
        $sqlcm = New-Object -TypeName MySql.Data.MySqlClient.MySqlCommand

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
        function mainProcess
        {   
            
            Write-verbose "Checking if required variables are set"
            
            Write-Verbose "Checking if SurName is set"
	        IF($SurName) {            
		        Write-Verbose "$SurName SurName is set, setting to title case and removing apostrophes"
                $SurName = $TextInfo.ToTitleCase($SurName)
                $SurName =  $SurName -replace "'"    
	        } else {
		        Write-Verbose "$SurName SurName is not set, exiting"
		        return
	        }
	        
            Write-Verbose "Checking if GivenName is set"
	        IF($GivenName) {            
		        Write-Verbose "$SurName GivenName is set, setting to title case and removing apostrophes"
                $GivenName = $TextInfo.ToTitleCase($GivenName)
                $GivenName = $GivenName -replace "'"
	        } else {
		        Write-Verbose "$SurName GivenName is not set, exiting"
		        return
	        }

            Write-Verbose "Checking if title is set"
	        IF($title) {            
		        Write-Verbose "$SurName Title is set, setting to title case"
                $title = $TextInfo.ToTitleCase($title)    
	        } else {
		        Write-Verbose "$SurName Title is not set, exiting"
		        return
	        }
            
            Write-Verbose "Checking if department is set"
	        IF($department) {            
		        Write-Verbose "$SurName Department is set, setting to uppercase"
    	        $Department = $Department.toupper()    
	        } else {
		        Write-Verbose "$SurName Department is not set, exiting"
		        return
	        }
            	
	        Write-Verbose "Setting username to first initial + lastname and checking if it is taken"
	        $username = $GivenName.substring(0,1)+$SurName
	        if (!(get-aduser $username -ErrorAction SilentlyContinue))
	        {
		        Write-Verbose "$username is not taken, continuing..."
	        } else {
		        Write-Verbose "$username is taken, changing"  
                Write-Verbose "Setting username to first 2 initials + lastname and checking if it is taken"
		        $username = $GivenName.substring(0,2)+$SurName	
		        if (!(get-aduser $username -ErrorAction SilentlyContinue))
		        {
			        Write-Verbose "$username is not taken, continuing..."
		        } else {
			        Write-Verbose "$username is taken, changing..." 
                    Write-Verbose "Setting username to firstname.lastname"
			        $username = $GivenName+"."+$SurName
		            if (!(get-aduser $username -ErrorAction SilentlyContinue))
                    {
                        Write-Verbose "$username is not taken, continuing..."
                    } else {
                        Write-Verbose "$username is still taken, quitting"
                        return
                    }
                } 
		    }
	
	        Write-Verbose "Setting username to lower case and removing apostrophes"
	        $username=$username.tolower() -replace "'",""
	
	        Write-Verbose "Setting fullname"
	        $Name=$GivenName+" "+$SurName

	        Write-Verbose "Checking if clean team member"
	        IF(($title -like "*clean team*") -OR ($title -like "*custodian*")) {
	            Write-Verbose "Clean team staff member, setting password..."
	            $password="Passw0rd!"
	        } else {
	            Write-Verbose "$SurName Password is not set, setting..."
	            $rand = get-random -minimum 1000 -maximum 9999
	            $password = $GivenName.substring(0,1).toupper()+$GivenName.substring(1,1).tolower()+$SurName.substring(0,2).tolower()+$rand
	        }

	        Write-Verbose "Setting user principal name"
	        $upn = $username + $domain

	        Write-Verbose "Checking department and setting details"
	        Switch ($Department)
	        {
		        LA 	
			        {
                    IF($title -like "*intern*") {
                        $ou="OU=Interns/External,OU=LA,OU=Users,OU=Staff,DC=contoso,DC=local"
			        } ELSE {    
                        $ou="OU=LA,OU=Users,OU=Staff,DC=contoso,DC=local"
			        }
                    $street=""
					$zip=""
			        $phone="123-456-7890"
			        $sname="New Orleans"
					$state="LA"
			        $address=$street+", "+$sname+", "$state+" "+$zip
					$logo=""
			        $orgid="1"
                    }
		        TX
			        {
                    IF($title -like "*intern*") {
                        $ou="OU=Interns/External,OU=TX,OU=Users,OU=Staff,DC=contoso,DC=local"
			        } ELSE {    
                        $ou="OU=TX,OU=Users,OU=Staff,DC=contoso,DC=local"
			        }
			       	$street=""
					$zip=""
			        $phone="123-456-7890"
			        $sname="Houston"
					$state="TX"
					$address=$street+", "+$sname+", "$state+" "+$zip
			        $logo=""
			        $orgid="6"
                    }
		        DEFAULT
			        {
			        exit
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
            -passwordneverexpires $true `
            -enabled $true `
            -Title $title `
            -Department $sname `
			-StreetAddress $street `
			-PostalCode $zip `
			-City $sname `
			-State $state
			

	        Write-Verbose "Adding $username to staff group"
	        Add-ADGroupMember -Identity S-1-5-21-1474232603 -Members $username
	
	        IF(($title -like "*clean team*") -OR ($title -like "*custodian*")) {
			        Write-Verbose "Clean team staff member, adding to Access-CleanTeam, skipping printout, and skipping home drive creation"
			        Add-ADGroupMember -Identity S-1-5-21-1474232603 -Members $username
		    } ELSE {
                Write-Verbose "Creating userdrive for $username"
	            New-Item -Name $username -ItemType Directory -Path $root | Out-Null
	            $ACL = Get-Acl "$root\$UserName"
	            $ACL.SetAccessRuleProtection($true, $true)
	            $ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
	            $ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$NTDomain\$UserName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow")))
	            Set-Acl "$root\$UserName" $ACL
            
                if ($SkipHRPrint -eq $True) {
                    Write-Verbose "Skipping new hire welcome sheet"
                } else {
                    Write-Verbose "Printing new hire welcome sheet"
		            Out-NewHireSheet -username $username -password $password
                }
            }

	    
            IF (!$orgid) 
            {
                Write-Verbose "Org ID not set, skipping ticket system creation"
            } ELSE {
                Write-Verbose "Adding user to ticket system"
                $sqlquery = "INSERT INTO user (firstname, lastname, email, organisation_id, organisation_access_level) VALUES ( '$GivenName' , '$SurName' , '$upn' , '$orgid' , '1')"
                $sqlcm.Connection = $sqlcn
                $sqlcm.CommandText = $sqlquery
                $sqlcm.ExecuteNonQuery()
	        }
	        Write-Verbose "Setting signature"
	        $sig=""
	
	        Write-Verbose "Adding content to csv files"
	        Add-Content -path $temppass -value "$GivenName,$SurName,$username,$password,$Department,$title"
	        Add-Content -path $azure -value "$upn"
	        Add-Content -path $sigfile -value "$upn,$sig"
        }

        IF($SurName) {            
		    Write-Verbose "SurName is set, continuing"
            mainProcess
	    } else {
		    Write-Verbose "SurName is not set, setting to csv file"
            $names=Import-csv $Desktop+"\User-Automation\names.csv"
            Foreach ($name in $names) {
                $GivenName=$name.first
				$SurName=$name.last
				$Department=$name.school
				$Title=$name.title
				Write-Verbose "Creating account using: $GivenName $SurName $Department $Title"
				mainProcess
				Start-Sleep -seconds 5
			}
		}

    }
    End
    {
    }
}