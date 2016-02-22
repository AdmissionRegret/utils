'Created 5/31/2013

ON ERROR RESUME NEXT

DIM objShell, objNetwork, objDomain, objDomainString, objUserString, objUser, objSysInfo, objWMI, objComputer
SET objShell = CreateObject("WScript.Shell")
SET objNetwork = CreateObject("WScript.Network")
SET objWMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")

'Get domain
objDomainString = objNetwork.UserDomain 

'Get WinDir
WinDir = objShell.ExpandEnvironmentStrings("%WinDir%")

'Get user name
objUserString = objNetwork.UserName
SET objUser = GetObject("WinNT://" & objDomainString & "/" & objUserString)

'Get computer name
strComputer = objNetwork.ComputerName

'Get OU
SET objSysInfo=createobject("adsysteminfo")
sDN=lCASE(objSysInfo.username)
sData=split(sDN,",")
sOU=mid(sdata(1),4)

'Set computer description; will not update field if description is current or if it starts with an "!"
FOR EACH objSMBIOS IN objWMI.ExecQuery("Select * from Win32_SystemEnclosure")
	serviceTag = replace(objSMBIOS.SerialNumber, ",", ".")
	manufacturer = replace(objSMBIOS.Manufacturer, ",", ".")
NEXT
FOR EACH objComputer IN objWMI.ExecQuery("Select * from Win32_ComputerSystem")
	model = trim(replace(objComputer.Model, ",", "."))
NEXT
SET objComputer = GetObject("LDAP://" & objSysInfo.ComputerName)
newDescription = objNetwork.UserName & " (" & serviceTag & " / " & manufacturer & " / " & model & ")"
IF NOT objComputer.Description = newDescription AND NOT left(objComputer.Description,1) = "!"  THEN 
	objComputer.Description = newDescription
	objComputer.SetInfo
END IF


'Disconnect any drive mappings as needed.
objNetwork.RemoveNetworkDrive "X:", True, True
objNetwork.RemoveNetworkDrive "T:", True, True
objNetwork.RemoveNetworkDrive "W:", True, True
objNetwork.RemoveNetworkDrive "Y:", True, True
objNetwork.RemoveNetworkDrive "Z:", True, True
objNetwork.RemoveNetworkDrive "O:", True, True

wscript.sleep 300

'Map drives needed by all
objNetwork.MapNetworkDrive "X:", "\\10.10.10.10\education",True
objNetwork.MapNetworkDrive "T:", "\\10.10.10.10\technology",True


'check for group memberships and map drives
FOR EACH GroupObj IN objUser.Groups
	SELECT CASE UCASE(GroupObj.Name)
		CASE "ACCESS - HUMAN RECOURCES"
			objNetwork.MapNetworkDrive "z:", "\\10.10.10.10\HR",True
		CASE "ACCESS - OPERATIONS"
			objNetwork.MapNetworkDrive "o:", "\\10.10.10.10\Operations",True
		CASE "ACCESS - FUNDRAISING"
			objNetwork.MapNetworkDrive "w:", "\\10.10.10.10\Fundraising",True
		CASE "ACCESS - MANAGEMENT"
			objNetwork.MapNetworkDrive "w:", "\\10.10.10.10\Fundraising",True
			objNetwork.MapNetworkDrive "y:", "\\10.10.10.10\Finance",True	
			objNetwork.MapNetworkDrive "o:", "\\10.10.10.10\Operations",True			
		CASE "ACCESS - FINANCE"
			objNetwork.MapNetworkDrive "y:", "\\10.10.10.10\Finance",True	
	END SELECT
NEXT

'Install printers
SELECT CASE UCASE (objIPAddress)
	CASE "10.10.*.*"
		objNetwork.AddWindowsPrinterConnection "\\10.10.10.10\Main Office"		
	CASE "10.20.*.*"
		objNetwork.AddWindowsPrinterConnection "\\10.20.10.10\Office"
		objNetwork.AddWindowsPrinterConnection "\\10.20.10.10\Workroom"
END SELECT

wscript.quit
