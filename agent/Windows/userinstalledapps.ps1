
#################################
#           Functions           #
#################################

# Function to retrieve user installed applications
function Get-Apps 
{
    param([string] $SID)

    $regpaths = @("Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "Registry::HKEY_USERS\$SID\Software\", "Registry::HKEY_USERS\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*")
	$regApplications = Get-ItemProperty -Path $regpaths -ErrorAction Ignore | Select *

    return $regApplications
}

# Function to retrieve local installed applications
function Get-Local-Apps 
{
    $regLocalPaths = @("Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")
	$regLocalApplications = Get-ItemProperty -Path $regLocalPaths -ErrorAction Ignore | Select *

    return $regLocalApplications
}

# Function to retrieve user SID
function Get-Sid
{
	param([string]$pth, [array]$profileList)
	foreach($sid in $profileList) {
		if($pth -eq $sid.ProfileImagePath) {
			return $sid.PSChildName
		}
	}

	return ""
}

$xml = ""

$profileListPath =  @("Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*")
$profileList = Get-ItemProperty -Path $profileListPath -ErrorAction Ignore | Select ProfileImagePath, PSChildName

$pathUsers = "C:\Users"

$tmp = Get-ChildItem -Path $pathUsers | Select "Name"
[System.Collections.ArrayList]$users = $tmp.Name

while ($users -contains "Public") {
	$users.Remove("Public")
}

foreach ($user in $users) {
    $path = $pathUsers+"\"+$user
	$username = $user
	$SID = Get-Sid $path $profileList
    $appnames = @()

    $regApplications = Get-Apps $SID

	if ($regApplications -ne $null) {
		$regApplications | ForEach-Object {
			if ($_ -ne $null) {
				$appname = If ($_.DisplayName) {$_.DisplayName} Else {$_.PSChildName}
                $appname = $appname -replace "\.[^.]*$", ""

                $publisher = ""
                $version = ""

                if($_.Publisher -ne $null) {
                    $publisher = $_.Publisher
                }

                if($_.DisplayVersion -ne $null) {
                    $version = $_.DisplayVersion
                }
                
                # reduce duplicate entries by checking if same app already listed
                $comparator = "*$appname*"
                if (-Not (@($appnames) -like $comparator)) {
                    $xml += "<USERINSTALLEDAPPS>`n"
                    $xml += "<USERNAME>" + $username + "</USERNAME>`n"
                    $xml += "<APPNAME>" + $appname + "</APPNAME>`n"
                    $xml += "<PUBLISHER>" + $publisher + "</PUBLISHER>`n"
                    $xml += "<VERSION>" + $version + "</VERSION>`n"
				    $xml += "</USERINSTALLEDAPPS>`n"
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

        $publisher = ""
        $version = ""

        if($_.Publisher -ne $null) {
            $publisher = $_.Publisher
        }

        if($_.DisplayVersion -ne $null) {
            $version = $_.DisplayVersion
        }

		# reduce duplicate entries by checking if this app is already listed
		$comparator = "*$appname*"
        if (-Not (@($appnames) -like $comparator)) {
            $xml += "<USERINSTALLEDAPPS>`n"	
            $xml += "<USERNAME>" + $username + "</USERNAME>`n"
            $xml += "<APPNAME>" + $appname + "</APPNAME>`n"
            $xml += "<PUBLISHER>" + $publisher + "</PUBLISHER>`n"
            $xml += "<VERSION>" + $version + "</VERSION>`n"  
		    $xml += "</USERINSTALLEDAPPS>`n"
        }
        $appnames += $appname
    } 
}

# just in case
if($xml -eq '') {
	$xml = "<USERINSTALLEDAPPS/>"
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::WriteLine($xml)
