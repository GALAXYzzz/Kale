<######################################################################
FWIRMM Dynamic RS-232 Display Detection Script version 5

Created by:
   Kyle Rupprecht - kyle.rupprecht@fourwindsinteractive.com - November 2018

Description:
	This script will gather information about the display or displays attached to the target PC.
	This script is intended for use on RS-232 enabled and ready displays and will assume that all screens
    attached to the PC will be identical in manufacturer and will be connected in sequence via RS-232.

Instructions:
    Running the script with no arguments will gather information from the RS232 connected displays and output
    that information to an XML file (C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML).

    To run the script with no arguments and generate the XML, right click the script and click "Run with Powershell".

    This script can then be called using one of the 4 parameters listed:  -getMFG, -getPORT, -getCOUNT, or -getINPUT
    Using the arguments will have the script pull information directly from the XML file and output the result.

    The "-getINPUT" argument requires a second argument signalling the screen number for which you would like to see the input.
    
    For example:
        powershell.exe .\DisplayDetect.ps1 -getCOUNT
        or
        powershell.exe .\DisplayDetect.ps1 -getINPUT 1

	
########################################################################>

<#############################################################################################################
Version 5 Major Changes:
- Additional methods for discovering display manufacturer.
- Added check for VPro Port so the port can be avoided.
###############################################################################################################>

<#############################################################################################################
Version 4 Major Changes:
- Compatible with PShell version 2.x
- Removed port checks within each Screencount function.  Now using previously determined variable instead.
###############################################################################################################>

function NECscreencount
{

# Defining port used for communicating to screens

$PORTNAME = $args[0]
$port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one

# NEC "Power Mode (read only)" queries require unique hex values for the screen ID (third value) and the check code (fourteenth value).
# Here, hex values are converted to Bytes and then assigned to variables.

[Byte[]] $chkPower1 = 0x01,0x30,0x41,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x74,0x0D
[Byte[]] $chkPower2 = 0x01,0x30,0x42,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x77,0x0D
[Byte[]] $chkPower3 = 0x01,0x30,0x43,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x76,0x0D
[Byte[]] $chkPower4 = 0x01,0x30,0x44,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x71,0x0D
[Byte[]] $chkPower5 = 0x01,0x30,0x45,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x70,0x0D
[Byte[]] $chkPower6 = 0x01,0x30,0x46,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x73,0x0D
[Byte[]] $chkPower7 = 0x01,0x30,0x47,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x72,0x0D
[Byte[]] $chkPower8 = 0x01,0x30,0x48,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x7d,0x0D
[Byte[]] $chkPower9 = 0x01,0x30,0x49,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x7c,0x0D
[Byte[]] $chkPower10 = 0x01,0x30,0x4A,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x7f,0x0D
[Byte[]] $chkPower11 = 0x01,0x30,0x4B,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x7e,0x0D
[Byte[]] $chkPower12 = 0x01,0x30,0x4C,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x79,0x0D
[Byte[]] $chkPower13 = 0x01,0x30,0x4D,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x78,0x0D
[Byte[]] $chkPower14 = 0x01,0x30,0x4E,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x7b,0x0D
[Byte[]] $chkPower15 = 0x01,0x30,0x4F,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x7a,0x0D
[Byte[]] $chkPower16 = 0x01,0x30,0x50,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x65,0x0D
[Byte[]] $chkPower17 = 0x01,0x30,0x51,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x64,0x0D
[Byte[]] $chkPower18 = 0x01,0x30,0x52,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x67,0x0D
[Byte[]] $chkPower19 = 0x01,0x30,0x53,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x66,0x0D
[Byte[]] $chkPower20 = 0x01,0x30,0x54,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x61,0x0D

# We have a placeholder for the first array value since arrays by default start at zero and we don't have a screen 0 (we want to start with screen 1).

$placeholder = "placeholder"

$array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

$pwrstatus = @()

# Finally, opening the port sending commands via a loop.  Any command that receives a response from the correct screen will add a response to the $pwrstatus array.

	$port.Open()

	for ($i=1; $i -lt $array.length ; $i++){

	$port.Write($array[$i], 0, $array[$i].Count) 
	start-sleep -m 2000
	$temp = $port.ReadExisting()  
	start-sleep -m 2000
	$temp2 = [System.Text.Encoding]::UTF8.GetBytes($temp)
	$pwrstatus += ($temp2 -join " ")

	}

	$port.Close()

# After attempting to reach 20 total screens, we count the number of objects in the array that are not NULL and this gives us our total screen count.

$script:screencount = @(@($pwrstatus) | Where { -not [string]::IsNullOrEmpty($_) }).Count
if ($screencount -eq "0")		{$script:screencount = "Unknown"}

} #end of function

