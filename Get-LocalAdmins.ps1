# David Wong - 8/22/20
$location = Split-Path $PSCommandPath -Parent

function get-members{
param($Members,$Groupname)
$Groupmember = @()
$Localmember = @()
	foreach($member in $Members){
		if(($member.split('\').Length - 1) -eq 0){
		$Localmember += "$script:s\$member"
		}
		else{
			$sAMmember = $member.Split('\')[1]
			if($ResolveGroups){$ADGroupmembers = & $location\Get-ADGroupMember-Recursive.ps1 -Groupname $sAMmember}else{$ADGroupmembers = $null}
			if($ADGroupmembers -ne $null){
				$Groupmember += $ADGroupmembers}
			else {$Groupmember += $sAMmember}
		}
	}
	if($ToFile){
        if($Localmember -ne $null -or $Groupmember -ne $null){
		$Localmember | Sort  | Out-File $location\$Groupname-$script:s.log
		$Groupmember | select -unique | Sort | Out-File $location\$Groupname-$script:s.log -Append
        write-host "$location\$Groupname-$script:s.log created"
        }
	}
	else{
		$Localmember | Sort 
		$Groupmember | select -unique | Sort 
	}
}

#$Servers = Get-Content $location\Servers.txt   # get list of servers from file
$Servers = "Server1","Server2"    # get list of servers
$Servers = $null    # to get local machine. Comment out if using other methods
$ResolveGroups = $true # to resolve the groups recursively or just list groups
$ToFile = $false       # to write to file or screen.

$LocalGroup = "Administrators"
if($Servers -eq $null){$Servers = $env:COMPUTERNAME}

foreach($S in $Servers){
	if($Servers -eq $env:COMPUTERNAME){$Locals = net localgroup $LocalGroup}
	else{
		$Locals = Invoke-Command -scriptblock {net localgroup $using:LocalGroup} -ComputerName $S
	}
	$Locals = $Locals[6..($Locals.Count-3)]
	if(-Not($ToFile)){Write-Host "`n$Localgroup on $s"}
	Get-members $Locals $Localgroup
}	