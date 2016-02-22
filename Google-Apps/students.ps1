#import functions and set gam alias
. ./googcreate-func.ps1
set-alias gam-stu "\\10.10.10.10\installs\gam-stu\gam.exe"

#set file locations and variables
$powerheader = "\\10.10.10.10\configs\google\Power.csv"
$powerNoHeader = "\\10.10.10.10\configs\google\powerschool.csv"
$GoogleTemp = "\\10.10.10.10\configs\google\GoogleTemp.csv"
$emails=@()

#get a list of users and add to array $emails
gam-stu print users > $GoogleTemp
import-csv $GoogleTemp |  %{$emails += $_.primaryEmail}

#create file with header from powerschool.csv
Clear-Content $powerheader
Add-Content $powerheader "First,Last,DOB,Grade,ClassOf,School"
Get-Content $powerNoHeader | Add-Content $powerheader

#run googcreate function to create users and move them to the correct organization
Import-Csv $powerheader | ForEach-Object {GOOGCREATE -firstname $_.first -lastname $_.last -dob $_.DOB -class $_.ClassOf -school $_.School}

#remove temporary files
rm $GoogleTemp
rm $powerheader
