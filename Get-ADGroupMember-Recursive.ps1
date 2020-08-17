<# This is about equivalent to using Get-AdGroupMember -Recursive but better and faster.
 When it encounters a member it does not have permissiong to, it won't crash.
 Script is from https://activedirectoryfaq.com/2019/04/recursive-list-of-group-members-in-ad/
 Moved $groupsToNotResolve into Param
 Added -OutputType "Email","Detailed","sAMAccountName","DistinguishedName" to create different outputs. 
 Email and Detailed will output to file while SAmAccountName and DistinguishedName outputs to screen.
 Comment out $membersHT.Add($member, $groupsHT.$member) in resolve-members-recursive function
 Comment out 1st resolve-members-recursive in resolve-members-recursive function 
 Added Write-Verbose lines for troubleshooting.  Set $VerbosePreference = "continue" to troubleshoot
 Added Tracking of Groups it resolved ($GroupsIn)
#> 
param(
[Parameter(Mandatory = $true)][String]$groupName,
[Parameter(Mandatory = $false)][AllowEmptyCollection()][String[]]$groupsToNotResolve,
[Parameter(Mandatory = $false)][ValidateSet("Email","Detailed","sAMAccountName","DistinguishedName")][string]$OutputType="sAMAccountName"
)
$VerbosePreference = "silentlycontinue"  # set to "continue" to troubleshoot, set to "silentlycontinue" for normal processing
if($VerbosePreference -eq "silentlycontinue"){CLS}
$groupsHT = @{} # This is our group cache 
$membersHT = @{} # These are our members 
 
function Get-Info {
 Param(
 [Parameter(Mandatory = $true)][string[]]$DNs,
 [Parameter(Mandatory=$False)][switch]$EmailOnly)
	$location = Split-Path $PSCommandPath -Parent
	$userList = @{}
	$contactlist = @{}
	$neitherlist = @()
 
	foreach ($DN in $DNs)
	{
		$DN = $DN.Trim()
		$User = Get-ADUser -LDAPFilter "(DistinguishedName=$DN)" | Select sAmAccountName, Name, UserPrincipalName, DistinguishedName, Enabled
		if ($User) {$userList.add($user.sAmAccountName,$user)}
			else
		{
			$ContactName = Get-ADObject -LDAPFilter "(DistinguishedName=$DN)" | Select Name, DistinguishedName, ObjectClass
			if($ContactName.Objectclass -eq 'Contact'){$contactlist.add($ContactName.Name,$ContactName)}
			else
			{$neitherlist += $DN}
		}
	}

	$Userlist = $Userlist.Values
	$Contactlist = $contactlist.Values
	
	if($EmailOnly)
	{
		$userlist.UserPrincipalName | Sort | Out-File -FilePath $location\$GroupName-Emails.txt
		$contactlist.Name | Sort | Out-File -FilePath $location\$Groupname-Emails.txt -Append
		if($neitherlist){$neitherlist | Sort | Out-File -FilePath $location\$Groupname-NotEmails.txt}
		Write-host "$location\$GroupName-Emails.txt Created"
	}
	else
	{
		$userlist | Sort UserPrincipalName | Export-CSV -Path $location\$Groupname-Info.csv -NoTypeInformation
		if($contactlist -ne $null){$contactlist | Sort Name  | Export-CSV -Path $location\$Groupname-ContactInfo.csv -NoTypeInformation}
		if($neitherlist){$neitherlist | Sort | Out-File -FilePath $location\$Groupname-NeitherList.txt}
		Write-host "$location\$Groupname-Info.csv Created"
	}
}
 
function groupShouldNotBeResolved {     
	param($member)     
 
	#$groupsToNotResolve = @($null)
	#@( # These are CNs! Make sure that your sAMAccountNames and CNs match!         
	#"Domain Users" # Feel free to edit these!         
	#"SomeGroup")
	
	foreach($group in $groupsToNotResolve) { # We iterate through our list of groups...         
		if($member.StartsWith(("CN=" + $group + ","), "CurrentCultureIgnoreCase") -eq $true) { # ...and check if our member matches             
			$groupToNotResolveAD = Get-ADObject -Identity $member # If we find a match, we get it from AD             
			$groupsHT.Add($member, $groupToNotResolveAD) # And add it to our list of groups, so we know it next time             
			return $true # Let caller know this group should not be resolved         
		}     
	}     
	return $false # This group should be resolved! 
} 
 
