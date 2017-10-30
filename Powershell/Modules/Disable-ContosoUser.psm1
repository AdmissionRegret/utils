<#
.Synopsis
   Disable user accounts given username
.DESCRIPTION
   Disables user account, moves to disabled ou, and moves all users files to disabled root
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Disable-ContosoUser
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
        $desktop=[Environment]::GetFolderPath("Desktop")
        $root="\\10.1.10.15\users\"
        $disableroot="\\10.1.10.15\h$\disabled-users\"
		$gam="\\server01\installs\gam-stu\gam.exe"
    }
    Process
    {

        function mainProcess
        {            
            $log = $desktop + "\User-Automation\DisabledUsers\" + $user + ".txt"
            $source=$root+$user
            $disabledest=$disableroot+$user
            $upn=$user+"@contoso.com"
        
        
            write-verbose "Disabling accounts for $user"
        
            Disable-ADAccount -Identity $user
            Get-ADUser $user | Move-ADObject -TargetPath 'OU=InactiveAccounts,OU=Users,DC=contoso,DC=com'
            Set-ADUser -Identity $user -Description (Get-Date -format MM/dd/yyyy) -clear proxyaddresses

            Write-Verbose "Removing calendar events for $user"

            $gam calendar $upn wipe

            Write-Verbose "Removing $user from groups"
            $adUser = Get-ADUser $user -Properties memberOf

            $groups = $aduser.memberOf |ForEach-Object {
                Get-ADGroup $_
            } 

            Out-File $log -Append -InputObject $aduser.memberOf -Encoding utf8

            $groups | ForEach-Object {Remove-ADGroupMember -Identity $_ -Members $aduser -Confirm:$false}
            
            Write-Verbose "Transfer Google Drive files"

            $gam create datatransfer $upn gdrive userfiles@contoso.com

            Write-Verbose "Copy user files to disabled root"
        
            icacls.exe $source /setowner "contoso\domain admins" /T

            robocopy /e /NFL /NDL /R:0 /Move $source\ $disabledest

            $sqlquery = "UPDATE user SET organisation_id='7' WHERE email='$upn'"
            $sqlcm.Connection = $sqlcn
            $sqlcm.CommandText = $sqlquery
            $sqlcm.ExecuteNonQuery()
        }
        
        IF($username) {            
		    Write-Verbose "Username is set, continuing"  
            $user=$username  
            mainProcess
	    } else {
		    Write-Verbose "Username is not set, setting to csv file"
            $username=Import-csv "C:\Users\admin\Desktop\User-Automation\disable.csv"
            Foreach ($user in $username.username) {
                mainProcess
            }
		}
    }
    End
    {
    Sync-ContosoUser -SkipHREmail
    }
}

