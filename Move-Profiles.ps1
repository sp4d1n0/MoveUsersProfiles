# This command has 2 non-mandatory parameters
# Parameter 1: User-Account -> f.e "user1"
# Parameter 2: New profiles path -> f.e "D:\USER_PROFILES" (default value is "D:\users")
#
# Execution examples
#
# PS> .\MOVE_PROFILES.ps1 (moves all user profiles to the new location D:\users\<user>"
# PS> .\MOVE_PROFILES.ps1 user1 (moves user1 profile to the new location D:\users\<user>"
# PS> .\MOVE_PROFILES.ps1 user1 G:\folder (moves user1 profile to the new location G:\FOLDER\<user>"
# PS> .\MOVE_PROFILES.ps1 ALL G:\folder (moves all user profiles to the new location G:\FOLDER\<user>"
#
# Execute it as administrator when the user you want to migrate is not logged!!


Param(
  [string] $ACCOUNT = "",
  [string] $NEWPATH = ""
)

# Obtain all user profiles (excluding system profiles)
$USER_PROFILES = dir -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | ? {$_.name -match "S-1-5-21-"} 
 
# Loop to process all profiles
foreach ($USER_PROFILE in $USER_PROFILES) {

    # Obtain registry, profile path, user and profile new path
	$REGISTRY = $($($USER_PROFILE.pspath.tostring().split("::") | Select-Object -Last 1).Replace("HKEY_LOCAL_MACHINE","HKLM:"))
	$OLD_PROFILEPATH = $(Get-ItemProperty -LiteralPath $REGISTRY -name ProfileImagePath).ProfileImagePath.tostring()
	$USER=$OLD_PROFILEPATH.Split("\")[-1]
	$NEW_PROFILEPATH = "$NEWPATH\$USER"
	
    # Process all or the user passed as parameter?
	If ($ACCOUNT -eq "ALL" -or $USER -eq $ACCOUNT)
	{
		Write-Host "User:		$USER"
		Write-Host "Registry:	$REGISTRY"
		Write-Host "Old path:	$OLD_PROFILEPATH"
		Write-Host "New path:	$NEW_PROFILEPATH"
		Write-Host

        # Change the profile path in the registry
        Set-ItemProperty -LiteralPath $REGISTRY -Name ProfileImagePath -Value $NEW_PROFILEPATH
		Write-Host "- Modified Windows registry (ProfileImagePath)"
		Write-Host "- Moving folders to new location ($NEW_PROFILEPATH)..."

        # Move the profile folders to the new location
		$ROBOCOPY_COMMAND = "robocopy /e /MOVE /copyall /r:0 /mt:4 /b /nfl /xj /xjd /xjf $OLD_PROFILEPATH $NEW_PROFILEPATH > robocopy_$USER.log"
		Invoke-Expression $ROBOCOPY_COMMAND
		Write-Host "- Done!"
		Write-Host "-------------------------------"		
	}
} 
 