function resolve-members-recursive {     
	param($members) # The input is a list of members (distinguishedNames)     
    
	foreach($member in $members) { # We look at each member / distinguishedName         
		if($membersHT.Contains($member) -eq $true) { # If the distinguishedName is already in our list of members, we skip it             
		   write-verbose "$member already added to list"
		   continue         
		}         
		elseif((groupShouldNotBeResolved $member) -eq $true) { # If the member is a group that should not be resolved....             
		#	$membersHT.Add($member, $groupsHT.$member) # We add it to our members list ## comment out since I don't excluded to show on member list      
		}         
		elseif($groupsHT.Contains($member) -eq $true) {  # If the distinguishedName is already in our group cache...
			write-verbose "$member is a duplicate group"
		#	resolve-members-recursive $groupsHT.$member # Resolve its members recursively! # comment out because it is not needed
		}         
		elseif($GroupnameDN -ne $member) { # If the distinguishedName is in neither cache, we find out what it is if it's not $groupname             
			$memberAD = Get-ADObject -Identity $member -Properties member # ... from AD!             
			if($memberAD.objectClass -eq "group") { # If it's a group...                 
				write-verbose "$member is a group. Add members to list"  
                		$script:GroupsIn += $memberAD.Name
				$groupsHT.Add($memberAD.distinguishedName, $memberAD.member) # We add it to our group cache
				resolve-members-recursive $groupsHT.$member # And resolve its members recursively             
			}             
			else { # If it's not a group, it must be a user...                 
				write-verbose "Add $member"
				$membersHT.Add($member, $memberAD) # So we add it to our members list             
			}         
		}
		else{write-verbose "$member is a duplicate group"}
	} 
	write-verbose "Exit resolve-members-recursive"
} 

$groupToResolve = Get-ADObject -LDAPFilter ("(&(objectClass=group)(objectCategory=group)(sAMAccountName=" + $groupName + "))") -Properties member 
if($groupToResolve -eq $null) {     
	Write-Host ($groupName + " could not be found in AD!")     
	return $null 
} 
else {   
	Write-host "Retrieving members from $Groupname ......"
	$GroupnameDN = (Get-ADObject -LDAPFilter "(sAMAccountName=$groupname)").DistinguishedName
	[string[]]$GroupsIn = $null
	resolve-members-recursive $groupToResolve.member
	# Return $membersHT
	if($GroupsIn){Write-Host "Members were also retrieved from the following groups:"
	$GroupsIn;Write-Host "-----------------------------------------------------"}
	if($VerbosePreference -eq "continue"){break}
	$Members = $membersHT.Values | Select DistinguishedName, ObjectClass
	if($Members)
	{
		if($OutputType -eq "Email"){Get-Info -DN $Members.DistinguishedName -EmailOnly}
		elseif($OutputType -eq "Detailed"){Get-Info -DN $Members.DistinguishedName}
		elseif($OutputType -eq "sAmAccountName")
		{
			$sAmAccountName = ($Members.DistinguishedName | ForEach-Object{[adsi]"GC://$_"}).sAmAccountName | Sort
			$sAmAccountName
			$NotUser = @()
			foreach($m in $Members){if($m.ObjectClass -ne "user"){$NotUser += $m.DistinguishedName} }
			if($NotUser){Write-host "`nNot Users`n=========";$NotUser | Sort}
		}
		elseif($OutputType -eq "DistinguishedName")
		{
			$Members.DistinguishedName | Sort
			$NotUser = @()
			foreach($m in $Members){if($m.ObjectClass -ne "user"){$NotUser += $m.DistinguishedName} }
			if($NotUser){Write-host "`nNot Users`n=========";$NotUser | Sort}
		}
		if($groupsToNotResolve){Write-host "`nGroups excluded from recursive search`n====================";$groupsToNotResolve}
	}
	else {Write-Host "No members found in $groupName"}
} 
