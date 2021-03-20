# Add an Item to a registry string.
# ie. Add-ItemToListInReg -Key HKCU:\PathTest -Name Path -Item c:\path3                HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3
# Optional switch -AppendSemi will add a semicolon at end of the string. 
# ie. Add-ItemToListInReg -Key HKCU:\PathTest -Name Path -Item c:\path3 -AppendSemi    HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3;

function Add-ItemToListInReg
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
	{
		$Prev = "was " + $GetNameInfo.$Name
		$CheckItem = (($GetNameInfo.$Name).Split(';') -ne '').Trim() | Sort -Unique # Remove duplicates, spaces and double semicolons from list
	}
	else
	{   # Create Registry Key if it does not exist
		if(!(Test-Path $Key)){New-Item -Path $Key -Force -EA 0 | Out-Null ; $Prev = "did not exist and key was created"}
		else{$Prev = "did not exist"}
	}                             
	if($CheckItem -notcontains $Item)
	{   # Append Item to end of string. Also add semicolon to end if -AppendSemi parameter used.
		if($CheckItem){$AddItem = ($CheckItem -join ';') + ";$Item"+$Semi}        # Add to existing list 
		else{$AddItem = $Item+$Semi}                                              # Add to empty list
	
		try{
			New-ItemProperty -Path $Key -Name $Name -PropertyType String -Value $AddItem -Force -EA Stop | Out-Null
			Write-Host "$Key\$Name previously $Prev"
			Write-Host "$Key\$Name set to $AddItem"
		}
	
		catch{
			Write-Host "Failed to append $Item to $Key\$Name"
		}
	}
	else
	{
		Write-Host "$Item already in $Key\$Name"
		$AddItem = ($CheckItem -join ';') + $Semi
		New-ItemProperty -Path $Key -Name $Name -PropertyType String -Value $AddItem -Force -EA Stop | Out-Null
		Write-Host "$Key\$Name previously $Prev"
		Write-Host "Cleaned up list $Key\$Name to $AddItem"
	}
}

