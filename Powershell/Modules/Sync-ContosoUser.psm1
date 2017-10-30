<#
.Synopsis
   Syncs users to Azure and Google Apps
.DESCRIPTION
   Syncs users to Azure
   Adds users to shadow groups
   Syncs users to Google Apps
   Sets signatures for users
   Assigns Google Apps app to Azure user
.EXAMPLE
   Sync-ContosoUser
#>
function Sync-ContosoUser
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Skips HR email
        [Parameter(Mandatory=$false)]
        [Switch]$SkipHREmail

     )
    
    Begin
    {
        #Import Modules
        Import-Module ADSync
        Import-Module AADGraph
        #Env variables
        $desktop=[Environment]::GetFolderPath("Desktop")
        $pdflog = $desktop+"\User-Automation\usercreation\html\"
		$gam="\\server01\installs\gam-stu\gam.exe"
        
        #Set file locations
        $temppass=$desktop+"\User-Automation\usercreation\temppass.csv"
        $azure=$desktop+"\User-Automation\usercreation\usernames.csv"
        $sigfile=$desktop+"\User-Automation\usercreation\sigs.csv"
        
        #Setup Azure connection
        Load-ActiveDirectoryAuthenticationLibrary
    }
    Process
    {
        Write-Verbose "Checking if Azure AD Sync is running..."

        While(Get-ADSyncConnectorRunStatus){
            Start-Sleep -Seconds 10
        }

        Write-Verbose "Initializing Azure AD Delta Sync..."
        Start-ADSyncSyncCycle -PolicyType Delta

        Start-Sleep -Seconds 10

        While(Get-ADSyncConnectorRunStatus){
            Start-Sleep -Seconds 10
        }
        Write-Verbose " | Complete!"

        Write-Verbose "Adding users to groups based on OU"
		&"C:\Users\admin\Documents\WindowsPowerShell\Scripts\Auto-Groups.ps1"
        
		Write-Verbose "Syncing users to G Suite"
		&"C:\Program Files\Google Apps Directory Sync\sync-cmd.exe" -a -c C:\Users\admin\Documents\google-apps


        if ($SkipHREmail -eq $True) {
            Write-Verbose "Skipping HR email"
        } else {
            Write-Verbose "Sending usernames and passwords to HR"
            $pass= import-csv $temppass | select GivenName,SurName,username,password,title| ConvertTo-Html -Fragment
            Get-ChildItem $pdflog | Where {-not $_.PSIsContainer} | foreach {$_.fullname} | Send-MailMessage -To "HR@contoso.com" -Cc "IT@contoso.com" -SmtpServer "smtp-relay.gmail.com" "New users" -Port "587" -Body "$pass" -From "UserCreation@contoso.com" -BodyAsHtml
        }
        
        Write-verbose "Setting Signatures"
        $gam csv $sigfile gam user ~email signature ~sig

        Write-Verbose "Adding Google Apps role to Azure AD"
        $global:authenticationResult = Get-AuthenticationResult
        Import-CSV $azure | %{$user = get-aaduser -Id $_.userprincipalname;Set-AppRoleAssignmentsGoogle -userId $user.Objectid}

        Write-Verbose "Resetting AAD Password sync"
        Update-AADConnector
                      
    }
    End
    {
        remove-item $temppass
        remove-item $azure
        remove-item $sigfile
        Add-Content -path $temppass -value "GivenName,SurName,username,password,school,title"
        Add-Content -path $azure -value "userprincipalname"
        Add-Content -path $sigfile -value "email,sig"
        Get-ChildItem $pdflog | Remove-Item
    }
}