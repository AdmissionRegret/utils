Import-Module AADGraph
Load-ActiveDirectoryAuthenticationLibrary
$global:authenticationResult = Get-AuthenticationResult

Set-Location C:\students
$assignedstudents = import-csv google-assigned-students.csv
$allstudents= get-aduser -LDAPFilter "(!userAccountControl:1.2.840.113556.1.4.803:=2)" -SearchBase "OU=Students,DC=contoso,DC=com" -Properties mail
foreach ($student in $allstudents) {
	if ($assignedstudents.mail -match $student.mail) 
	{
		Continue;
	}
    
    $user = get-aaduser -Id $student.mail;Set-AppRoleAssignmentsGoogle -userId $user.Objectid
}

$allstudents | export-csv google-assigned-students.csv