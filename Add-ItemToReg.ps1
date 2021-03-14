# Add an Item to a registry string.
# ie. Add-ItemToReg -Key HKCU:\PathTest -Name Path -Item c:\path3                HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3
# Optional switch -AppendSemi will add a semicolon at end of the string. 
# ie. Add-ItemToReg -Key HKCU:\PathTest -Name Path -Item c:\path3 -AppendSemi    HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3;

function Add-ItemToReg
{
param(
[Parameter(Mandatory = $true)][String]$Key,
[Parameter(Mandatory = $true)][String]$Name,
[Parameter(Mandatory = $true)][String]$Item,
[Parameter(Mandatory = $false)][Switch]$AppendSemi
)

	$CheckItem = @(); $AddItem = ''
	if($AppendSemi){$Semi = ";"}
	$GetNameInfo = Get-ItemProperty $Key -Name $Name -EA 0
	if($GetNameInfo)
	{$CheckItem = (($GetNameInfo.$Name).Split(';') -ne '').Trim() | Sort -Unique}
	else
	{New-Item -Path $Key -Force -EA 0 | Out-Null}
	if($CheckItem -notcontains $Item)
	{
		if($CheckItem){$AddItem = ($CheckItem -join ';') + ";$Item"+$Semi}
		else{$AddItem = $Item + $Semi}
	
		try{
			New-ItemProperty -Path $Key -Name $Name -PropertyType String -Value $AddItem -Force -EA Stop | Out-Null
			Write-Host "$Key\$Name set to $AddItem"
		}
	
		catch{
			Write-Host "Failed to append $Item to $Key\$Name"
		}
	}
	else
	{Write-Host "$Item already in $Key\$Name"}
}
