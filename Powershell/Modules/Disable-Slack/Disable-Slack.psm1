<#
.Synopsis
   Disable slack account given upn
.EXAMPLE
   Disable-Slack -upn cml@contoso.org
#>
function Disable-Slack
{
	[CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # User Principal Name for the user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $upn
    )

    Begin
    {
		#slack info
		$slacktoken="set this to your api token" #token generated under OAuth & Permissions after creating app at https://api.slack.com/apps
		$legacytoken="legacy token here" #token generated at https://api.slack.com/custom-integrations/legacy-tokens
		$slackemail="https://slack.com/api/users.lookupByEmail"
		$slackinactive="https://slack.com/api/users.admin.setInactive"

    }
    Process
    {
		Write-Verbose "Getting user Slack details"
        $slackjson=invoke-webrequest "$slackemail`?token=$slacktoken&email=$upn"
		$slackuser=convertfrom-json $slackjson
		if ($slackuser.ok -eq "true") {
			$slackid=$slackuser.user.id
		} else {
			write-verbose "Slack error"
			write-verbose $slackuser.error
		}
		
		
		IF (!($slackid -eq $null)) {
			invoke-webrequest "$slackinactive`?token=$legacytoken&user=$slackid"
		}
	}
}