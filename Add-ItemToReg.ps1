function Add-ItemToReg
{
param(
[Parameter(Mandatory = $true)][String]$Key,
[Parameter(Mandatory = $true)][String]$Name,
[Parameter(Mandatory = $true)][String]$Item
)

	$CheckItem = @(); $AddItem = ''
	$GetNameInfo = Get-ItemProperty $Key -Name $Name -EA SilentlyContinue
	if($GetNameInfo)
	{$CheckItem = (($GetNameInfo.$Name).Split(';') -ne '').Trim() | Sort -Unique}
	else
	{New-Item -Path $Key -Force -EA Continue | Out-Null}
	if($CheckItem -notcontains $Item)
	{
		if($CheckItem){$AddItem = ($CheckItem -join ';') + ";$Item"}
		else{$AddItem = $Item}
	
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

Add-ItemToReg -Key HKCU:\Test\Test1\Test2 -Name Test -Item msedge3.exe
