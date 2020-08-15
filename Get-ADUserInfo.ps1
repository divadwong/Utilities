[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True, Position=1, HelpMessage='Enter userid or leave blank to proces users from Userlist-Info.txt')]
	[AllowEmptyCollection()]
	[array]$users,
	# Change InputType that will be processed
	[Parameter(Mandatory = $false)][ValidateSet("SAmAccountName","DistinguishedName","UserPrincipalName")][string]$InputType="SAmAccountName"
)

function ProcessList{
Param($InputType)
	$userList = @{}
	$userobj = @()
	
	Write-Host "InputType set to $InputType"
	foreach ($user in $users)
	{
		# Trim spaces in front and end
		$user=$user.Trim()
		# check to see if Input is valid. Add to HT if valid,
		$Filter = "(" + $Inputtype + "=" + $user + ")"
		$userobj = Get-ADUser -LDAPFilter $Filter -Properties givenName, sn, Enabled, AccountExpires, Mail, department, streetAddress, telephoneNumber, title, lastLogonTimestamp, lastLogon, userAccountControl, employeeNumber, whenCreated, pwdLastSet, passwordNeverExpires |
		Select-Object DistinguishedName, Enabled, SamAccountName, Name, givenName, sn, Mail, employeeNumber, whenCreated, department, title, streetAddress, telephoneNumber, @{N='AccountExpires'; E={[DateTime]::FromFileTime($_.AccountExpires).ToString('g')}}, @{N='lastLogonTimestamp'; E={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('s')}}, @{N='lastLogon'; E={[DateTime]::FromFileTime($_.lastLogon).ToString('g')}}, @{N='pwdLastSet'; E={[DateTime]::FromFileTime($_.pwdLastSet).ToString('s')}}, passwordNeverExpires | Sort-Object SamAccountName
		if ($userobj -ne $null) {$userList.add($user,$userobj) | Out-Null}
			else
		{write-host $user "is invalid"}
	}
	return $userlist.values
}

# Called from GetUserInfo.cmd
$location = Split-Path $PSCommandPath -Parent
# If No Input process the Userlist-Info.txt
if (-Not($users))
{
	# If Userlist-Info.txt doesn't exist, quit
	if (-Not(Test-Path $location\Userlist-Info.txt)){write-host $location\Userlist-Info.txt missing;Exit}	
	# gets your list of users
	$users = Get-Content $location\Userlist-Info.txt
}

write-host "Generating user info report ....."
# Process users 
$ProcessededUsers = ProcessList $InputType
if ($ProcessededUsers)
{
	$ProcessededUsers = $ProcessededUsers | Sort SAmAccountName
	write-host @($ProcessededUsers).count users
	$Output = Read-Host -Prompt 'Output to Screen or File? (S, F) Screen is default'
	if ($Output -eq "F")
	{
		if (($ProcessededUsers.count) -gt 1)
		{	
			$ProcessededUsers | Export-CSV -Path $location\UserInfo.csv -NoTypeInformation
			write-host $location\results\User-Info.csv created
		}
		else
		{		
			$ProcessededUsers | Export-CSV -Path $location\$Users.csv -NoTypeInformation
			write-host $location\results\$Users.csv created
		}
	}	
	else
	{$ProcessededUsers}
}
else
{write-host "No Users processed"}
