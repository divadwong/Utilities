# Append an Item to a registry string. 
# ie. Add-ItemToListInReg -Key HKCU:\PathTest -Name Path -Item c:\path3               HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3
# Optional switch -AppendEnd will add a delimter to the end.
# ie. Add-ItemToListInReg -Key HKCU:\PathTest -Name Path -Item c:\path3 -AppendEnd    HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3;
# Added -Cleanup switch to remove dupicates and blanks, otherwise item will just be added to end of list.
# Added optional -Delim parameter. Default set is semicolon

function Add-ItemToListInReg
{
param(
[Parameter(Mandatory = $true)][String]$Key,
[Parameter(Mandatory = $true)][String]$Name,
[Parameter(Mandatory = $true)][String]$Item,
[Parameter(Mandatory = $false)][String]$Delim = ';',
[Parameter(Mandatory = $false)][Switch]$Cleanup,
[Parameter(Mandatory = $false)][Switch]$AppendEnd
)

	if($AppendEnd){$AppDelimEnd = $Delim}
	$CheckItem = @(); $AddItem = ''
	$GetNameInfo = Get-ItemProperty $Key -Name $Name -EA 0
	
	if($GetNameInfo)
	{
		$Prev = "$Key\$Name was " + $GetNameInfo.$Name
		$CheckItem = (($GetNameInfo.$Name).Split($Delim) -ne '').Trim() | Sort -Unique # Remove duplicates, spaces and empty items from list
	}
	else
	{   # Create Registry Key if it does not exist
		if(!(Test-Path $Key)){New-Item -Path $Key -Force -EA 0 | Out-Null ; $Prev = "$Key did not exist and was created"}
		else{$Prev = "$Key\$Name did not exist"}
	}                             
	if($CheckItem -notcontains $Item)
	{   # Append Item to end of string. Also add delimter to end if -AppendEnd parameter used.
		if($Cleanup)
		{
			if($CheckItem){$AddItem = ($CheckItem -join $Delim) + $Delim + $Item + $AppDelimEnd}   # Add to cleaned up existing list 
			else{$AddItem = $Item + $AppDelimEnd}                                                  # Add to empty list
		}
		else
		{
			if($CheckItem)
			{
				if ($GetNameInfo.$Name -notmatch "$Delim$"){$GetNameInfo.$Name += $Delim}          # Add delimeter if needed
				$AddItem = $GetNameInfo.$Name + "$Item" + $AppDelimEnd                             # Append to existing list
			}
			else
			{$AddItem = $AddItem = $Item + $AppDelimEnd}                                           # Add to empty list
		}

		try{
			New-ItemProperty -Path $Key -Name $Name -PropertyType String -Value $AddItem -Force -EA Stop | Out-Null
			Write-Host "Previously $Prev"
			Write-Host "$Key\$Name set to $AddItem"
		}
	
		catch{
			Write-Host "Failed to append $Item to $Key\$Name"
		}
	}
	else
	{
		Write-Host "Previously $Prev"
		Write-Host "$Item already in $Key\$Name"
		if($Cleanup)
		{
			$AddItem = ($CheckItem -join $Delim) + $AppDelimEnd
			New-ItemProperty -Path $Key -Name $Name -PropertyType String -Value $AddItem -Force -EA Stop | Out-Null
			Write-Host "Cleaned up list $Key\$Name to $AddItem"
		}
	}
}