function SAMscreencount
{
# Defining port used for communicating to screens

$PORTNAME = $args[0]
$port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one

# hex codes to check for power
# for Samsung, value 3 is the screen id and value 5 is the checksum (the sum of all values except for the first)

[Byte[]] $chkPower1 = 0xAA,0x11,0x01,0x00,0x12
[Byte[]] $chkPower2 = 0xAA,0x11,0x02,0x00,0x13
[Byte[]] $chkPower3 = 0xAA,0x11,0x03,0x00,0x14
[Byte[]] $chkPower4 = 0xAA,0x11,0x04,0x00,0x15
[Byte[]] $chkPower5 = 0xAA,0x11,0x05,0x00,0x16
[Byte[]] $chkPower6 = 0xAA,0x11,0x06,0x00,0x17
[Byte[]] $chkPower7 = 0xAA,0x11,0x07,0x00,0x18
[Byte[]] $chkPower8 = 0xAA,0x11,0x08,0x00,0x19
[Byte[]] $chkPower9 = 0xAA,0x11,0x09,0x00,0x1A
[Byte[]] $chkPower10 = 0xAA,0x11,0x0A,0x00,0x1B
[Byte[]] $chkPower11 = 0xAA,0x11,0x0B,0x00,0x1C
[Byte[]] $chkPower12 = 0xAA,0x11,0x0C,0x00,0x1D
[Byte[]] $chkPower13 = 0xAA,0x11,0x0D,0x00,0x1E
[Byte[]] $chkPower14 = 0xAA,0x11,0x0E,0x00,0x1F
[Byte[]] $chkPower15 = 0xAA,0x11,0x0F,0x00,0x20
[Byte[]] $chkPower16 = 0xAA,0x11,0x10,0x00,0x21
[Byte[]] $chkPower17 = 0xAA,0x11,0x11,0x00,0x22
[Byte[]] $chkPower18 = 0xAA,0x11,0x12,0x00,0x23
[Byte[]] $chkPower19 = 0xAA,0x11,0x13,0x00,0x24
[Byte[]] $chkPower20 = 0xAA,0x11,0x14,0x00,0x25

# We have a placeholder for the first array value since arrays by default start at zero and we don't have a screen 0 (we want to start with screen 1).

$placeholder = "placeholder"

$array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

$pwrstatus = @()

# Finally, opening the port sending commands via a loop.  Any command that receives a response from the correct screen will add a response to the $pwrstatus array.


for ($i=1; $i -lt $array.length ; $i++)

			{
			$port.Open()
			$port.Write($array[$i], 0, $array[$i].Count) 
			start-sleep -m 2000
			$temp = $port.ReadExisting()  
			start-sleep -m 2000
			$temp2 = [System.Text.Encoding]::UTF8.GetBytes($temp)
			$pwrstatus += ($temp2 -join " ")
			$port.Close()
			}

# After attempting to reach 20 total screens, we count the number of objects in the array that are not NULL and this gives us our total screen count.

$script:screencount = @(@($pwrstatus) | Where { -not [string]::IsNullOrEmpty($_) }).Count
if ($screencount -eq "0")		{$script:screencount = "Unknown"}

} #end of function

function LGscreencount
{
			# Defining port used for communicating to screens

            $PORTNAME = $args[0]
            $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
                    
			# NEC "Power Mode (read only)" queries require unique hex values for the screen ID (third value) and the check code (fourteenth value).
			# Here, hex values are converted to Bytes and then assigned to variables.

			#check power on screen 1
			$chkPower1 = "ka 01 ff"
			#check power on screen 2
			$chkPower2 = "ka 02 ff"
			#check power on screen 3
			$chkPower3 = "ka 03 ff"
			#check power on screen 4
			$chkPower4 = "ka 04 ff"
			#check power on screen 5
			$chkPower5 = "ka 05 ff"
			#check power on screen 6
			$chkPower6 = "ka 06 ff"
			#check power on screen 7
			$chkPower7 = "ka 07 ff"
			#check power on screen 8
			$chkPower8 = "ka 08 ff"
			#check power on screen 9
			$chkPower9 = "ka 09 ff"
			#check power on screen 10
			$chkPower10 = "ka 10 ff"
			#check power on screen 11
			$chkPower11 = "ka 11 ff"
			#check power on screen 12
			$chkPower12 = "ka 12 ff"
			#check power on screen 13
			$chkPower13 = "ka 13 ff"
			#check power on screen 14
			$chkPower14 = "ka 14 ff"
			#check power on screen 15
			$chkPower15 = "ka 15 ff"
			#check power on screen 16
			$chkPower16 = "ka 16 ff"
			#check power on screen 17
			$chkPower17 = "ka 17 ff"
			#check power on screen 18
			$chkPower18 = "ka 18 ff"
			#check power on screen 19
			$chkPower19 = "ka 19 ff"
			#check power on screen 20
			$chkPower20 = "ka 20 ff"


			# We have a placeholder for the first array value since arrays by default start at zero and we don't have a screen 0 (we want to start with screen 1).

			$placeholder = "placeholder"

			$array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

			$pwrstatus = @()

			# Finally, opening the port sending commands via a loop.  Any command that receives a response from the correct screen will add a response to the $pwrstatus array.

			$port.Open()

			for ($i=1; $i -lt $array.length ; $i++){

			$port.WriteLine($array[$i])
			start-sleep -m 1000
			$temp = $port.ReadExisting()

			$pwrstatus += ($temp -join " ")

			}

			$port.Close()

# After attempting to reach 20 total screens, we count the number of objects in the array that are not NULL and this gives us our total screen count.

$script:screencount = @(@($pwrstatus) | Where { -not [string]::IsNullOrEmpty($_) }).Count
if ($screencount -eq "0")		{$script:screencount = "Unknown"}

} #end of function

