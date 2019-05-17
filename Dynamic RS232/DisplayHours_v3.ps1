<######################################################################
FWIRMM Dynamic RS-232 Display Hours Script.

Created by:
   Kyle Rupprecht - kyle.rupprecht@fourwindsinteractive.com - October 2018

Description:
	This script will generate an XML that will be used to turn off RS232 displays overnight,
    on weekends, etc. in an effort to reduce energy use.
	This script is intended for use on RS-232 enabled and ready displays and will assume that all screens
	attached to the PC will be identical in manufacturer and model and will be connected in sequence via RS-232.

Instructions:
	This script must be given 3 parameters, the first being a time to turn on the displays,
	the second being a time to turn off the displays and the third parameter being the days that the screens 
	will remain off, spelled out, and seperated by commas.
    
    For example:
		powershell.exe .\DisplayTimes.ps1 07:00 19:00 Saturday,Sunday
	
########################################################################>

#create XML path
$XMLPath="C:\Windows\LTSvc\plugins\FWIRMM_RS232_HOURS.XML"
#$XMLPath="C:\Users\kyle.rupprecht\OneDrive - Four Winds Interactive\EMS Projects\Dynamic RS232\v3 Final\FWIRMM_RS232_HOURS.XML"

# If XML file already exists, delete it.
If 	(Test-Path $XMLPath) {Remove-Item -Path $XMLPath}

[xml]$Doc = New-Object System.Xml.XmlDocument
#XML create declaration
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$doc.AppendChild($dec) | Out-Null
#XML create comment
$text = @"
 
RS232 Display Hours
Generated $(Get-Date)
 
"@
$doc.AppendChild($doc.CreateComment($text)) | Out-Null

$OnTime = $args[0]
$OffTime = $args[1]
$DaysOff = $args[2]

$root_node = $doc.CreateNode("element","Root",$null)

#XML create manufacturer node
$ontime_node = $doc.CreateNode("element","OnTime",$null)
$ontime_node.InnerText = $OnTime
#XML end of screencount node
$root_node.AppendChild($ontime_node) | Out-Null

$offtime_node = $doc.CreateNode("element","OffTime",$null)
$offtime_node.InnerText = $OffTime
#XML end of screencount node
$root_node.AppendChild($offtime_node) | Out-Null

$daysoff_node = $doc.CreateNode("element","DaysOff",$null)
$daysoff_node.InnerText = $DaysOff
#XML end of screencount node
$root_node.AppendChild($daysoff_node) | Out-Null

$doc.AppendChild($root_node) | Out-Null
$doc.save($XMLPath)

Write-host "Done."