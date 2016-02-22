Function GOOGCREATE {

#define parameters
param (
	[string]$firstname,
	[string]$lastname,
	[string]$dob,
	[string]$class,
	[string]$school
)

#convert 4 digit graduation year into 2 digit
$class = $class -replace "^.."

#check to see if graduation year is not equal to 2 and if so quit
if ($class.length -ne 2) {
	echo "$firstname $lastname $class class error"
	return
}

#split dob into month and day variables
$split = $dob.split("/")
$month = $split[0]
$day = $split[1]

#checks to see if month is 1 digit and adds a leading 0 if so
if ($month.length -eq 1) {
	$month = "0"+$month
} 

#checks to see if day is 1 digit and adds a leading 0 if so
if ($day.length -eq 1) {
	$day = "0"+$day
} 

#removes spaces from the firstname and last name
$firstname = $firstname -replace " ", ""
$lastname = $lastname -replace " ", ""

#creates username from firstname.lastnameClassyear e.g. Cory Landry 2016 becomes Cory.Landry16
$username = $firstname+"."+$lastname+$class

#removes apostrophes from the user name and creates the email address
$username = $username -replace "'", ""
$username = $username -replace "``", ""
$email = $username+"@scholar.org"

#creates password out of scholarBirthmonthBirthday e.g. a birth date of January 12 is scholar0112
$password = "scholar"+$month+$day

#checks to see if email is already created and if so exits
if ($emails -contains $email)
	{
	write-host "User $email already exists, exiting"
	return
	}

#checks for school code and set the organization variable
Switch ($school)
{
	385001 	
		{ 
		$org="/school1"
		}
	385002	
		{ 
		$org="/school2"
		}
	385003
		{ 
		$org="/school3"
		}
}

#creates student
gam-stu create user $username firstname $firstname lastname $lastname password $password changepassword off nohash

#moves student to correct organization
gam-stu update org $org add users $username

#adds user information to log file for teachers
Add-Content -path \\10.10.10.15\Education\Shared\Technology\StudentGoogleUsers.csv -value "$firstname,$lastname,$username,$email,$password"
}
