function Enable-GoogleSSO
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        #Username you want to enable GoogleSSO for
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $username
    )

    Begin
    {
        Write-Verbose "Setting up AzureAD Connection"
        $AzureUser = "cml@contoso.org"
		$AzurePass = cat C:\Users\admin\Documents\WindowsPowerShell\securestring.txt | convertto-securestring
		$AzureCred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $AzureUser, $AzurePass
		Connect-AzureAD -Credential $AzureCred
		$sp = Get-AzureADServicePrincipal -Filter "displayName eq 'G Suite'"
		$appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq 'Default Organization' }
    }
    Process
    {
        $upn = (Get-ADUser $username -properties mail).mail
        $user = Get-AzureADUser -ObjectId $upn
		New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id
    }
    End
    {
    }
}