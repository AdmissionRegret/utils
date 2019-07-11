<#
.Synopsis
   Disable user accounts given username
.DESCRIPTION
   Disables user account, moves to disabled ou, and moves all users files to disabled root.
   If no username is specified the script will pull usernames from $Desktop\User-Automation\disable.csv
.EXAMPLE
   Disable-User -username cml
.EXAMPLE
   Disable-User
#>
function Disable-User
{
	[CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Username help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $username
    )

    Begin
    {
		$Elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
		if ( -not $Elevated ) {
			throw "This module requires elevation."
		}
        $desktop=[Environment]::GetFolderPath("Desktop")
		$root="\\10.1.10.15\h$\users\"
        $disableroot="\\10.1.10.15\h$\disabled-users\"
		$filters = @('$recycle.bin','*.lnk','default.rdp','thumbs.db','desktop.ini','~$*','*.tmp','itunes')
		
        #connect to mysql server
        [system.reflection.assembly]::LoadWithPartialName("MySql.Data")
        $sqlcn = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
        $sqlcn.ConnectionString = "SERVER=10.1.10.10;DATABASE=support;UID=usercreation;PWD=password;SslMode=none"
        $sqlcn.Open()
        $sqlcm = New-Object -TypeName MySql.Data.MySqlClient.MySqlCommand
    }
    Process
    {

        function mainProcess
        {
			Write-Verbose "Getting users details"
			$upn=(get-aduser $username -Properties mail).mail
			$name=(get-aduser $username).name			
		
			IF ($upn -eq $null) {
				throw "User does not exist in AD"
			}
			
			$log = $desktop + "\User-Automation\DisabledUsers\" + $username + ".txt"
            $source=$root+$username
            $disabledest=$disableroot+$username
			$newuser=$username+"-suspended"
			$newupn=$newuser+"@contoso.org"
			
			Write-Verbose "Removing $username from AD groups"
            $adUser = Get-ADUser $username -Properties memberOf

            $groups = $aduser.memberOf |ForEach-Object {
                Get-ADGroup $_
            }
			
            write-verbose "Disabling accounts for $username"
        
            Disable-ADAccount -Identity $username
            Get-ADUser $username | Move-ADObject -TargetPath 'OU=InactiveAccounts,OU=Users,OU=Staff,DC=contoso,DC=local'
            Set-ADUser -Identity $username -EmailAddress $newupn -Description (Get-Date -format MM/dd/yyyy) -clear proxyaddresses -replace @{samaccountname=$newuser}
						
			Disable-Slack -upn $upn
			
			Write-Verbose "Removing $username from email groups"
			\\server\installs\gam\gam.exe user $upn delete groups
			
            Out-File $log -Append -InputObject $aduser.memberOf -Encoding utf8

            $groups | ForEach-Object {Remove-ADGroupMember -Identity $_ -Members $aduser -Confirm:$false}
            
            Write-Verbose "Transfer Google Drive files"

            \\server\installs\gam\gam.exe create datatransfer $upn gdrive userfiles@contoso.org

            Write-Verbose "Taking ownership of user files"
			
            takeown /f $source /r /d y
			icacls.exe $source /reset /T
			icacls.exe $source /inheritance:r /grant:r "contoso\domain admins:F" /grant:r "administrators:F" /grant:r "SYSTEM:F" /T
			
			Write-Verbose "Removing files matching filter"
			foreach ($filter in $filters) {
				Write-Verbose "Removing files matching $filter"
				Get-ChildItem $source -Force -Recurse -Filter $filter | rm -recurse -force
			}
			
			Write-Verbose "Deleting empty directorys"
			get-childitem $source -recurse |
				Where-Object {$_.GetType() -match "DirectoryInfo"} |
				Where-Object {$_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0} |
				rm -force
			
			Write-Verbose "Moving files to disabled destination"
			Move-item $source -destination $disabledest
			
			Write-Verbose "Setting user organation to disabled in helpdesk system"
            $sqlquery = "UPDATE user SET organisation_id='7' WHERE email='$upn'"
            $sqlcm.Connection = $sqlcn
            $sqlcm.CommandText = $sqlquery
            $sqlcm.ExecuteNonQuery()
        }
        
        IF($username) {            
		    Write-Verbose "Username is set, continuing"    
            mainProcess
	    } else {
		    Write-Verbose "Username is not set, getting usernames from csv file"
            $users=Import-csv $Desktop + "\User-Automation\disable.csv"
            Foreach ($user in $users) {
				$username=$user.username
                mainProcess
            }
		}
    }
    End
    {
		Write-Verbose "Calling sync script"
		Sync-User -SkipHREmail
		$disabledusers = \\server\installs\gam-stu\gam.exe print users  query "orgUnitPath=/Staff/Users/InactiveAccounts" aliases
		$disabledcsv = $disabledusers | convertfrom-csv | where aliases.0 -ne $null | select aliases.0
		$disabledcsv | %{\\server\installs\gam\gam.exe delete alias $_."aliases.0"}
    }
}