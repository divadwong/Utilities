[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True, Position=1, HelpMessage='Enter userid or leave blank to proces users from Userlist-Info.txt')]
	[AllowEmptyCollection()]
	[array]$users,
	# Change InputType that will be processed
	[Parameter(Mandatory = $false)][ValidateSet("SAmAccountName","DistinguishedName","UserPrincipalName","Name")][string]$InputType="SAmAccountName"
)

function ProcessList{
Param($InputType)
	$userList = @{}
	$userobj = @()
	
	foreach ($user in $users)
	{
		# Trim spaces in front and end
		$user=$user.Trim()
		# check to see if Input is valid. Add to HT if valid,
		$Filter = "(" + $Inputtype + "=" + $user + ")"
		$userobj = Get-ADUser -LDAPFilter $Filter -Properties givenName, sn, Enabled, AccountExpires, Mail, department, streetAddress, telephoneNumber, title, lastLogonTimestamp, lastLogon, userAccountControl, employeeNumber, whenCreated, pwdLastSet, passwordNeverExpires, ProfilePath |
		Select-Object DistinguishedName, Enabled, SamAccountName, Name, givenName, sn, Mail, employeeNumber, whenCreated, department, title, streetAddress, telephoneNumber, @{N='AccountExpires'; E={[DateTime]::FromFileTime($_.AccountExpires).ToString('g')}}, @{N='lastLogonTimestamp'; E={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('s')}}, @{N='lastLogon'; E={[DateTime]::FromFileTime($_.lastLogon).ToString('g')}}, @{N='pwdLastSet'; E={[DateTime]::FromFileTime($_.pwdLastSet).ToString('s')}}, passwordNeverExpires, ProfilePath
		if ($userobj) {$userList.add($user,$userobj) | Out-Null}
			else
		{
			Write-host "$user not found and logged to $location\results\GetInfo_BadID.csv"
			$Date = (get-date -format filedatetime)[0..12] -join ''; $Date +"`t"+ $Inputtype +"`t"+ $user | Out-File $location\results\GetInfo_BadID.csv -Append
		}
	}
	return $userlist.values
}

# Called from GetUserInfo.cmd and FindUser.cmd
$location = Split-Path $PSCommandPath -Parent
# If No Input process the Userlist-Info.txt
if (-Not($users))
{
	# If Userlist-Info.txt doesn't exist, quit
	if (-Not(Test-Path $location\Userlist-Info.txt)){write-host $location\Userlist-Info.txt missing;Exit}	
	# gets your list of users
	$users = Get-Content $location\Userlist-Info.txt
}

if($InputType -ne "SAmAccountName"){write-host "InputType set to $InputType"}
write-host "Generating user info report ....."
# Process users 
$ProcessedUsers = ProcessList $InputType
if ($ProcessedUsers)
{
    if($ProcessedUsers.Syncroot.count -gt 0)  # If used multiple wildcards, the array will be split into syncroot. Need to combined them.
    {
      $CombineThem = @()
      For ($i=0; $i -le $ProcessedUsers.Syncroot.Count-1; $i++){$CombineThem += $ProcessedUsers.Syncroot[$i]}
      $ProcessedUsers = $CombineThem
    }
	$ProcessedUsers = $ProcessedUsers | Sort SAmAccountName
	$Count = $ProcessedUsers.SamAccountName.Count
	write-host $Count users
	$Output = Read-Host -Prompt 'Output to Screen or File? (S, F) Screen is default'
	if ($Output -eq "F")
	{
		if (($Count) -gt 1)
		{	
			$ProcessedUsers | Export-CSV -Path $location\results\UserInfo.csv -NoTypeInformation
			write-host $location\results\User-Info.csv created
		}
		else
		{		
			$ProcessedUsers | Export-CSV -Path $location\results\$Users.csv -NoTypeInformation
			write-host $location\results\$Users.csv created
		}
	}	
	else
	{$ProcessedUsers}
}
else
{write-host "No Users processed"}