# David Wong - 8/22/20
param(
[Parameter(Mandatory = $true)][AllowEmptyCollection()][String[]]$Servers=$env:COMPUTERNAME,
[Parameter(Mandatory = $false)]$ResolveGroups=$true, # to resolve the groups recursively or just list groups
[Parameter(Mandatory = $false)]$ToFile=$true   # to write to file or screen.
)

$location = Split-Path $PSCommandPath -Parent
#$Servers = Get-Content $location\Servers.txt   # get list of servers from file
#$Servers = "Server1","Server2"    # get list of servers

$LocalGroup = "Administrators"
if(!($Servers)){$Servers = $env:COMPUTERNAME}

function get-members{
param($Members,$Groupname)
$Groupmember = @()
$Localmember = @()
	foreach($member in $Members){
		if(($member.split('\').Length - 1) -eq 0){
		$Localmember += "$script:Server\$member"
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
		$Localmember | Sort  | Out-File $location\$Groupname-$script:Server.log
		$Groupmember | select -unique | Sort | Out-File $location\$Groupname-$script:Server.log -Append
        write-host "$location\$Groupname-$script:Server.log created"
        }
	}
	else{
		$Localmember | Sort 
		$Groupmember | select -unique | Sort 
	}
}

foreach($Server in $Servers){
	if($Servers -eq $env:COMPUTERNAME){$Locals = net localgroup $LocalGroup}
	else{
		$Locals = Invoke-Command -scriptblock {net localgroup $using:LocalGroup} -ComputerName $Server
	}
	$Locals = $Locals[6..($Locals.Count-3)]
	if(-Not($ToFile)){Write-Host "`n$Localgroup on $Server"}
	Get-members $Locals $Localgroup
}	