function MFGcheck
{

    if ($MFG -eq "Unknown")
        {
                Try
                {
                        $Monitors = Get-WmiObject WmiMonitorID -Namespace root\wmi -ErrorAction Stop
                        ForEach ($Monitor in $Monitors)
                        {
                            $script:MFG = ($Monitor.ManufacturerName -notmatch 0 | ForEach{[char]$_}) -join ""
                            #$MOD = ($Monitor.UserFriendlyName -notmatch 0 | ForEach{[char]$_}) -join ""    
                            break
                        }
                }

                Catch
                {
                        $script:MFG = "Unknown"
                }
        }

    if ($MFG -eq "Unknown")
        {
                try
                {
                        $Monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams | Select InstanceName
                        $Mon1 = [string]($Monitors[0])
                        $Info = $Mon1.split('\')
                        $script:MFG = $Info[1].Substring(0,3)
                        #$MOD = $Info[1].Substring(4,3)
                }
                catch
                {
                        $script:MFG = "Unknown"
                }
        }

    if ($MFG -eq "Unknown")
        {
                try
                {
                        $colItems = get-wmiobject -class "Win32_DesktopMonitor" -namespace "root\CIMV2"
                        foreach ($objItem in $colItems) {$MON = [string]$objItem.PNPDeviceID;break}
                        $MON = $MON.split('\')
                        $script:MFG = $MON[1].Substring(0,3)
                }
                catch
                {
                        $script:MFG = "Unknown"
                }
        }

    if ($MFG -eq "Unknown")
        {
            function getcomports {
                $result = [System.IO.Ports.SerialPort]::GetPortNames()
                Write-Output $result
                }
                
            $COMports = getcomports | where {$_ -NotLike $VPROportname}
            $port = "placeholder"
            write-host $COMports.count

            if ($COMports.count -eq 0 -or $COMports -eq $null)  
                {
                    $script:MFG = "Unknown"
                    $script:portname = "No COM ports detected!"
                    $script:continue = "False"
                }
                
            elseif ($COMports.count -gt 1)
                {
                    if ($MFG -eq "Unknown")

                        {
                            $counter = 0
                            [Byte[]] $NECtest = 0x01,0x30,0x41,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x74,0x0D
                            $return = ""

                                while   ($return -eq "" -and $counter -lt $COMports.count)
                                            {
                                                $port = new-Object System.IO.Ports.SerialPort $COMports[$counter],9600,None,8,one
                                                $port.Open()
                                                start-sleep -m 2000
                                                $port.Write($NECtest, 0, $NECtest.Count)
                                                start-sleep -m 2000
                                                $return = $port.ReadExisting()
                                                start-sleep -m 2000
                                                $port.Close()
                                                start-sleep -m 2000
                                                $counter++
                                            }

                            if      ($return -ne "")    {$script:MFG = "NEC"}
                            else                        {$script:MFG = "Unknown"}
                        }

                    if ($MFG -eq "Unknown")

                        {

                            $counter = 0
                            [Byte[]] $SAMtest = 0xAA,0x11,0x01,0x00,0x12
                            $return = ""

                                while   ($return -eq "" -and $counter -lt $COMports.count)
                                            {
                                                $port = new-Object System.IO.Ports.SerialPort $COMports[$counter],9600,None,8,one
                                                $port.Open()
                                                start-sleep -m 2000
                                                $port.Write($SAMtest, 0, $SAMtest.Count)
                                                start-sleep -m 2000
                                                $return = $port.ReadExisting()
                                                start-sleep -m 2000
                                                $port.Close()
                                                start-sleep -m 2000
                                                $counter++
                                            }

                            if      ($return -ne "")    {$script:MFG = "SAM"}
                            else                        {$script:MFG = "Unknown"}                                            
                        }

                    if ($MFG -eq "Unknown")

                        {

                            $counter = 0
                            $LGtest = "ka 01 ff"
                            $return = ""
        
                                while   ($return -eq "" -and $counter -lt $COMports.count)
                                            {
                                                $port = new-Object System.IO.Ports.SerialPort $COMports[$counter],9600,None,8,one
                                                $port.Open()
                                                start-sleep -m 2000
                                                $port.WriteLine("")
                                                start-sleep -m 2000
                                                $port.WriteLine($LGtest)
                                                start-sleep -m 2000
                                                $return = $port.ReadExisting()
                                                start-sleep -m 2000
                                                $port.Close()
                                                start-sleep -m 2000
                                                $counter++
                                            }

                            if      ($return -ne "")    {$script:MFG = "GSM"}
                            else                        {$script:MFG = "Unknown"}                                            
                                    
                        }
        
                    if  ($MFG -eq "Unknown")

                                {
                                $script:continue = "False"
                                }
                }
                
            else
                {
                    if      ($MFG -eq "Unknown")
                        {
                            $port = new-Object System.IO.Ports.SerialPort $COMports,9600,None,8,one
                            [Byte[]] $NECtest = 0x01,0x30,0x41,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x74,0x0D
                            $return = ""

                                $port.Open()
                                start-sleep -m 2000
                                $port.Write($NECtest, 0, $NECtest.Count)
                                start-sleep -m 2000
                                $return = $port.ReadExisting()
                                start-sleep -m 2000
                                $port.Close()
                                start-sleep -m 2000

                            if      ($return -ne "")    {$script:MFG = "NEC"}
                            else                        {$script:MFG = "Unknown"}
                        }
                    if      ($MFG -eq "Unknown")
                        {
                            $port = new-Object System.IO.Ports.SerialPort $COMports,9600,None,8,one
                            [Byte[]] $SAMtest = 0xAA,0x11,0x01,0x00,0x12
                            $return = ""

                                $port.Open()
                                start-sleep -m 2000
                                $port.Write($SAMtest, 0, $SAMtest.Count)
                                start-sleep -m 2000
                                $return = $port.ReadExisting()
                                start-sleep -m 2000
                                $port.Close()
                                start-sleep -m 2000

                            if      ($return -ne "")    {$script:MFG = "SAM"}
                            else                        {$script:MFG = "Unknown"}    
                        }
                    if      ($MFG -eq "Unknown")
                        {
                            $port = new-Object System.IO.Ports.SerialPort $COMports,9600,None,8,one
                            $LGtest = "ka 01 ff"
                            $return = ""

                                $port.Open()
                                start-sleep -m 2000
                                $port.WriteLine("")
                                start-sleep -m 2000
                                $port.WriteLine($LGtest)
                                start-sleep -m 2000
                                $return = $port.ReadExisting()
                                start-sleep -m 2000
                                $port.Close()
                                start-sleep -m 2000

                            if      ($return -ne "")    {$script:MFG = "GSM"}
                            else                        {$script:MFG = "Unknown"}

                        }
                    if      ($MFG -eq "Unknown")
                        {
                            $script:continue = "False"
                        }
                }
            }
} #end of function


function getMFG
{
    [xml]$info = (get-content "C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML")
    $MFG = $info.SelectNodes("//MFG") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    Write-host $MFG
    Exit
} #end of function

function getPORT
{
    [xml]$info = (get-content "C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML")
    $PORT = $info.SelectNodes("//Port") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    Write-host $PORT
    Exit
} #end of function

function getCOUNT
{
    [xml]$info = (get-content "C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML")
    $COUNT = $info.SelectNodes("//NumberOfScreens") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    Write-host $COUNT
    Exit
} #end of function

function getINPUT
{
    $number = $args[0]
    [xml]$info = (get-content "C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML")
    $INPT = $info.SelectNodes("//Screen"+$number+"/Input") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    Write-host $INPT
    Exit
} #end of function

##################START OF SCRIPT##################

#create XML path
$XMLPath="C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML"

#check if user is trying to pull info from XML

If ($args[0] -eq "-getDATE")
    {
        If 	(-Not (Test-Path $XMLPath)) {Write-host "XML File does not exist.  Please run script with no arguments to create XML.";Exit}
        getDATE
    }

If ($args[0] -eq "-getMFG")
    {
        If 	(-Not (Test-Path $XMLPath)) {Write-host "XML File does not exist.  Please run script with no arguments to create XML.";Exit}
        getMFG
    }

If ($args[0] -eq "-getPORT")
    {
        If 	(-Not (Test-Path $XMLPath)) {Write-host "XML File does not exist.  Please run script with no arguments to create XML.";Exit}
        getPORT
    }

If ($args[0] -eq "-getCOUNT")
    {
        If 	(-Not (Test-Path $XMLPath)) {Write-host "XML File does not exist.  Please run script with no arguments to create XML.";Exit}
        getCOUNT
    }

If ($args[0] -eq "-getINPUT") 
    {    
        If 	(-Not (Test-Path $XMLPath)) {Write-host "XML File does not exist.  Please run script with no arguments to create XML.";Exit}
        IF  ($args[1] -eq $null) {Write-host "Please include screen number as second argument";Exit}
        $number = $args[1]
        getINPUT $number
    }

# If XML file already exists, delete it.
If 	(Test-Path $XMLPath) {Remove-Item -Path $XMLPath}
[xml]$Doc = New-Object System.Xml.XmlDocument
#XML create declaration
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$doc.AppendChild($dec) | Out-Null
#XML create comment
$text = @"
 
RS232 Screen Inventory
Generated $(Get-Date)
 
"@
$doc.AppendChild($doc.CreateComment($text)) | Out-Null
#XML create root Node
$root_node = $doc.CreateNode("element","Root",$null)

# Look for VPRO ports so they can be ignored in the future
try 
{
$VPROport = Get-WMIObject Win32_PnPEntity | where {$_.Name -like "Intel(R) Active Management Technology*"} | Select Name
$VPROport = [string]($VPROport)
$VPROportname = $VPROport.split('(')
$VPROportname = $VPROportname[2].Substring(0,4)
}
catch 
{
$VPROportname = "None"
}

# Get Screen Manufacturer and Model
# 4 different methods

# variables
$MFG = "Unknown"
$screencount = "Unknown"
$continue = "True"
#declaring port variables
$port = "Unknown"
$portname = "Unknown"

# MFG check
if ($MFG -eq "Unknown")        {MFGcheck}

# 3-Letter codes supported for each MFG
$SAM_array = "SAM"
$NEC_array = "NEC","ADV"
$LG_array = "LGD","GSM","GN"

#XML create manufacturer node
$manufacturer_node = $doc.CreateNode("element","MFG",$null)
$manufacturer_node.InnerText = $MFG
#XML end of manufacturer node
$root_node.AppendChild($manufacturer_node) | Out-Null

#finding port to use
If          ($NEC_array -contains $MFG -and $continue -eq "True")
    {
            function getcomports {
                $result = [System.IO.Ports.SerialPort]::GetPortNames()
                Write-Output $result
                }
                
            $COMports = getcomports | where {$_ -NotLike $VPROportname}
            $port = "placeholder"
        
            if ($COMports.count -eq 0 -or $COMports -eq $null)  
                {
                    $script:portname = "No COM ports detected!"
                    $script:continue = "False"
                }
                
            elseif ($COMports.count -gt 1)
                {
                
                    $counter = 0
                    [Byte[]] $test = 0x01,0x30,0x41,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x74,0x0D
                    $return = ""
            
                        while ($return -eq "" -and $counter -lt $COMports.count)
                                {
                                $script:port = new-Object System.IO.Ports.SerialPort $COMports[$counter],9600,None,8,one
                                $port.Open()
                                $port.Write($test, 0, $test.Count)
                                start-sleep -m 2000
                                $return = $port.ReadExisting()  
                                start-sleep -m 2000
                                $port.Close()
                                $counter++
                                } 
                        if ($return -eq "")
                                {
                                $script:portname = "No communication on "+$COMports
                                $script:continue = "False"                
                                }
                        else
                                {
                                $script:portname = $port.PortName
                                }
        
                }
                
            else
                {
                    $script:port = new-Object System.IO.Ports.SerialPort $COMports,9600,None,8,one
                    [Byte[]] $test = 0x01,0x30,0x41,0x30,0x41,0x30,0x36,0x02,0x30,0x31,0x44,0x36,0x03,0x74,0x0D
                    $return = ""

                                $port.Open()
                                $port.Write($test, 0, $test.Count)
                                start-sleep -m 2000
                                $return = $port.ReadExisting()  
                                start-sleep -m 2000
                                $port.Close()

                        if ($return -eq "")
                                {
                                $script:portname = "No communication on "+$port.PortName
                                $script:continue = "False"
                                }
                        else
                                {
                                $script:portname = $port.PortName
                                }
        
                }        

    }
Elseif      ($SAM_array -contains $MFG -and $continue -eq "True")
    {
        function getcomports {
            $result = [System.IO.Ports.SerialPort]::GetPortNames()
            Write-Output $result
            }
            
        $COMports = getcomports | where {$_ -NotLike $VPROportname}
        $port = "placeholder"
            
        if ($COMports.count -eq 0 -or $COMports -eq $null)  
            {
                $script:portname = "No COM ports detected!"
                $script:continue = "False"
            }
        
        elseif ($COMports.count -gt 1)
            {
            
                $counter = 0
                [Byte[]] $test = 0xAA,0x11,0x01,0x00,0x12
                $return = ""
        
                    while ($return -eq "" -and $counter -lt $COMports.count)
                            {
                            $script:port = new-Object System.IO.Ports.SerialPort $COMports[$counter],9600,None,8,one
                            $port.Open()
                            $port.Write($test, 0, $test.Count)
                            start-sleep -m 2000
                            $return = $port.ReadExisting()  
                            start-sleep -m 2000
                            $port.Close()
                            $counter++
                            } 

                    if ($return -eq "")
                            {
                            $script:portname = "No communication on "+$COMports
                            $script:continue = "False"                
                            }
                    else
                            {
                            $script:portname = $port.PortName
                            }
    
            }
        
        else
            {
                $script:port = new-Object System.IO.Ports.SerialPort $COMports,9600,None,8,one
                [Byte[]] $test = 0xAA,0x11,0x01,0x00,0x12
                $return = ""

                    $port.Open()
                    $port.Write($test, 0, $test.Count)
                    start-sleep -m 2000
                    $return = $port.ReadExisting()  
                    start-sleep -m 2000
                    $port.Close()

                if ($return -eq "")
                        {
                        $script:portname = "No communication on "+$port.PortName
                        $script:continue = "False"
                        }
                else
                        {
                        $script:portname = $port.PortName
                        }
            }
    }
Elseif      ($LG_array -contains $MFG -and $continue -eq "True")
    {
	function getcomports {
		$result = [System.IO.Ports.SerialPort]::GetPortNames()
		Write-Output $result
		}
		
    $COMports = getcomports | where {$_ -NotLike $VPROportname}
	$port = "placeholder"
		
	if ($COMports.count -eq 0 -or $COMports -eq $null)  
		{
            $script:portname = "No COM ports detected!"
            $script:continue = "False"
		}
	
	elseif ($COMports.count -gt 1)
		{
		
			$counter = 0
			$test = "ka 01 ff"
			$return = ""
	
				while ($return -eq "" -and $counter -lt $COMports.count)
						{
						$script:port = new-Object System.IO.Ports.SerialPort $COMports[$counter],9600,None,8,one
						$port.Open()
						$port.WriteLine($test)
						start-sleep -m 1000
						$return = $port.ReadExisting()  
						start-sleep -m 2000
						$port.Close()
						$counter++
                        }

                if ($return -eq "")
                        {
                        $script:portname = "No communication on "+$COMports
                        $script:continue = "False"                
                        }
                else
                        {
                        $script:portname = $port.PortName
                        }
    
		}
	
	else
		{
            $script:port = new-Object System.IO.Ports.SerialPort $COMports,9600,None,8,one
            $test = "ka 01 ff"
            $return = ""

                        $port.Open()
                        $port.WriteLine($test)
                        start-sleep -m 1000
                        $return = $port.ReadExisting()  
                        start-sleep -m 2000
                        $port.Close()

                if ($return -eq "")
                        {
                        $script:portname = "No communication on "+$port.PortName
                        $script:continue = "False"
                        }
                else
                        {
                        $script:portname = $port.PortName
                        }
		}
    }
Else
    {
    $portname = "Unknown"
    $script:continue = "False"
    }

#XML create port node
$port_node = $doc.CreateNode("element","Port",$null)
$port_node.InnerText = $portname
#XML end of port node
$root_node.AppendChild($port_node) | Out-Null

#Count Screens
	
If      ($NEC_array -contains $MFG -and $continue -eq "True")         {NECscreencount $portname}
Elseif  ($SAM_array -contains $MFG -and $continue -eq "True")         {SAMscreencount $portname}
Elseif  ($LG_array -contains $MFG -and $continue -eq "True")          {LGscreencount $portname}
Else                                                                  {$screencount = "Unknown"}

#XML create screencount node
$screencount_node = $doc.CreateNode("element","NumberOfScreens",$null)
$screencount_node.InnerText = $screencount
#XML end of screencount node
$root_node.AppendChild($screencount_node) | Out-Null

#XML create screeninfo node
$screeninfo_node = $doc.CreateNode("element","ScreenInfo",$null)

# Get Screens Input

If      ($NEC_array -contains $MFG -and $continue -eq "True")
    {
        [Byte[]] $chkInput1 = 0x01,0x30,0x41,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x03,0x0D
        [Byte[]] $chkInput2 = 0x01,0x30,0x42,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x00,0x0D
        [Byte[]] $chkInput3 = 0x01,0x30,0x43,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x01,0x0D
        [Byte[]] $chkInput4 = 0x01,0x30,0x44,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x06,0x0D
        [Byte[]] $chkInput5 = 0x01,0x30,0x45,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x07,0x0D
        [Byte[]] $chkInput6 = 0x01,0x30,0x46,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x04,0x0D
        [Byte[]] $chkInput7 = 0x01,0x30,0x47,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x05,0x0D
        [Byte[]] $chkInput8 = 0x01,0x30,0x48,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x0A,0x0D
        [Byte[]] $chkInput9 = 0x01,0x30,0x49,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x0B,0x0D
        [Byte[]] $chkInput10 = 0x01,0x30,0x4A,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x08,0x0D
        [Byte[]] $chkInput11 = 0x01,0x30,0x4B,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x09,0x0D
        [Byte[]] $chkInput12 = 0x01,0x30,0x4C,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x0E,0x0D
        [Byte[]] $chkInput13 = 0x01,0x30,0x4D,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x0F,0x0D
        [Byte[]] $chkInput14 = 0x01,0x30,0x4E,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x0C,0x0D
        [Byte[]] $chkInput15 = 0x01,0x30,0x4F,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x0D,0x0D
        [Byte[]] $chkInput16 = 0x01,0x30,0x50,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x12,0x0D
        [Byte[]] $chkInput17 = 0x01,0x30,0x51,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x13,0x0D
        [Byte[]] $chkInput18 = 0x01,0x30,0x52,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x10,0x0D
        [Byte[]] $chkInput19 = 0x01,0x30,0x53,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x11,0x0D
        [Byte[]] $chkInput20 = 0x01,0x30,0x54,0x30,0x43,0x30,0x36,0x02,0x30,0x30,0x36,0x30,0x03,0x16,0x0D

        $placeholder = "placeholder"

        $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20
    
        $i = 1

        for ($i = 1; $i -le $screencount; $i++)

                {
                    $port.Open()
                    $port.Write($input_array[$i], 0, $input_array[$i].Count)
                    start-sleep -m 1000
                    $input_temp = $port.ReadExisting()
                    start-sleep -m 1000
                    $input_return = [System.Text.Encoding]::UTF8.GetBytes($input_temp)
                    $port.Close()
        
                    if      ($input_return[20] -eq 48 -And $input_return[21] -eq 48 -And $input_return[22] -eq 49 -And $input_return[23] -eq 49) {$input_return_english = "HDMI"}
                    elseif  ($input_return[20] -eq 48 -And $input_return[21] -eq 48 -And $input_return[22] -eq 48 -And $input_return[23] -eq 70) {$input_return_english = "DP"}
                    elseif  ($input_return[20] -eq 48 -And $input_return[21] -eq 48 -And $input_return[22] -eq 48 -And $input_return[23] -eq 51) {$input_return_english = "DVI"}
                    elseif  ($input_return[20] -eq 48 -And $input_return[21] -eq 48 -And $input_return[22] -eq 49 -And $input_return[23] -eq 50) {$input_return_english = "DVD_HD1"}
                    else                                                                                                                         {$input_return_english = "Unknown"}
        
                    $screen_node = $doc.CreateNode("element","Screen"+$i,$null)
        
                    $Input = $doc.CreateElement("Input")
                    $Input.InnerText = $input_return_english
                    $screen_node.AppendChild($Input) | Out-Null
                
                    $screeninfo_node.AppendChild($screen_node) | Out-Null
                }
    }
Elseif  ($SAM_array -contains $MFG -and $continue -eq "True")
    {
        [Byte[]] $chkInput1 = 0xAA,0x14,0x01,0x00,0x15
        [Byte[]] $chkInput2 = 0xAA,0x14,0x02,0x00,0x16
        [Byte[]] $chkInput3 = 0xAA,0x14,0x03,0x00,0x17
        [Byte[]] $chkInput4 = 0xAA,0x14,0x04,0x00,0x18
        [Byte[]] $chkInput5 = 0xAA,0x14,0x05,0x00,0x19
        [Byte[]] $chkInput6 = 0xAA,0x14,0x06,0x00,0x1A
        [Byte[]] $chkInput7 = 0xAA,0x14,0x07,0x00,0x1B
        [Byte[]] $chkInput8 = 0xAA,0x14,0x08,0x00,0x1C
        [Byte[]] $chkInput9 = 0xAA,0x14,0x09,0x00,0x1D
        [Byte[]] $chkInput10 = 0xAA,0x14,0x0A,0x00,0x1E
        [Byte[]] $chkInput11 = 0xAA,0x14,0x0B,0x00,0x1F
        [Byte[]] $chkInput12 = 0xAA,0x14,0x0C,0x00,0x20
        [Byte[]] $chkInput13 = 0xAA,0x14,0x0D,0x00,0x21
        [Byte[]] $chkInput14 = 0xAA,0x14,0x0E,0x00,0x22
        [Byte[]] $chkInput15 = 0xAA,0x14,0x0F,0x00,0x23
        [Byte[]] $chkInput16 = 0xAA,0x14,0x10,0x00,0x24
        [Byte[]] $chkInput17 = 0xAA,0x14,0x11,0x00,0x25
        [Byte[]] $chkInput18 = 0xAA,0x14,0x12,0x00,0x26
        [Byte[]] $chkInput19 = 0xAA,0x14,0x13,0x00,0x27
        [Byte[]] $chkInput20 = 0xAA,0x14,0x14,0x00,0x28

        $placeholder = "placeholder"

        $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20
    
        $i = 1

        for ($i = 1; $i -le $screencount; $i++)

                {
                    $port.Open()
                    $port.Write($input_array[$i], 0, $input_array[$i].Count) 
                    start-sleep -m 1000
                    $input_temp = $port.ReadExisting()  
                    start-sleep -m 1000
                    $input_return = [System.Text.Encoding]::UTF8.GetBytes($input_temp)
                    $port.Close()

                    if      ($input_return[6] -eq 33) {$input_return_english = "HDMI"}
                    elseif  ($input_return[6] -eq 34) {$input_return_english = "HDMI_PC"}
                    elseif  ($input_return[6] -eq 35) {$input_return_english = "HDMI2"}
                    elseif  ($input_return[6] -eq 36) {$input_return_english = "HDMI2_PC"}
                    elseif  ($input_return[6] -eq 37) {$input_return_english = "DP"}
                    elseif  ($input_return[6] -eq 24) {$input_return_english = "DVI"}
                    elseif  ($input_return[6] -eq 31) {$input_return_english = "DVI_video"}
                    elseif  ($input_return[6] -eq 20) {$input_return_english = "VGA"}
                    else                              {$input_return_english = "Unknown"}
                
                    $screen_node = $doc.CreateNode("element","Screen"+$i,$null)
        
                    $Input = $doc.CreateElement("Input")
                    $Input.InnerText = $input_return_english
                    $screen_node.AppendChild($Input) | Out-Null
                
                    $screeninfo_node.AppendChild($screen_node) | Out-Null
                }
    

    }
Elseif  ($LG_array -contains $MFG -and $continue -eq "True")
    {
        $chkInput1 = "xb 01 ff"
        $chkInput2 = "xb 02 ff"
        $chkInput3 = "xb 03 ff"
        $chkInput4 = "xb 04 ff"
        $chkInput5 = "xb 05 ff"
        $chkInput6 = "xb 06 ff"
        $chkInput7 = "xb 07 ff"
        $chkInput8 = "xb 08 ff"
        $chkInput9 = "xb 09 ff"
        $chkInput10 = "xb 10 ff"
        $chkInput11 = "xb 11 ff"
        $chkInput12 = "xb 12 ff"
        $chkInput13 = "xb 13 ff"
        $chkInput14 = "xb 14 ff"
        $chkInput15 = "xb 15 ff"
        $chkInput16 = "xb 16 ff"
        $chkInput17 = "xb 17 ff"
        $chkInput18 = "xb 18 ff"
        $chkInput19 = "xb 19 ff"
        $chkInput20 = "xb 20 ff"
    
        $placeholder = "placeholder"

        $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20
    
        $i = 1

        for ($i = 1; $i -le $screencount; $i++)

                {
                    $port.Open()
                    $port.WriteLine($input_array[$i])
                    start-sleep -m 1000
                    $input_return = $port.ReadExisting()
                    $port.Close()

                    if 			($input_return -eq "b 0"+$i+" OK90x") 	{$input_return_english = "HDMI"}
                    elseif 		($input_return -eq "b 0"+$i+" OKa0x") 	{$input_return_english = "HDMI1"}
                    elseif 		($input_return -eq "b 0"+$i+" OKa1x") 	{$input_return_english = "HDMI2"}
                    elseif 		($input_return -eq "b 0"+$i+" OKd0x") 	{$input_return_english = "DP_PC"}
                    elseif 		($input_return -eq "b 0"+$i+" OKc0x") 	{$input_return_english = "DP_DTV"}
                    elseif 		($input_return -eq "b 0"+$i+" OK70x") 	{$input_return_english = "DVI"}
                    else 										        {$input_return_english = "Unknown"}

                    $screen_node = $doc.CreateNode("element","Screen"+$i,$null)
        
                    $Input = $doc.CreateElement("Input")
                    $Input.InnerText = $input_return_english
                    $screen_node.AppendChild($Input) | Out-Null
                
                    $screeninfo_node.AppendChild($screen_node) | Out-Null
                }

    }

$root_node.AppendChild($screeninfo_node) | Out-Null

# XML exit Root node and save XML
$doc.AppendChild($root_node) | Out-Null
$doc.save($XMLPath)