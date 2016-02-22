Local $upn = @username&"@contoso.org"
Local $password = InputBox("Password", "Enter Password")

Run("C:\Program Files (x86)\Microsoft Office\Office15\OUTLOOK.EXE")

WinWait ("Welcome to Microsoft Outlook 2013")
Sleep(100)
ControlClick("Welcome to Microsoft Outlook 2013", "", "[CLASS:Button; INSTANCE:2]")

WinWait ("Microsoft Outlook Account Setup")
ControlClick("Microsoft Outlook Account Setup", "", "[CLASS:Button; INSTANCE:4]")

WinWait ("Add Account")
ControlSetText("Add Account", "", "[CLASS:RichEdit20WPT; INSTANCE:2]", $upn)
ControlSetText("Add Account", "", "[CLASS:RichEdit20WPT; INSTANCE:3]", $password)
ControlSetText("Add Account", "", "[CLASS:RichEdit20WPT; INSTANCE:4]", $password)
ControlClick("Add Account", "", "[CLASS:Button; INSTANCE:6]")

Do
   $Finish = ControlGetHandle("Add Account", "Finish", 1)
   Sleep(100)
Until $Finish <> ""

ControlClick("Add Account", "", "[CLASS:Button; INSTANCE:9]")

;WinActivate("First things first.")
;Send("!U")
;Sleep(500)
;Send("!A")

WinWait("Inbox - ")

Sleep(15000)

WinClose("Inbox - ")

Sleep(5000)

Run("C:\Program Files (x86)\Microsoft Office\Office15\OUTLOOK.EXE")

WinWait ("Windows Security")
Sleep(500)
ControlSetText("Windows Security", "", "[CLASS:Edit; INSTANCE:1]", $upn)
ControlClick("Windows Security", "", "[CLASS:Edit; INSTANCE:2]")
Send($password)
Send("{Down}")
Send("{Space}")
Sleep(500)
ControlClick("Windows Security", "", "[CLASS:Button; INSTANCE:2]")

Exit
