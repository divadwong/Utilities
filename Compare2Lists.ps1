# Created by David Wong
# Updated 7/09/19
# Script to compare two lists files
# Outputs 3 files. In both lists, In List1 Not List2, & In List2 Not List1

function CompareUserLists($userlist1, $userlist2)

{
	$ExistinBoth = $userList1 | Where-Object {$userlist2 -contains $_}
	if ($ExistinBoth)
	{
		# Write list to file and screen
		$Writefile = "$location\InBoth-$Filename1~and~$Filename2.txt"
        	$Count = $ExistinBoth.count
		#WriteDateHeader($Writefile)
		"$Count exists in both lists" > $Writefile
		$ExistinBoth >> $Writefile
		write-host `r`n$Writefile created
		write-host $Count exists in both lists
	}
	
	# Users who are in UserList1 but not in UserList2
	$InUserList2Not1 = $userList2 | Where-Object {$userlist1 -notcontains $_}
	if ($InUserList2Not1)
	{
		# Write list of users in UserList2 and Not in UserList1
		$Writefile = "$location\In~$Filename2~NOT~$Filename1.txt"
        	$Count = $InUserList2Not1.count
		#WriteDateHeader($Writefile)
		"$Count in $Filename2 but not in $Filename1" > $Writefile
		$InUserList2Not1 >> $Writefile
		write-host `r`n$Writefile created
		write-host $Count in $Filename2 but not in $Filename1
	}
	Else
		{write-host "`r`n0 in $Filename2 but not in $Filename1"}
	
	# Users who are in UserList2 but not in Userlist1
	$InUserList1Not2 = $Userlist1 | Where-Object {$userList2 -notcontains $_}
	if ($InUserList1Not2)
	{
		# Write list of users in Userlist1 but not UserList2
		$Writefile = "$location\In~$Filename1~NOT~$Filename2.txt"
        	$Count = $InUserList1Not2.count
		#WriteDateHeader($Writefile)
		"$Count in $Filename1 but not in $Filename2" > $Writefile
		$InUserList1Not2 >> $Writefile
		write-host `r`n$Writefile created
		write-host $Count in $Filename1 but not in $Filename2
	}
	Else
		{write-host "`r`n0 in $Filename1 but not in $Filename2"}	
}

###################  Beginning of script #########################
$location = Split-Path $PSCommandPath -Parent
# gets your lists
$Filename1 = Read-Host -Prompt 'Type first file to compare'
$Filename2 = Read-Host -Prompt 'Type second file to compare'
$File1 = "$location\$Filename1"
$File2 = "$location\$Filename2"
if (-NOT(Test-Path $File1) -OR -NOT(Test-Path $File2)){write-host "`r`nOne or more missing files detected";Read-Host -Prompt "Press Enter to Exit";Exit}
$List1 = Get-Content $File1
$List2 = Get-Content $File2
Write-host "`r`nPlease be patient"
Write-host "Processing files ......."
# create ArrayList for List1
$userList1 = New-Object system.Collections.ArrayList
# add each user to the ArrayList
foreach ($user in $List1)
{
	# Add to ArrayList,
	# Trim spaces in front and end
	$user=$user.Trim()
	If ($user -ne ""){$userList1.add($user) | Out-Null}
}

# create ArrayList for List2
$userList2 = New-Object system.Collections.ArrayList
# add each user to the ArrayList
foreach ($user in $List2)
{
	# Add to ArrayList,
	# Trim spaces in front and end
	$user=$user.Trim()
	If ($user -ne ""){$userList2.add($user) | Out-Null}
}
	
#  Compare userlists
CompareUserLists $userlist1 $userlist2

Read-Host -Prompt "`r`nPress Enter to Exit"	
