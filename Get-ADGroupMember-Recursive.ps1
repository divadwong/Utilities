<# This is about equivalent to using Get-AdGroupMember -Recursive but more resilient and faster.
 Script is from https://activedirectoryfaq.com/2019/04/recursive-list-of-group-members-in-ad/
 Modified by David W. - 08/17/20
#>
param(
[Parameter(Mandatory = $true)][String]$groupName,
[Parameter(Mandatory = $false)][AllowEmptyCollection()][String[]]$groupsToNotResolve=$null
)
$groupsHT = @{} # This is our group cache 
$membersHT = @{} # These are our members 
 
function groupShouldNotBeResolved {     
	param($member)     
 
	foreach($group in $groupsToNotResolve) { # We iterate through our list of groups...         
		if($member.StartsWith(("CN=" + $group + ","), "CurrentCultureIgnoreCase") -eq $true) { # ...and check if our member matches             
			return $true # Let caller know this group should not be resolved         
		}     
	}     
	return $false 
} 
 
function resolve-members-recursive {     
	param($members) # The input is a list of members (distinguishedNames)     
    
	foreach($member in $members) { # We look at each member / distinguishedName         
		if($membersHT.Contains($member) -eq $true) { # If the distinguishedName is already in our list of members, we skip it             
			continue         
		}         
		elseif($groupsToNotResolve -ne $null -and (groupShouldNotBeResolved $member) -eq $true){  # if there are groupstoNotResolve and member is on list,
		#	$membersHT.Add($member, $groupsHT.$member) 					  # We add it to our members list?
			continue                                                                           # move onto next member, otherwise keep processing.
		}         
		elseif($groupsHT.Contains($member) -eq $true) {  # If the distinguishedName is already in our group cache...
			continue
		}         
		elseif($groupToResolve.DistinguishedName -ne $member)  { # If the distinguishedName is in neither cache, we find out what it is...         
			$memberAD = Get-ADObject -Identity $member -Properties member # ... from AD!             
			if($memberAD.objectClass -eq "group") { # If it's a group...                 
				$groupsHT.Add($memberAD.distinguishedName, $memberAD.member) # We add it to our group cache
				resolve-members-recursive $groupsHT.$member # And resolve its members recursively             
			}             
			else { # If it's not a group, it must be an object...                 
				$membersHT.Add($member, $memberAD) # So we add it to our members list             
			}         
		}   
	} 
} 

$groupToResolve = Get-ADObject -LDAPFilter ("(&(objectClass=group)(objectCategory=group)(sAMAccountName=" + $groupName + "))") -Properties member 
if($groupToResolve -eq $null) {     
	#Write-Host ($groupName + " could not be found in AD!")     
	return $null 
} 
else {     
	resolve-members-recursive $groupToResolve.member
	$Members = $membersHT.Values | Select DistinguishedName
	if($Members)
	{
		$sAMAccountName = ($Members.DistinguishedName | ForEach-Object{[adsi]"GC://$_"}).sAMAccountName | Sort
		Return $sAMAccountName
	}
	else {return $null}
} 
