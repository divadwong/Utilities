function Add-UVIProcExcl($EXEtoAdd)
{
	$CtxUviKey = "HKLM:\SYSTEM\CurrentControlSet\Services\CtxUvi"
	$CtxUvi = Get-ItemProperty $CtxUviKey -Name UviProcessExcludes
	$CheckProc = @()
	$AddProc = ''
	
	$CheckProc = ($CtxUvi.UviProcessExcludes.Split(';') -ne '').Trim() | Sort -Unique
	if($CheckProc -notcontains $EXEtoAdd)
	{
		if($CheckProc){$AddProc = ($CheckProc -join ';') + ";$EXEtoAdd;"}
		else{$AddProc = "$EXEtoAdd;"}
	
		try{
			New-ItemProperty -Path $CtxUviKey -Name UviProcessExcludes -PropertyType String -Value $AddProc -Force -EA Stop | Out-Null
			Write-Host "$CtxUviKey\UviProcessExcludes set to $AddProc"
		}
	
		catch{
			Write-Host "Failed to append $EXEtoAdd to $CtxUviKey\UviProcessExcludes"
		}
	}
	else
	{Write-Host "$EXEtoAdd already in $CtxUviKey\UviProcessExcludes"}
}

Add-UVIProcExcl msedge.exe
