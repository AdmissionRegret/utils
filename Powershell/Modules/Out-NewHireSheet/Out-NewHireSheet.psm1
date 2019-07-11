<#
.Synopsis
    Creates New Hire welcome sheet.
.DESCRIPTION
    Creates new hire PDF in Desktop\User-Automation\usercreation\html\
    You must have wkhtmltopdf.exe in C:\Program Files\wkhtmltopdf\bin\
.EXAMPLE
   Out-NewHireSheet -username cml -password Passw0rd!
.EXAMPLE
   Out-NewHireSheet cml Passw0rd!
#>
function Out-NewHireSheet
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # The username that you want the sheet created for.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $username,

        # The password of the user that you want the sheet created for.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $password
		)

    Begin
    {
        $upn=$username+"@contoso.org"
		$desktop=[Environment]::GetFolderPath("Desktop")
    }
    Process
    {
        Write-Verbose "Printing new hire welcome sheet"
        	
		$htmllog = $desktop+"\User-Automation\usercreation\html\$username.html"
		$pdflog = $desktop+"\User-Automation\usercreation\html\$username.pdf"
        rm $htmllog -ErrorAction SilentlyContinue
        rm $pdflog -ErrorAction SilentlyContinue
        
		Add-Content $htmllog @"
<html>
  <body>
    <p align="center" style='text-align:center'>
      <b style='mso-bidi-font-weight: normal'>
        <span style='font-size:25.0pt;line-height:107%'>Welcome to Contoso.</span>
      </b>
    </p>
    <p>&nbsp;</p>
    <meta content='text/html; charset=UTF-8' http-equiv='content-type' />
    <style type='text/css'>
ol{margin:0;padding:0}table td,table
th{padding:0}.c2{color:#000000;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:13pt;font-family:&amp;#39;Times
New
Roman&amp;#39;;font-style:normal}.c4{padding-top:0pt;padding-bottom:0pt;line-height:1.0;orphans:2;widows:2;text-align:left;height:11pt}.c1{color:#000000;font-weight:700;text-decoration:none;vertical-align:baseline;font-size:13pt;font-family:&amp;#39;Times
New
Roman&amp;#39;;font-style:normal}.c6{color:#000000;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:11pt;;font-style:normal}.c0{padding-top:0pt;padding-bottom:8pt;line-height:1.0;orphans:2;widows:2;text-align:left}.c8{color:#000000;text-decoration:none;vertical-align:baseline;font-size:15pt;font-style:normal}.c5{color:#000000;text-decoration:none;vertical-align:baseline;font-size:11pt;font-style:italic}.c7{background-color:#ffffff;max-width:468pt;padding:72pt
72pt 72pt 72pt}.c3{font-weight:400;font-family:&amp;#39;Times New
Roman&amp;#39;}.title{padding-top:0pt;color:#000000;font-size:26pt;padding-bottom:3pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}.subtitle{padding-top:0pt;color:#666666;font-size:15pt;padding-bottom:16pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}li{color:#000000;font-size:13pt;}p{margin:0;color:#000000;font-size:13pt;}h1{padding-top:20pt;color:#000000;font-size:20pt;padding-bottom:6pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h2{padding-top:18pt;color:#000000;font-size:16pt;padding-bottom:6pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h3{padding-top:16pt;color:#434343;font-size:14pt;padding-bottom:4pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h4{padding-top:14pt;color:#666666;font-size:12pt;padding-bottom:4pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h5{padding-top:12pt;color:#666666;font-size:11pt;padding-bottom:4pt;;line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h6{padding-top:12pt;color:#666666;font-size:11pt;padding-bottom:4pt;;line-height:1.15;page-break-after:avoid;font-style:italic;orphans:2;widows:2;text-align:left}
</style>
    <p>
      <span class='c2'>Your logon name is: 
      <strong>$username</strong></span>
    </p>
    <p>
      <span class='c2'>Your Email address is: 
      <strong>$upn</strong></span>
    </p>
    <p>
      <span class='c2'>Your computer and email password is: 
      <strong>$password</strong></span>
    </p>
    <p>
      <span class='c2'>&nbsp;</span>
    </p>
    <p>
      <span class='c2'>You can access your email from any computer by going to
      mail.google.com</span>
    </p>
    <p>
      <span class='c2'>Please be aware onsite Internet traffic is monitored and some
      sites may be blocked due to school policies.</span>
    </p>
    <p>
      <span class='c2'>&nbsp;</span>
    </p>
    <p>
      <span class='c2'>To log into your laptop first click on 
      <strong>Other User</strong>, then enter your logon name and password from above.</span>
    </p>
    <p>
      <span class='c2'>&nbsp;</span>
    </p>
    <p>
      <span class='c2'>For IT Support: email request to 
      <strong>help@contoso.org</strong></span>
    </p>
    <p>
      <span class='c2'>&nbsp;</span>
    </p>
    <p>
      <span class='c2'>Kind regards,</span>
    </p>
    <p>
      <span class='c2'>Your Helpdesk</span>
    </p>
    <p>
      <span class='c2'>&nbsp;</span>
    </p>
    <p class='c0'>
      <span class='c1'>Security Policy</span>
    </p>
    <p class='c0'>
    <span class='c3'>As a vital part of our security system, a security card linked to your name has been issued to you. This is
    your electronic key to enter all buildings that Contoso operates.</span> 
    <span class='c3'>All staff members are expected to scan this card anytime they enter a building unless specified otherwise in
    writing by their supervisor.</span></p>
    <p class='c0'>
      <span class='c2'>If your security card is lost or stolen, you must obtain a replacement at your own expense. Lost or stolen
      cards should be reported to your school leader as soon as possible.</span>
    </p>
    <p class='c0'>
      <span class='c2'>Upon termination, employees will be required to return all security and ID badges to Human Resources as part
      of the Exit Procedure.</span>
    </p>
	<p>
      <span class='c2'>&nbsp;</span>
    </p>
    <p class='c0'>
      <span class='c1'>Laptop/Telecommunications Policy</span>
    </p>
    <p class='c0'>
      <span class='c2'>Each employee provided with a laptop by Contoso is responsible for the physical security of the laptop. All
      laptops acquired for or on behalf of Contoso are deemed to be company property. Each employee will be provided with a unique
      email address, computer login and password. The password is strictly confidential and is not to be shared with anyone. Any
      work created or communications transmitted by an employee must be conducted under that employees unique credentials</span>
    </p>
    <p class='c0'>
      <span class='c2'>Employees are responsible for the security of the device. Employees must avoid leaving their laptops
      unattended in an automobile. If they must do so temporarily, the laptop must be placed in the trunk.</span>
    </p>
    <p class='c0'>
      <span class='c2'>Laptops that will not be used for several days or longer must be locked out of sight in a secure cabinet or
      safe.</span>
    </p>
    <p class='c0'>
      <span class='c2'>No employee of Contoso should use any computers or communications systems for any
      non-school related business and no employee of Contoso should use their personal email to access Contoso networks or drives.</span>
    </p>
    <p class='c0'>
    <span class='c3'>All data in Contosos computer and communication systems</span> 
    <span class='c3'>(including, but not limited to, documents, and other electronic files, email and recorded voicemail
    messages)</span> 
    <span class='c2'>is the property of Contoso. &nbsp;Contoso may inspect and monitor such data at any time. &nbsp;Contoso may also monitor usage of
    the Internet by employees, including reviewing a list of sites accessed by an individual.</span></p>
    <p class='c0'>
      <span class='c2'>No individual should have any expectation of privacy for electronic communications or account information in
      Contosos system, including, but not limited to, documents, emails or messages marked private, which may be inaccessible to most
      users but remain available to Contoso. &nbsp;</span>
    </p>
    <p class='c4'></p>
    <p class='c0'>
      <span class='c3 c5'>Policy Violations</span>
    </p>
    <p class='c0'>
      <span class='c2'>Violation of any aspect of these policies may be grounds for disciplinary action up to and including
      termination of employment. If an employees laptop is stolen or if the device is not returned upon employment separation, the
      employee will be responsible for the cost of replacing the laptop.</span>
    </p>
    <p class='c0'>
      <span class='c2'>Please sign below to indicate receipt of the Laptop and Security Policy and to authorize the deduction of
      wages due to the theft or loss of the laptop or security card.</span>
    </p>
    <p class='c0'></p>
	<p class='c0'>
      <span class='c2'>Service Tag:___________________________________</span>
    </p>
    <p class='c0'>
      <span class='c2'>Employee Signature:____________________________</span>
    </p>
    <p class='c0'>
      <span class='c3'>Date:__________________________________________</span>
    </p>
  </body>
</html>
"@
		
        & 'C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe' $htmllog $pdflog
		$adobe = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
		$printername = 'LA-1-PrettyGirl'
		$drivername = 'Brother MFC-L2700DW series'
		$printerport = '10.1.10.29'
		$arglist = '/S /T "{0}" "{1}" "{2}" {3}' -f $pdflog, $printername, $drivername, $portname
		Start-Process $adobe -ArgumentList $arglist
    }
    End
    {
        rm $htmllog        
    }
}