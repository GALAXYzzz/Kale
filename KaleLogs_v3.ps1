# Kale Logs Powershell Script revision 3 - May 2018
# Written by Kyle Rupprecht - kyle.rupprecht@fourwindsinteractive.com
# Four Winds Interactive

# Check for Content Player version and set variables accordingly

If 	(Test-Path "C:\Users\Public\Documents\Four Winds Interactive\Signage\Profiles\(default)\Logs\PlayerLog.txt") {
	$currentlog = "C:\Users\Public\Documents\Four Winds Interactive\Signage\Profiles\(default)\Logs\PlayerLog.txt";
	$currentlog1 = "C:\Users\Public\Documents\Four Winds Interactive\Signage\Profiles\(default)\Logs\PlayerLog.txt.1" }
	
ElseIf (Test-Path "C:\Users\Public\Documents\Four Winds Interactive\Signage\Logs\PlayerLog.txt") {
	$currentlog = "C:\Users\Public\Documents\Four Winds Interactive\Signage\Logs\PlayerLog.txt";
	$currentlog1 = "C:\Users\Public\Documents\Four Winds Interactive\Signage\Logs\PlayerLog.txt.1" }
	
ElseIf (Test-Path "C:\Documents and Settings\All Users\Documents\Four Winds Interactive\Signage\Logs\PlayerLog.txt") {
	$currentlog = "C:\Documents and Settings\All Users\Documents\Four Winds Interactive\Signage\Logs\PlayerLog.txt" ;
	$currentlog1 = "C:\Documents and Settings\All Users\Documents\Four Winds Interactive\Signage\Logs\PlayerLog.txt.1" }
	
ElseIf (Test-Path "D:\Signage\Profiles\(default)\Logs\PlayerLog.txt") {
	$currentlog = "D:\Signage\Profiles\(default)\Logs\PlayerLog.txt" ;
	$currentlog1 = "D:\Signage\Profiles\(default)\Logs\PlayerLog.tx.1" }
	
ElseIf (Test-Path "D:\Program Files (x86)\Four Winds Interactive\Signage\Profiles\(default)\Logs\PlayerLog.txt") {
	$currentlog = "D:\Program Files (x86)\Four Winds Interactive\Signage\Profiles\(default)\Logs\PlayerLog.txt" ;
	$currentlog1 = "D:\Program Files (x86)\Four Winds Interactive\Signage\Profiles\(default)\Logs\PlayerLog.txt.1" }
	
ElseIf (Test-Path "C:\fwi\Signage\Profiles\(default)\Logs\PlayerLog.txt") {
	$currentlog = "C:\fwi\Signage\Profiles\(default)\Logs\PlayerLog.txt" ;
	$currentlog1 = "C:\fwi\Signage\Profiles\(default)\Logs\PlayerLog.txt.1" }
	
Else {
	Write-Host "PlayerLog cannot be found." ;
	Exit }


# Set Additional Variables

$kalelogs = "C:\Users\Public\Documents\Four Winds Interactive\FWIRMM Kale Logs\"
$previouslog = "C:\Users\Public\Documents\Four Winds Interactive\FWIRMM Kale Logs\PlayerLogPrevious.txt"
$output = "C:\Users\Public\Documents\Four Winds Interactive\FWIRMM Kale Logs\Kale_PlayerLog.txt"
$currentlogcopy = "C:\Users\Public\Documents\Four Winds Interactive\FWIRMM Kale Logs\PlayerLogCurrent.txt"

# Create Kale Logs directory

If (-NOT (Test-Path $kalelogs))
	{mkdir $kalelogs}

# If file2 does not exist, create first copy
	
If (-NOT (Test-Path $previouslog))
	{copy-item $currentlog -Destination $previouslog}

# Check if PlayerLog.txt.1 exists and set variables
	
if (Test-Path $currentlog1){
	$currentlog1time = (Get-Item $currentlog1).LastWriteTime;
	$tminus10 = (Get-Date).AddMinutes(-10);

# Check if currentlog1 has been written to in last 10 minutes
# If so, compare previous log to the currentlog1 and then append the new current log to the end

	if($currentlog1time -gt $tminus10){
		Compare-Object -referenceObject $(Get-Content $previouslog) -differenceObject $(Get-Content $currentlog1) | %{$_.Inputobject + $_.SideIndicator} | ft -auto | out-file $output -width 5000;
		Copy-Item $currentlog -Destination $currentlogcopy -force
		Add-Content -Path $currentlogcopy -Value "$(Get-Date -format "yyyy-MM-dd HH:mm:ss") - KALE LOGS WAS HERE"
		Add-Content -Path $output -Value (Get-Content $currentlogcopy);
		remove-item -path $previouslog -force;
		copy-item $currentlogcopy -Destination $previouslog -force;
		remove-item $currentlogcopy -force;
		write-host "Log compare is complete."
		}

# Otherwise, just compare the previous log to the current log
		
	else {
		Copy-Item $currentlog -Destination $currentlogcopy -force
		Add-Content -Path $currentlogcopy -Value "$(Get-Date -format "yyyy-MM-dd HH:mm:ss") - KALE LOGS WAS HERE"
		Compare-Object -referenceObject $(Get-Content $previouslog) -differenceObject $(Get-Content $currentlogcopy) | %{$_.Inputobject + $_.SideIndicator} | ft -auto | out-file $output -width 5000;
		remove-item -path $previouslog -force;
		copy-item $currentlogcopy -Destination $previouslog -force;
		remove-item $currentlogcopy -force;
		write-host "Log compare is complete."
		}
		}
		
# If PlayerLog.txt.1 doesn't exist, simply compare previouslog to currentlog

else {
		Copy-Item $currentlog -Destination $currentlogcopy -force
		Add-Content -Path $currentlogcopy -Value "$(Get-Date -format "yyyy-MM-dd HH:mm:ss") - KALE LOGS WAS HERE"
		Compare-Object -referenceObject $(Get-Content $previouslog) -differenceObject $(Get-Content $currentlogcopy) | %{$_.Inputobject + $_.SideIndicator} | ft -auto | out-file $output -width 5000;
		remove-item -path $previouslog -force;
		copy-item $currentlogcopy -Destination $previouslog -force;
		remove-item $currentlogcopy -force;
		write-host "Log compare is complete."
	}
