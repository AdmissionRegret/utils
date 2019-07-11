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
   Sync-User
#>
function Sync-User
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # SkipHREmail help description
        [Parameter(Mandatory=$false)]
        [Switch]$SkipHREmail

     )
    
    Begin
    {
		$Elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
		if ( -not $Elevated ) {
			throw "This module requires elevation."
		}
        
		#Import Modules
        Import-Module ADSync
        
        #Env variables
        $desktop=[Environment]::GetFolderPath("Desktop")
        $pdflog = $desktop+"\User-Automation\usercreation\html\"
        
        #Set file locations
        $temppass=$desktop+"\User-Automation\usercreation\temppass.csv"
        $azure=$desktop+"\User-Automation\usercreation\usernames.csv"
        $sigfile=$desktop+"\User-Automation\usercreation\sigs.csv"
        
        #Setup Azure connection
        $AzureUser = "cml@contoso.org"
		$AzurePass = cat C:\Users\admin\Documents\WindowsPowerShell\securestring.txt | convertto-securestring
		$AzureCred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $AzureUser, $AzurePass
		Connect-AzureAD -Credential $AzureCred
		$sp = Get-AzureADServicePrincipal -Filter "displayName eq 'G Suite'"
		$appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq 'Default Organization' }
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

        #Run scripts to add users to groups based on OU and to sync google apps
        &"C:\Users\admin\Documents\WindowsPowerShell\Scripts\Auto-Groups.ps1"
        &"C:\Program Files\Google Cloud Directory Sync\sync-cmd.exe" -a -c C:\Users\admin\Documents\google-apps


        if ($SkipHREmail -eq $True) {
            Write-Verbose "Skipping HR email"
        } else {
            Write-Verbose "Sending usernames and passwords to HR"
            $pass= import-csv $temppass | select GivenName,SurName,username,password,title| ConvertTo-Html -Fragment
            Get-ChildItem $pdflog | Where {-not $_.PSIsContainer} | foreach {$_.fullname} | Send-MailMessage -To "hr@contoso.org" -Cc "cml@contoso.org" -SmtpServer "smtp-relay.gmail.com" "New users" -Port "587" -Body "$pass" -From "UserCreation@contoso.org" -BodyAsHtml
        }
        

        #set signature for all users
        \\server\Installs\Gam\gam.exe csv $sigfile gam user ~email signature ~sig

        #Add gogle apps role to azure ad
		Import-CSV $azure | %{$user = Get-AzureADUser -ObjectId $_.userprincipalname;New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id}

        #Reset AAD Password sync
        Update-AADConnector
		
		#Add teacher to teacher groups
		\\server\Installs\Gam\gam.exe csv $sigfile gam update group classroom_teachers@contoso.org add member user ~email
                      
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