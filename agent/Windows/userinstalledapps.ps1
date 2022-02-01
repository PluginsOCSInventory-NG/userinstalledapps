
function Get-Apps {
    param([string] $SID)

    $regpaths = @("Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "Registry::HKEY_USERS\$SID\Software\", "Registry::HKEY_USERS\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*")
	$regApplications = Get-ItemProperty -Path $regpaths -ErrorAction Ignore | Select *

    return $regApplications
}

function Get-Local-Apps {

    $regLocalPaths = @("Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")
	$regLocalApplications = Get-ItemProperty -Path $regLocalPaths -ErrorAction Ignore | Select *

    return $regLocalApplications
}


function Get-Users {
    $users = gwmi win32_UserAccount | Select Name, Caption, SID, Disabled | Where {$_.Disabled -eq $False}
    return $users
}



$xml = ''

$users = Get-Users

foreach ($user in $users) {
	$username = $user.Caption
	$SID = $user.SID
    $appnames = @()

    $regApplications = Get-Apps $SID

	if ($regApplications -ne $null) {
		$regApplications | ForEach-Object {
			if ($_ -ne $null) {
				$appname = If ($_.DisplayName) {$_.DisplayName} Else {$_.PSChildName}
                $appname = $appname -replace "\.[^.]*$", ""
                
                # reduce duplicate entries by checking if same app already listed
                $comparator = "*$appname*"
                if (-Not (@($appnames) -like $comparator)) {
                    $xml += "<WINUSERAPP>`n"
						
					    $xml += "<USERNAME>" + $username + "</USERNAME>`n"
					    $xml += "<APPNAME>" + $appname + "</APPNAME>`n"
					     
				    $xml += "</WINUSERAPP>`n"
                }
                $appnames += $appname
 
			}
		}
	}
}

# apps from hklm can be associated with user if we look at the uninstall string
$regLocalApplications = Get-Local-Apps
$regLocalApplications | ForEach-Object {
    if ($_.UninstallString -match "C:\\Users\\([a-zA-Z0-9_\-\s]*)\\.*") {
        $username = $Matches[1]
        $appname = $_.DisplayName

		# get user and domain from our $users
        $user = $users | Where {$_.Name -eq $username}
		# reduce duplicate entries by checking if this app is already listed
		$comparator = "*$appname*"
        if (-Not (@($appnames) -like $comparator)) {
            $xml += "<USERINSTALLEDAPPS>`n"
						
		        $xml += "<USERNAME>" + $user.Caption + "</USERNAME>`n"
		        $xml += "<APPNAME>" + $appname + "</APPNAME>`n"
					     
		    $xml += "</USERINSTALLEDAPPS>`n"
        }
        $appnames += $appname
    } 
}

# just in case
if($xml -eq $null) {
	$xml = "<USERINSTALLEDAPPS/>"
}

Write-Output $xml
