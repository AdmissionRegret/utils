Set-Location E:\installs\gam-stu

$oldgroups = import-csv groups.csv
$groups=.\gam.exe print groups name
foreach ($group in $groups) {
	if($group.substring(0, $group.IndexOf(',')) -eq "Email")
    {
		Continue;
    }
	if ($oldgroups.email -match $group.substring(0, $group.IndexOf(','))) 
	{
		Continue;
	}
	.\gam.exe update group $group.substring(0, $group.IndexOf(',')) who_can_view_membership all_in_domain_can_view
}
$groups > groups.csv