function Set-Sig
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Username of the user you would like to set the signature of.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $username
    )
    Begin
    {
		$gam="\\server01\installs\gam-stu\gam.exe"
    }
	Process
    {
        $user=Get-ADUser $username -Properties *
        $address=$user.streetaddress+", "+$user.city+", "+$user.state+" "+ $user.postalcode
        $name=$user.name
        $title=$user.title
        $sname=$user.department
        $phone=$user.mobile
        $upn=$user.mail

        Switch ($user.department)
        {
	        "NY" 	
	        {
		        Write-Verbose "New York Department"
	            $logo="REPLACE WITH COMPANY/OFFICE LOGO"
            }
	        "LA"
	        {
		        Write-Verbose "Los Angles Department"
	            $logo=""
            }
	        DEFAULT
	        {
		        return
	        }
        }
        

        $sig="`"<div dir='ltr'><div><div dir='ltr'><div><div dir='ltr'><div dir='ltr'><div dir='ltr'><div><p>&nbsp;</p><table border='0'><tbody><tr><td><img src='$logo' alt='logo' height='101' /></td><td><p><strong>$name</strong>&nbsp;<br /><em>$title</em><em>, $sname</em><br /> <a href='tel:$phone' target='_blank'>$phone</a>&nbsp;|&nbsp;<a style='font-size: 12.8px;' href='mailto:$upn' target='_blank'>$upn</a><br />$address<br /><a href='http://contoso.com/' target='_blank'>contoso.com</a>&nbsp;</p></div></div></div></div></div></div></div>`""
		
        $gam user $user.mail signature $sig
    }
}