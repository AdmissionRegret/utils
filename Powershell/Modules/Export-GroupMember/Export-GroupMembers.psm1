
<#
.Synopsis
   Export all members of all O365 groups
.EXAMPLE
   Export-GroupMembers -OutputFile DistMembers.csv
#>
function Export-GroupMembers
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        #The CSV Output file that is created
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $OutputFile
    )

    Begin
    {
        Import-Module MSOnline
        $O365Cred = Get-Credential
        $O365Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365Cred -Authentication Basic -AllowRedirection
        Import-PSSession $O365Session
        Connect-MsolService –Credential $O365Cred

        $arrDLMembers = @{} 
    }
    Process
    {
        Write-Verbose "Preparing Output file with headers"
        Out-File -FilePath $OutputFile -InputObject "Distribution Group DisplayName,Distribution Group Email,Member DisplayName, Member Email, Member Type" -Encoding UTF8  
  
        Write-Verbose "Getting all Distribution Groups from Office 365"
        $objDistributionGroups = Get-DistributionGroup -ResultSize Unlimited  
  
        Write-Verbose "Iterating through all groups"
        Foreach ($objDistributionGroup in $objDistributionGroups)  
        {      
     
            Write-Verbose "Processing $($objDistributionGroup.DisplayName)..."  
    
            $objDGMembers = Get-DistributionGroupMember -Identity $($objDistributionGroup.PrimarySmtpAddress)  
      
            Write-Verbose "Found $($objDGMembers.Count) members..."  
      
            Write-Verbose "Iterating through each member" 
            Foreach ($objMember in $objDGMembers)  
            {  
                Out-File -FilePath $OutputFile -InputObject "$($objDistributionGroup.identity), $($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType)" -Encoding UTF8 -append  
                Write-Verbose "`t$($objDistributionGroup.DisplayName), $($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType)" 
            }  
        }  
    }
}


