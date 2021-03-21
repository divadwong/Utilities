# Add an Item to a registry string.
# ie. Add-ItemToListInReg -Key HKCU:\PathTest -Name Path -Item c:\path3               HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3
# Optional switch -AppendEnd will add a delimter to the end.
# ie. Add-ItemToListInReg -Key HKCU:\PathTest -Name Path -Item c:\path3 -AppendEnd    HKCU:\PathTest\Path = c:\path1;c:\path2;c:\path3;

function Add-ItemToListInReg
{
param(
[Parameter(Mandatory = $true)][String]$Key,
[Parameter(Mandatory = $true)][String]$Name,
[Parameter(Mandatory = $true)][String]$Item,
[Parameter(Mandatory = $false)][String]$Delim = ';',
[Parameter(Mandatory = $false)][Switch]$AppendEnd
)

	if($AppendEnd){$AppDelimEnd = $Delim}
	$CheckItem = @(); $AddItem = ''
	$GetNameInfo = Get-ItemProperty $Key -Name $Name -EA 0
	
	if($GetNameInfo)
	{
		$Prev = "was " + $GetNameInfo.$Name
		$CheckItem = (($GetNameInfo.$Name).Split($Delim) -ne '').Trim() | Sort -Unique            # Remove duplicates, spaces and empty items from list
	}
	else
	{   # Create Registry Key if it does not exist
		if(!(Test-Path $Key)){New-Item -Path $Key -Force -EA 0 | Out-Null ; $Prev = "did not exist and key was created"}
		else{$Prev = "did not exist"}
	}                             
	if($CheckItem -notcontains $Item)
	{   # Append Item to end of string. Also add semicolon to end if -AppendEnd parameter used.
		if($CheckItem){$AddItem = ($CheckItem -join $Delim) + $Delim + $Item + $AppDelimEnd}      # Add to cleaned up existing list 
		else{$AddItem = $Item + $AppDelimEnd}     
	
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
		$AddItem = ($CheckItem -join $Delim) + $AppDelimEnd
		New-ItemProperty -Path $Key -Name $Name -PropertyType String -Value $AddItem -Force -EA Stop | Out-Null
		Write-Host "$Key\$Name previously $Prev"
		Write-Host "Cleaned up list $Key\$Name to $AddItem"
	}
}

