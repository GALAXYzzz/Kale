<#############################################################################################################
FWIRMM Dynamic RS-232 Monitoring Script version 7

Created by:
   Kyle Rupprecht - kyle.rupprecht@fourwindsinteractive.com - November 2018

Description:
	This script is designed to check the input and power settings for attached RS-232 displays and attempt to restore
	the correct settings if needed.
	This script is intended for use with RS-232 enabled and ready displays and will require that all screens
	attached to the PC will be identical in manufacturer and will be connected in sequence via RS-232.

Instructions:
    This script requires an XML file to gather the monitor information.
    To generate the XML file, please run the script called DisplayDetect.ps1
    The XML file will be located here:
        C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML

    Optionally, the working hours of this script can be determined via another XML.
    To generate this XML file, please run the script called DisplayHours.ps1
    The working hours XML will be located here:
        C:\Windows\LTSvc\plugins\FWIRMM_RS232_HOURS.XML
	
##############################################################################################################>

<#############################################################################################################
Version 7 Major Changes:
- New method for restarting Content Player using a scheduled task that gets called from this script.
- The scheduled task will get created when DisplayDetect is run from RMM.
- Changed off hours check of last 3 status entries to its own function.
###############################################################################################################>

<#############################################################################################################
Version 6 Major Changes:
- Limiting error log to 2MB and hisory log to 200MB - keeping copies of old logs
- New CP restart function using IF statement.
- Changed sleeps after turn on to 30 seconds rather than 60 to alleviate some issues with RMM.
- Added timestamp filter.  Logs format may changeover in near future to timestamps on every line.
- Change to history log entries - only writing "Screen Reset?" entry once at the end of each script run.
- Now checking last 3 "Screen Reset?" history log entries during off hours.
- Screens are now checked during off hours, to make sure they stay off.
###############################################################################################################>

<#############################################################################################################
Version 5 Major Changes:
- Added Content Player restart after anytime the screens are turned on/reset to ensure proper content scaling.
- Added function to make sure only 1 instance of the script will run at a time.
- Added second display check after displays have been reset.
- Second check will log ("SUCCESS" or "FAILED") the result of the screen reset in the Error log.
- Added DVD_HD1 input support for NEC
- Added sleeps where sleeps were missing and were needed.
- Added script message and exit when finding an unknown input in the XML.
- Added the abilty to turn on or turn off the displays using an argument.  For example
    .\DisplayMonitoring TurnOn
###############################################################################################################>

<#############################################################################################################
Version 4 Major Changes:
- Compatible with PShell version 2.x
- Re-arranged functions and IF checks to be congruent with DisplayDetect.  Always NEC first, then SAM, then LG.
###############################################################################################################>

# All Functions below this line

filter timestamp {"$(Get-Date -Format G): $_"}

function NECon
{

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one

    [Byte[]] $PowerOnAll = 0x01,0x30,0x2A,0x30,0x41,0x30,0x43,0x02,0x43,0x32,0x30,0x33,0x44,0x36,0x30,0x30,0x30,0x31,0x03,0x18,0x0D

    $time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"

    $port.open()
    start-sleep -m 2000
    $port.Write($PowerOnAll, 0, $PowerOnAll.count)	#broadcast turn all screens on
    start-sleep -m 2000
    $port.Close()

    if ($args[3] -eq "NoLog")
        {
            write-host "Screens were turned on."
        }
    else
        {
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "$time" | out-file -append "$history_log"
            write-output "Working Hours - $OnTime - $OffTime" | out-file -append "$history_log"
            write-output "Days Off - $DaysOff" | out-file -append "$history_log"
            write-output "Good morning!  It is time for the displays to turn on." | out-file -append "$history_log"
            write-output "Commands to turn on the displays have been sent." | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

            OffHoursStatusCheck
        }

    #restart Content Player to make sure Content displays properly
    start-sleep -s 30
    RestartCP

    DisableLock
    Exit

} #end of function

function SAMon
{
    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
    $COUNT = $args[2]

    [Byte[]] $PowerOn1 = 0xAA,0x11,0x01,0x01,0x01,0x14
    [Byte[]] $PowerOn2 = 0xAA,0x11,0x02,0x01,0x01,0x15
    [Byte[]] $PowerOn3 = 0xAA,0x11,0x03,0x01,0x01,0x16
    [Byte[]] $PowerOn4 = 0xAA,0x11,0x04,0x01,0x01,0x17
    [Byte[]] $PowerOn5 = 0xAA,0x11,0x05,0x01,0x01,0x18
    [Byte[]] $PowerOn6 = 0xAA,0x11,0x06,0x01,0x01,0x19
    [Byte[]] $PowerOn7 = 0xAA,0x11,0x07,0x01,0x01,0x1A
    [Byte[]] $PowerOn8 = 0xAA,0x11,0x08,0x01,0x01,0x1B
    [Byte[]] $PowerOn9 = 0xAA,0x11,0x09,0x01,0x01,0x1C
    [Byte[]] $PowerOn10 = 0xAA,0x11,0x0A,0x01,0x01,0x1D
    [Byte[]] $PowerOn11 = 0xAA,0x11,0x0B,0x01,0x01,0x1E
    [Byte[]] $PowerOn12 = 0xAA,0x11,0x0C,0x01,0x01,0x1F
    [Byte[]] $PowerOn13 = 0xAA,0x11,0x0D,0x01,0x01,0x20
    [Byte[]] $PowerOn14 = 0xAA,0x11,0x0E,0x01,0x01,0x21
    [Byte[]] $PowerOn15 = 0xAA,0x11,0x0F,0x01,0x01,0x22
    [Byte[]] $PowerOn16 = 0xAA,0x11,0x10,0x01,0x01,0x23
    [Byte[]] $PowerOn17 = 0xAA,0x11,0x11,0x01,0x01,0x24
    [Byte[]] $PowerOn18 = 0xAA,0x11,0x12,0x01,0x01,0x25
    [Byte[]] $PowerOn19 = 0xAA,0x11,0x13,0x01,0x01,0x26
    [Byte[]] $PowerOn20 = 0xAA,0x11,0x14,0x01,0x01,0x27

    $placeholder = "placeholder"

    $poweron_array = $placeholder,$PowerOn1,$PowerOn2,$PowerOn3,$PowerOn4,$PowerOn5,$PowerOn6,$PowerOn7,$PowerOn8,$PowerOn9,$PowerOn10,$PowerOn11,$PowerOn12,$PowerOn13,$PowerOn14,$PowerOn15,$PowerOn16,$PowerOn17,$PowerOn18,$PowerOn19,$PowerOn20

    $time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"

    $i = 1

        $port.open()
        start-sleep -m 2000

    for ($i = 1; $i -le $COUNT; $i++)
    
        {
        $port.Write($poweron_array[$i], 0, $poweron_array[$i].Count)	
        start-sleep -m 2000
        }

        $port.close()

    if ($args[3] -eq "NoLog")
        {
            write-host "Screens were turned on."
        }
    else
        {
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "$time" | out-file -append "$history_log"
            write-output "Working Hours - $OnTime - $OffTime" | out-file -append "$history_log"
            write-output "Days Off - $DaysOff" | out-file -append "$history_log"
            write-output "Good morning!  It is time for the displays to turn on." | out-file -append "$history_log"
            write-output "Commands to turn on the displays have been sent." | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

            OffHoursStatusCheck
        }

    #restart Content Player to make sure Content displays properly
    start-sleep -s 30
    RestartCP

    DisableLock
    Exit

} #end of function

function LGon
{

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one

    $time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"

    $port.open()
    start-sleep -m 2000
    $port.WriteLine("ka 00 01")	#broadcast turn all screens on
    start-sleep -m 2000
    $port.Close()

    if ($args[3] -eq "NoLog")
        {
            write-host "Screens were turned on."
        }
    else
        {
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "$time" | out-file -append "$history_log"
            write-output "Working Hours - $OnTime - $OffTime" | out-file -append "$history_log"
            write-output "Days Off - $DaysOff" | out-file -append "$history_log"
            write-output "Good morning!  It is time for the displays to turn on." | out-file -append "$history_log"
            write-output "Commands to turn on the displays have been sent." | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

            OffHoursStatusCheck
        }

    #restart Content Player to make sure Content displays properly
    start-sleep -s 30
    RestartCP

    DisableLock
    Exit

} #end of function

function NECoff
{

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one

    [Byte[]] $PowerOffAll = 0x01,0x30,0x2A,0x30,0x41,0x30,0x43,0x02,0x43,0x32,0x30,0x33,0x44,0x36,0x30,0x30,0x30,0x34,0x03,0x1D,0x0D

    $time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"

    $port.open()
    start-sleep -m 2000
    $port.Write($PowerOffAll, 0, $PowerOffAll.count)	#broadcast turn all screens off
    start-sleep -m 2000
    $port.Close()

    if      ($args[3] -eq "NoLog")
        {
            write-host "Screens were turned off."
        }
    elseif  ($args[3] -eq "Fix")
        {
            OffHoursStatusCheck
        }
    else
        {
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "$time" | out-file -append "$history_log"
            write-output "Working Hours - $OnTime - $OffTime" | out-file -append "$history_log"
            write-output "Days Off - $DaysOff" | out-file -append "$history_log"
            write-output "Good night...  It is time for the displays to turn off." | out-file -append "$history_log"
            write-output "Commands to turn off the displays have been sent." | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

            OffHoursStatusCheck
        }

    DisableLock
    Exit

} #end of function

function SAMoff
{

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
    $COUNT = $args[2]

    [Byte[]] $PowerOff1 = 0xAA,0x11,0x01,0x01,0x00,0x13
    [Byte[]] $PowerOff2 = 0xAA,0x11,0x02,0x01,0x00,0x14
    [Byte[]] $PowerOff3 = 0xAA,0x11,0x03,0x01,0x00,0x15
    [Byte[]] $PowerOff4 = 0xAA,0x11,0x04,0x01,0x00,0x16
    [Byte[]] $PowerOff5 = 0xAA,0x11,0x05,0x01,0x00,0x17
    [Byte[]] $PowerOff6 = 0xAA,0x11,0x06,0x01,0x00,0x18
    [Byte[]] $PowerOff7 = 0xAA,0x11,0x07,0x01,0x00,0x19
    [Byte[]] $PowerOff8 = 0xAA,0x11,0x08,0x01,0x00,0x1A
    [Byte[]] $PowerOff9 = 0xAA,0x11,0x09,0x01,0x00,0x1B
    [Byte[]] $PowerOff10 = 0xAA,0x11,0x0A,0x01,0x00,0x1C
    [Byte[]] $PowerOff11 = 0xAA,0x11,0x0B,0x01,0x00,0x1D
    [Byte[]] $PowerOff12 = 0xAA,0x11,0x0C,0x01,0x00,0x1E
    [Byte[]] $PowerOff13 = 0xAA,0x11,0x0D,0x01,0x00,0x1F
    [Byte[]] $PowerOff14 = 0xAA,0x11,0x0E,0x01,0x00,0x20
    [Byte[]] $PowerOff15 = 0xAA,0x11,0x0F,0x01,0x00,0x21
    [Byte[]] $PowerOff16 = 0xAA,0x11,0x10,0x01,0x00,0x22
    [Byte[]] $PowerOff17 = 0xAA,0x11,0x11,0x01,0x00,0x23
    [Byte[]] $PowerOff18 = 0xAA,0x11,0x12,0x01,0x00,0x24
    [Byte[]] $PowerOff19 = 0xAA,0x11,0x13,0x01,0x00,0x25
    [Byte[]] $PowerOff20 = 0xAA,0x11,0x14,0x01,0x00,0x26

    $placeholder = "placeholder"

    $poweroff_array = $placeholder,$PowerOff1,$PowerOff2,$PowerOff3,$PowerOff4,$PowerOff5,$PowerOff6,$PowerOff7,$PowerOff8,$PowerOff9,$PowerOff10,$PowerOff11,$PowerOff12,$PowerOff13,$PowerOff14,$PowerOff15,$PowerOff16,$PowerOff17,$PowerOff18,$PowerOff19,$PowerOff20

    $time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"

    $i = 1

        $port.open()
        start-sleep -m 2000

    for ($i = 1; $i -le $COUNT; $i++)
    
        {
        $port.Write($poweroff_array[$i], 0, $poweroff_array[$i].Count)	
        start-sleep -m 2000
        }

        $port.close()

    if      ($args[3] -eq "NoLog")
        {
            write-host "Screens were turned off."
        }
    elseif  ($args[3] -eq "Fix")
        {
            OffHoursStatusCheck
        }
    else
        {
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "$time" | out-file -append "$history_log"
            write-output "Working Hours - $OnTime - $OffTime" | out-file -append "$history_log"
            write-output "Days Off - $DaysOff" | out-file -append "$history_log"
            write-output "Good night...  It is time for the displays to turn off." | out-file -append "$history_log"
            write-output "Commands to turn off the displays have been sent." | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

            OffHoursStatusCheck
        }

    DisableLock
    Exit

} #end of function

function LGoff
{

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one

    $time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"

    $port.open()
    start-sleep -m 2000
    $port.WriteLine("ka 00 00")	# broadcast turn all screens off
    start-sleep -m 2000
    $port.Close()

    if      ($args[3] -eq "NoLog")
        {
            write-host "Screens were turned off."
        }
    elseif  ($args[3] -eq "Fix")
        {
            OffHoursStatusCheck
        }
    else
        {
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "$time" | out-file -append "$history_log"
            write-output "Working Hours - $OnTime - $OffTime" | out-file -append "$history_log"
            write-output "Days Off - $DaysOff" | out-file -append "$history_log"
            write-output "Good night...  It is time for the displays to turn off." | out-file -append "$history_log"
            write-output "Commands to turn off the displays have been sent." | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

            OffHoursStatusCheck
        }

    DisableLock
    Exit

} #end of function

function NECcheck
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
    $COUNT = $args[2]

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

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20

    $global:screen_status = "Good"
        
    $global:reset_displays = "no"

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

    $i = 1

	#done with the main variables

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){

                        #setting variables based on arguments given to script

                        if 		($INPT[$i] -eq "HDMI")		{$input_expected = 48,48,49,49; $input_expected_english = "HDMI"}
						elseif 	($INPT[$i] -eq "DP")        {$input_expected = 48,48,48,70; $input_expected_english = "Display Port"}
						elseif 	($INPT[$i] -eq "DVI")		{$input_expected = 48,48,48,51; $input_expected_english = "DVI"}
						elseif 	($INPT[$i] -eq "DVD_HD1")   {$input_expected = 48,48,49,50; $input_expected_english = "DVD_HD1 (HDMI)"}
                        else							    {$input_expected = "Unknown"; $input_expected_english = "Unknown"}

                        $power_expected = 48,48,48,49
                    
                                  #opening port and checking input and power for screens
                        
                            $port.open()

                                start-sleep -m 2000
                                $port.Write($power_array[$i], 0, $power_array[$i].Count)	#check power status
                                start-sleep -m 2000
                                $power_temp = $port.ReadExisting()
                                start-sleep -m 2000
                                $power_return = [System.Text.Encoding]::UTF8.GetBytes($power_temp)
                                start-sleep -m 2000
                                $port.Write($input_array[$i], 0, $input_array[$i].Count)	#check input
                                start-sleep -m 2000
                                $input_temp = $port.ReadExisting()
                                start-sleep -m 2000
                                $input_return = [System.Text.Encoding]::UTF8.GetBytes($input_temp)
                                start-sleep -m 2000

                            $port.Close()
                            start-sleep -m 2000

                        $input_return_short = $input_return[20],$input_return[21],$input_return[22],$input_return[23]
                        $power_return_short = $power_return[20],$power_return[21],$power_return[22],$power_return[23]
                    

                                #comparing returned values to what we expect
                                if ($power_return_short[0] -eq 48 -and $power_return_short[1] -eq 48 -and $power_return_short[2] -eq 48 -and $power_return_short[3] -eq 52) {$PowerIsOff = "True"}
                                
                                if ($power_temp -eq "")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM did not receive any response from the display." | out-file -append "$error_log"
                                    write-output "FWIRMM will make an attempt to power on the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($PowerIsOff -eq "True")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM has detected that the display is powered off." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power on the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return_short[0] -ne $power_expected[0] -or $power_return_short[1] -ne $power_expected[1] -or $power_return_short[2] -ne $power_expected[2] -or $power_return_short[3] -ne $power_expected[3] -and $power_temp -ne "" -and $PowerIsOff -ne "True")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM has detected that the display is in an unknown power state." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power on the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }    

                                if ($input_return_short[0] -ne $input_expected[0] -or $input_return_short[1] -ne $input_expected[1] -or $input_return_short[2] -ne $input_expected[2] -or $input_return_short[3] -ne $input_expected[3] -and $power_temp -ne "" -and $PowerIsOff -ne "True")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
    
                                    if 		($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 49 -and $input_return_short[3] -eq 49)	{$input_return_english = "HDMI"}
                                    elseif 	($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 48 -and $input_return_short[3] -eq 70)	{$input_return_english = "Display Port"}
                                    elseif 	($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 48 -and $input_return_short[3] -eq 51)	{$input_return_english = "DVI"}
                                    elseif 	($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 49 -and $input_return_short[3] -eq 50)	{$input_return_english = "DVD_HD1 (HDMI)"}
                                    else 									                                                                                                            {$input_return_english = "Unknown"}
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM has detected that the display is set to the wrong input ($input_return_english)." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to reset the display to the correct input ($input_expected_english)." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }
                              
                                #writing log information
    
                                write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check" | out-file -append "$history_log"    
                                write-output "$time" | out-file -append "$history_log"
                                write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
                                write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
                                write-output "Power Status Returned - $power_return_short" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
                                write-output "Input Status Expected - $input_expected" | out-file -append "$history_log"
                                write-output "Input Status Returned - $input_return_short" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
                                write-output "Screen Status - $screen_status" | out-file -append "$history_log"

                    } #end of "for loop"

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "Reset Displays? - $reset_displays" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

} #end of function

function SAMcheck
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
    $COUNT = $args[2]

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

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20

    $global:screen_status = "Good"
        
    $global:reset_displays = "no"

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

    $i = 1

    #done with the main variables
    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){
					
                        #setting variables based on arguments given to script
                        
                        if 		($INPT[$i] -eq "HDMI")		{$input_expected = 33; $input_expected_english = "HDMI"}
                        elseif 	($INPT[$i] -eq "HDMI_PC")	{$input_expected = 34; $input_expected_english = "HDMI_PC"}
						elseif 	($INPT[$i] -eq "HDMI2")	    {$input_expected = 35; $input_expected_english = "HDMI2"}
						elseif 	($INPT[$i] -eq "HDMI2_PC")	{$input_expected = 36; $input_expected_english = "HDMI2_PC"}
						elseif 	($INPT[$i] -eq "DP")        {$input_expected = 37; $input_expected_english = "Display Port"}
						elseif 	($INPT[$i] -eq "DVI")		{$input_expected = 24; $input_expected_english = "DVI"}
                        elseif 	($INPT[$i] -eq "DVI_video") {$input_expected = 31; $input_expected_english = "DVI_video"}
                        elseif 	($INPT[$i] -eq "VGA")       {$input_expected = 20; $input_expected_english = "VGA"}
                        else							    {$input_expected = "Unknown"; $input_expected_english = "Unknown"}
                        
                        $power_expected = 1
    
                                #opening port and checking input and power for screens
                        
                                $port.open()
                                    start-sleep -m 2000
                                    $port.Write($power_array[$i], 0, $power_array[$i].Count)	#check power status
                                    start-sleep -m 2000
                                    $power_temp = $port.ReadExisting()
                                    start-sleep -m 2000
                                    $power_return = [System.Text.Encoding]::UTF8.GetBytes($power_temp)
                                    start-sleep -m 2000
                                    $port.Write($input_array[$i], 0, $input_array[$i].Count)	#check input
                                    start-sleep -m 2000
                                    $input_temp = $port.ReadExisting()
                                    start-sleep -m 2000
                                    $input_return = [System.Text.Encoding]::UTF8.GetBytes($input_temp)
                                    start-sleep -m 2000                                    
                                $port.Close()
                                
                                #comparing returned values to what we expect
                                
                                if ($power_temp -eq "")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM did not receive any response from the display." | out-file -append "$error_log"
                                    write-output "FWIRMM will make an attempt to power on the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }


                                if ($power_return[6] -eq 0)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM has detected that the display is powered off." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power on the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return[6] -ne $power_expected -and $power_temp -ne "" -and $power_return[6] -ne 0)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM has detected that the display is in an unknown power state." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power on the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }


                                if ($input_return[6] -ne $input_expected -and $power_temp -ne "" -and $power_return[6] -ne 0)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
    
                                    if 		($input_return[6] -eq 33)		{$input_return_english = "HDMI"}
                                    elseif 	($input_return[6] -eq 36)		{$input_return_english = "HDMI 2"}
                                    elseif 	($input_return[6] -eq 37)		{$input_return_english = "Display Port"}
                                    elseif 	($input_return[6] -eq 31)		{$input_return_english = "DVI"}
                                    elseif 	($input_return[6] -eq 20)		{$input_return_english = "VGA"}
                                    else 									{$input_return_english = "Unknown"}
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM has detected that the display is set to the wrong input ($input_return_english)." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to reset the display to the correct input ($input_expected_english)." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }
        
                                #writing log information
    
								write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check" | out-file -append "$history_log"    
								write-output "$time" | out-file -append "$history_log"
								write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
								write-output "Power Status Returned - $($power_return[6])" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Input Status Expected - $input_expected" | out-file -append "$history_log"
								write-output "Input Status Returned - $($input_return[6])" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Screen Status - $screen_status" | out-file -append "$history_log"

    
                    }#end of "for loop"

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "Reset Displays? - $reset_displays" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

} #end of function

function LGcheck
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
    $COUNT = $args[2]
    
    $chkPower1 = "ka 01 ff"
    $chkPower2 = "ka 02 ff"
    $chkPower3 = "ka 03 ff"
    $chkPower4 = "ka 04 ff"
    $chkPower5 = "ka 05 ff"
    $chkPower6 = "ka 06 ff"
    $chkPower7 = "ka 07 ff"
    $chkPower8 = "ka 08 ff"
    $chkPower9 = "ka 09 ff"
    $chkPower10 = "ka 10 ff"
    $chkPower11 = "ka 11 ff"
    $chkPower12 = "ka 12 ff"
    $chkPower13 = "ka 13 ff"
    $chkPower14 = "ka 14 ff"
    $chkPower15 = "ka 15 ff"
    $chkPower16 = "ka 16 ff"
    $chkPower17 = "ka 17 ff"
    $chkPower18 = "ka 18 ff"
    $chkPower19 = "ka 19 ff"
    $chkPower20 = "ka 20 ff"

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

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20

    $global:screen_status = "Good"
	
	$global:reset_displays = "no"



	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

	$i = 1
	
	#done with the main variables
    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){
					
					#setting variables based on arguments given to script
					if 		($INPT[$i] -eq "HDMI")		{$input_expected = "b 0"+$i+" OK90x"; $input_expected_english = "HDMI"}
					elseif 	($INPT[$i] -eq "HDMI1")	    {$input_expected = "b 0"+$i+" OKa0x"; $input_expected_english = "HDMI 1"}
					elseif 	($INPT[$i] -eq "HDMI2")	    {$input_expected = "b 0"+$i+" OKa1x"; $input_expected_english = "HDMI 2"}
                    elseif 	($INPT[$i] -eq "DP_PC")     {$input_expected = "b 0"+$i+" OKd0x"; $input_expected_english = "Display Port PC"}
					elseif 	($INPT[$i] -eq "DP_DTV")    {$input_expected = "b 0"+$i+" OKc0x"; $input_expected_english = "Display Port DTV"}
					elseif 	($INPT[$i] -eq "DVI")       {$input_expected = "b 0"+$i+" OK70x"; $input_expected_english = "DVI"}
					else							    {$input_expected = "Unknown"; $input_expected_english = "Unknown"}
					
					$power_expected = "a 0"+$i+" OK01x"

							#opening port and checking input and power for screens
					
							$port.open()
                            start-sleep -m 2000
                            $port.WriteLine($power_array[$i])	#check power status
                            start-sleep -m 2000
                            $power_return = $port.ReadExisting()
                            start-sleep -m 2000
                            $port.WriteLine($input_array[$i])	#check input
                            start-sleep -m 2000
                            $input_return = $port.ReadExisting()
                            start-sleep -m 2000
							$port.Close()
							
							#comparing returned values to what we expect

                            if ($power_return -eq "")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
                                write-output "FWIRMM did not receive any response from the display." | out-file -append "$error_log"
								write-output "FWIRMM will make an attempt to power on the display." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }
							
							if ($power_return -eq "a 0"+$i+" OK00x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
								write-output "FWIRMM has detected that the display is powered off." | out-file -append "$error_log"
								write-output "FWIRMM will attempt to power on the display." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }

                            if ($power_return -ne $power_expected -and $power_return -ne "" -and $power_return -ne "a 0"+$i+" OK00x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
								write-output "FWIRMM has detected that the display is in an unknown power state." | out-file -append "$error_log"
								write-output "FWIRMM will attempt to power on the display." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }

                                
							if ($input_return -ne $input_expected -and $power_return -ne "" -and $power_return -ne "a 0"+$i+" OK00x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								if 		($input_return -eq "b 0"+$i+" OK90x")		{$input_return_english = "HDMI"}
								elseif 	($input_return -eq "b 0"+$i+" OKa0x")		{$input_return_english = "HDMI 1"}
								elseif 	($input_return -eq "b 0"+$i+" OKa1x")		{$input_return_english = "HDMI 2"}
								elseif 	($input_return -eq "b 0"+$i+" OKd0x")		{$input_return_english = "Display Port"}
								elseif 	($input_return -eq "b 0"+$i+" OK70x")		{$input_return_english = "DVI"}
								else 												{$input_return_english = "Unknown"}

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
								write-output "FWIRMM has detected that the display is set to the wrong input ($input_return_english)." | out-file -append "$error_log"
								write-output "FWIRMM will attempt to reset the display to the correct input ($input_expected_english)." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
								}

							#writing log information

								write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check" | out-file -append "$history_log"    
								write-output "$time" | out-file -append "$history_log"
								write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
								write-output "Power Status Returned - $power_return" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Input Status Expected - $input_expected" | out-file -append "$history_log"
								write-output "Input Status Returned - $input_return" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Screen Status - $screen_status" | out-file -append "$history_log"

							#end of "for loop"
                    }
                    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "Reset Displays? - $reset_displays" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

} #end of function

function NECfix
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one    
	$INPT = $args[1]
	$COUNT = $args[2]

    [Byte[]] $PowerOnAll = 0x01,0x30,0x2A,0x30,0x41,0x30,0x43,0x02,0x43,0x32,0x30,0x33,0x44,0x36,0x30,0x30,0x30,0x31,0x03,0x18,0x0D

    $port.open()
    start-sleep -m 2000
    $port.Write($PowerOnAll, 0, $PowerOnAll.count)	#broadcast turn all screens on
    start-sleep -m 2000
    $port.Close()

    start-sleep -m 2000

    $i = 1

    for ($i = 1; $i -le $COUNT; $i++) 
    
    {

        if ($INPT[$i] -eq "HDMI")
            
        {
            
            [Byte[]] $SetInputAll = 0x01,0x30,0x2A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x19,0x0D
            [Byte[]] $SetInput1 = 0x01,0x30,0x41,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x72,0x0D
            [Byte[]] $SetInput2 = 0x01,0x30,0x42,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x71,0x0D
            [Byte[]] $SetInput3 = 0x01,0x30,0x43,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x70,0x0D
            [Byte[]] $SetInput4 = 0x01,0x30,0x44,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x77,0x0D
            [Byte[]] $SetInput5 = 0x01,0x30,0x45,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x76,0x0D
            [Byte[]] $SetInput6 = 0x01,0x30,0x46,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x75,0x0D
            [Byte[]] $SetInput7 = 0x01,0x30,0x47,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x74,0x0D
            [Byte[]] $SetInput8 = 0x01,0x30,0x48,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x7B,0x0D
            [Byte[]] $SetInput9 = 0x01,0x30,0x49,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x7A,0x0D
            [Byte[]] $SetInput10 = 0x01,0x30,0x4A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x79,0x0D
            [Byte[]] $SetInput11 = 0x01,0x30,0x4B,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x78,0x0D
            [Byte[]] $SetInput12 = 0x01,0x30,0x4C,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x7F,0x0D
            [Byte[]] $SetInput13 = 0x01,0x30,0x4D,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x7E,0x0D
            [Byte[]] $SetInput14 = 0x01,0x30,0x4E,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x7D,0x0D
            [Byte[]] $SetInput15 = 0x01,0x30,0x4F,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x7C,0x0D
            [Byte[]] $SetInput16 = 0x01,0x30,0x50,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x63,0x0D
            [Byte[]] $SetInput17 = 0x01,0x30,0x51,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x62,0x0D
            [Byte[]] $SetInput18 = 0x01,0x30,0x52,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x61,0x0D
            [Byte[]] $SetInput19 = 0x01,0x30,0x53,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x60,0x0D
            [Byte[]] $SetInput20 = 0x01,0x30,0x54,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x31,0x03,0x67,0x0D

        }

        elseif ($INPT[$i] -eq "DP")
            
        {

            [Byte[]] $SetInputAll = 0x01,0x30,0x2A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x6F,0x0D
            [Byte[]] $SetInput1 = 0x01,0x30,0x41,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x04,0x0D
            [Byte[]] $SetInput2 = 0x01,0x30,0x42,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x07,0x0D
            [Byte[]] $SetInput3 = 0x01,0x30,0x43,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x06,0x0D
            [Byte[]] $SetInput4 = 0x01,0x30,0x44,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x01,0x0D
            [Byte[]] $SetInput5 = 0x01,0x30,0x45,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x00,0x0D
            [Byte[]] $SetInput6 = 0x01,0x30,0x46,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x03,0x0D
            [Byte[]] $SetInput7 = 0x01,0x30,0x47,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x02,0x0D
            [Byte[]] $SetInput8 = 0x01,0x30,0x48,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x0D,0x0D
            [Byte[]] $SetInput9 = 0x01,0x30,0x49,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x0C,0x0D
            [Byte[]] $SetInput10 = 0x01,0x30,0x4A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x0F,0x0D
            [Byte[]] $SetInput11 = 0x01,0x30,0x4B,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x0E,0x0D
            [Byte[]] $SetInput12 = 0x01,0x30,0x4C,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x09,0x0D
            [Byte[]] $SetInput13 = 0x01,0x30,0x4D,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x08,0x0D
            [Byte[]] $SetInput14 = 0x01,0x30,0x4E,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x0B,0x0D
            [Byte[]] $SetInput15 = 0x01,0x30,0x4F,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x0A,0x0D
            [Byte[]] $SetInput16 = 0x01,0x30,0x50,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x15,0x0D
            [Byte[]] $SetInput17 = 0x01,0x30,0x51,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x14,0x0D
            [Byte[]] $SetInput18 = 0x01,0x30,0x52,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x17,0x0D
            [Byte[]] $SetInput19 = 0x01,0x30,0x53,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x16,0x0D
            [Byte[]] $SetInput20 = 0x01,0x30,0x54,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x46,0x03,0x11,0x0D

        }

        elseif ($INPT[$i] -eq "DVI")
            
        {

            [Byte[]] $SetInputAll = 0x01,0x30,0x2A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x1B,0x0D
            [Byte[]] $SetInput1 = 0x01,0x30,0x41,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x70,0x0D
            [Byte[]] $SetInput2 = 0x01,0x30,0x42,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x73,0x0D
            [Byte[]] $SetInput3 = 0x01,0x30,0x43,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x72,0x0D
            [Byte[]] $SetInput4 = 0x01,0x30,0x44,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x75,0x0D
            [Byte[]] $SetInput5 = 0x01,0x30,0x45,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x74,0x0D
            [Byte[]] $SetInput6 = 0x01,0x30,0x46,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x77,0x0D
            [Byte[]] $SetInput7 = 0x01,0x30,0x47,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x76,0x0D
            [Byte[]] $SetInput8 = 0x01,0x30,0x48,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x79,0x0D
            [Byte[]] $SetInput9 = 0x01,0x30,0x49,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x78,0x0D
            [Byte[]] $SetInput10 = 0x01,0x30,0x4A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x7B,0x0D
            [Byte[]] $SetInput11 = 0x01,0x30,0x4B,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x7A,0x0D
            [Byte[]] $SetInput12 = 0x01,0x30,0x4C,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x7D,0x0D
            [Byte[]] $SetInput13 = 0x01,0x30,0x4D,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x7C,0x0D
            [Byte[]] $SetInput14 = 0x01,0x30,0x4E,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x7F,0x0D
            [Byte[]] $SetInput15 = 0x01,0x30,0x4F,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x7E,0x0D
            [Byte[]] $SetInput16 = 0x01,0x30,0x50,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x61,0x0D
            [Byte[]] $SetInput17 = 0x01,0x30,0x51,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x60,0x0D
            [Byte[]] $SetInput18 = 0x01,0x30,0x52,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x63,0x0D
            [Byte[]] $SetInput19 = 0x01,0x30,0x53,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x62,0x0D
            [Byte[]] $SetInput20 = 0x01,0x30,0x54,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x31,0x33,0x03,0x65,0x0D

        }

                elseif ($INPT[$i] -eq "DVD_HD1")
            
        {

            [Byte[]] $SetInputAll = 0x01,0x30,0x2A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x6A,0x0D
            [Byte[]] $SetInput1 = 0x01,0x30,0x41,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x01,0x0D
            [Byte[]] $SetInput2 = 0x01,0x30,0x42,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x02,0x0D
            [Byte[]] $SetInput3 = 0x01,0x30,0x43,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x03,0x0D
            [Byte[]] $SetInput4 = 0x01,0x30,0x44,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x04,0x0D
            [Byte[]] $SetInput5 = 0x01,0x30,0x45,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x05,0x0D
            [Byte[]] $SetInput6 = 0x01,0x30,0x46,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x06,0x0D
            [Byte[]] $SetInput7 = 0x01,0x30,0x47,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x07,0x0D
            [Byte[]] $SetInput8 = 0x01,0x30,0x48,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x08,0x0D
            [Byte[]] $SetInput9 = 0x01,0x30,0x49,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x09,0x0D
            [Byte[]] $SetInput10 = 0x01,0x30,0x4A,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x0A,0x0D
            [Byte[]] $SetInput11 = 0x01,0x30,0x4B,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x0B,0x0D
            [Byte[]] $SetInput12 = 0x01,0x30,0x4C,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x0C,0x0D
            [Byte[]] $SetInput13 = 0x01,0x30,0x4D,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x0D,0x0D
            [Byte[]] $SetInput14 = 0x01,0x30,0x4E,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x0E,0x0D
            [Byte[]] $SetInput15 = 0x01,0x30,0x4F,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x0F,0x0D
            [Byte[]] $SetInput16 = 0x01,0x30,0x50,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x10,0x0D
            [Byte[]] $SetInput17 = 0x01,0x30,0x51,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x11,0x0D
            [Byte[]] $SetInput18 = 0x01,0x30,0x52,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x12,0x0D
            [Byte[]] $SetInput19 = 0x01,0x30,0x53,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x13,0x0D
            [Byte[]] $SetInput20 = 0x01,0x30,0x54,0x30,0x45,0x30,0x41,0x02,0x30,0x30,0x36,0x30,0x30,0x30,0x30,0x43,0x03,0x14,0x0D

        }


        $placeholder = "placeholder"
        $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20

        $port.open()
        start-sleep -m 2000
        $port.Write($changeinput_array[$i], 0, $changeinput_array[$i].count)
        start-sleep -m 2000
        $port.Close()
        start-sleep -m 2000

    }

} #end of function

function SAMfix
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one    
	$INPT = $args[1]
	$COUNT = $args[2]
        
    $i = 1

            for ($i = 1; $i -le $COUNT; $i++) 
            
            {

            [Byte[]] $PowerOn1 = 0xAA,0x11,0x01,0x01,0x01,0x14
            [Byte[]] $PowerOn2 = 0xAA,0x11,0x02,0x01,0x01,0x15
            [Byte[]] $PowerOn3 = 0xAA,0x11,0x03,0x01,0x01,0x16
            [Byte[]] $PowerOn4 = 0xAA,0x11,0x04,0x01,0x01,0x17
            [Byte[]] $PowerOn5 = 0xAA,0x11,0x05,0x01,0x01,0x18
            [Byte[]] $PowerOn6 = 0xAA,0x11,0x06,0x01,0x01,0x19
            [Byte[]] $PowerOn7 = 0xAA,0x11,0x07,0x01,0x01,0x1A
            [Byte[]] $PowerOn8 = 0xAA,0x11,0x08,0x01,0x01,0x1B
            [Byte[]] $PowerOn9 = 0xAA,0x11,0x09,0x01,0x01,0x1C
            [Byte[]] $PowerOn10 = 0xAA,0x11,0x0A,0x01,0x01,0x1D
            [Byte[]] $PowerOn11 = 0xAA,0x11,0x0B,0x01,0x01,0x1E
            [Byte[]] $PowerOn12 = 0xAA,0x11,0x0C,0x01,0x01,0x1F
            [Byte[]] $PowerOn13 = 0xAA,0x11,0x0D,0x01,0x01,0x20
            [Byte[]] $PowerOn14 = 0xAA,0x11,0x0E,0x01,0x01,0x21
            [Byte[]] $PowerOn15 = 0xAA,0x11,0x0F,0x01,0x01,0x22
            [Byte[]] $PowerOn16 = 0xAA,0x11,0x10,0x01,0x01,0x23
            [Byte[]] $PowerOn17 = 0xAA,0x11,0x11,0x01,0x01,0x24
            [Byte[]] $PowerOn18 = 0xAA,0x11,0x12,0x01,0x01,0x25
            [Byte[]] $PowerOn19 = 0xAA,0x11,0x13,0x01,0x01,0x26
            [Byte[]] $PowerOn20 = 0xAA,0x11,0x14,0x01,0x01,0x27


            if ($INPT[$i] -eq "HDMI")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x21,0x37
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x21,0x38
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x21,0x39
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x21,0x3A
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x21,0x3B
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x21,0x3C
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x21,0x3D
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x21,0x3E
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x21,0x3F
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x21,0x40
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x21,0x41
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x21,0x42
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x21,0x43
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x21,0x44
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x21,0x45
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x21,0x46
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x21,0x47
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x21,0x48
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x21,0x49
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x21,0x4A

                }

            elseif ($INPT[$i] -eq "HDMI_PC")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x21,0x37
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x21,0x38
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x21,0x39
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x21,0x3A
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x21,0x3B
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x21,0x3C
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x21,0x3D
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x21,0x3E
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x21,0x3F
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x21,0x40
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x21,0x41
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x21,0x42
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x21,0x43
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x21,0x44
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x21,0x45
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x21,0x46
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x21,0x47
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x21,0x48
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x21,0x49
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x21,0x4A

                    <# HDMI_PC original codes - tested and did not work, must use HDMI codes to reset screen to HDMI_PC
                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x22,0x38
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x22,0x39
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x22,0x3A
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x22,0x3B
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x22,0x3C
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x22,0x3D
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x22,0x3E
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x22,0x3F
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x22,0x40
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x22,0x41
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x22,0x42
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x22,0x43
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x22,0x44
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x22,0x45
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x22,0x46
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x22,0x47
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x22,0x48
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x22,0x49
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x22,0x4A
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x22,0x4B
                    #>

                }

            elseif ($INPT[$i] -eq "HDMI2")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x23,0x39
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x23,0x3A
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x23,0x3B
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x23,0x3C
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x23,0x3D
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x23,0x3E
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x23,0x3F
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x23,0x40
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x23,0x41
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x23,0x42
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x23,0x43
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x23,0x44
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x23,0x45
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x23,0x46
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x23,0x47
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x23,0x48
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x23,0x49
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x23,0x4A
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x23,0x4B
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x23,0x4C

                }

            elseif ($INPT[$i] -eq "HDMI2_PC")
            
                {
                    
                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x23,0x39
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x23,0x3A
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x23,0x3B
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x23,0x3C
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x23,0x3D
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x23,0x3E
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x23,0x3F
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x23,0x40
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x23,0x41
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x23,0x42
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x23,0x43
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x23,0x44
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x23,0x45
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x23,0x46
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x23,0x47
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x23,0x48
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x23,0x49
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x23,0x4A
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x23,0x4B
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x23,0x4C

                    <# HDMI2_PC original codes - tested and did not work, must use HDMI2 codes to reset screen to HDMI2_PC
                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x24,0x3A
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x24,0x3B
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x24,0x3C
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x24,0x3D
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x24,0x3E
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x24,0x3F
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x24,0x40
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x24,0x41
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x24,0x42
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x24,0x43
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x24,0x44
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x24,0x45
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x24,0x46
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x24,0x47
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x24,0x48
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x24,0x49
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x24,0x4A
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x24,0x4B
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x24,0x4C
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x24,0x4D
                    #>

                }

            elseif ($INPT[$i] -eq "DP")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x25,0x3B
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x25,0x3C
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x25,0x3D
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x25,0x3E
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x25,0x3F
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x25,0x40
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x25,0x41
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x25,0x42
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x25,0x43
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x25,0x44
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x25,0x45
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x25,0x46
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x25,0x47
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x25,0x48
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x25,0x49
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x25,0x4A
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x25,0x4B
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x25,0x4C
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x25,0x4D
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x25,0x4E

                }

            elseif ($INPT[$i] -eq "DVI")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x18,0x2E
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x18,0x2F
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x18,0x30
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x18,0x31
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x18,0x32
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x18,0x33
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x18,0x34
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x18,0x35
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x18,0x36
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x18,0x37
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x18,0x38
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x18,0x39
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x18,0x3A
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x18,0x3B
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x18,0x3C
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x18,0x3D
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x18,0x3E
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x18,0x3F
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x18,0x40
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x18,0x41

                }

            elseif ($INPT[$i] -eq "DVI_video")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x1F,0x35
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x1F,0x36
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x1F,0x37
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x1F,0x38
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x1F,0x39
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x1F,0x3A
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x1F,0x3B
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x1F,0x3C
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x1F,0x3D
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x1F,0x3E
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x1F,0x3F
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x1F,0x40
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x1F,0x41
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x1F,0x42
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x1F,0x43
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x1F,0x44
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x1F,0x45
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x1F,0x46
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x1F,0x47
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x1F,0x48

                }

            elseif ($INPT[$i] -eq "VGA")
            
                {

                    [Byte[]] $SetInput1 = 0xAA,0x14,0x01,0x01,0x14,0x2A
                    [Byte[]] $SetInput2 = 0xAA,0x14,0x02,0x01,0x14,0x2B
                    [Byte[]] $SetInput3 = 0xAA,0x14,0x03,0x01,0x14,0x2C
                    [Byte[]] $SetInput4 = 0xAA,0x14,0x04,0x01,0x14,0x2D
                    [Byte[]] $SetInput5 = 0xAA,0x14,0x05,0x01,0x14,0x2E
                    [Byte[]] $SetInput6 = 0xAA,0x14,0x06,0x01,0x14,0x2F
                    [Byte[]] $SetInput7 = 0xAA,0x14,0x07,0x01,0x14,0x30
                    [Byte[]] $SetInput8 = 0xAA,0x14,0x08,0x01,0x14,0x31
                    [Byte[]] $SetInput9 = 0xAA,0x14,0x09,0x01,0x14,0x32
                    [Byte[]] $SetInput10 = 0xAA,0x14,0x0A,0x01,0x14,0x33
                    [Byte[]] $SetInput11 = 0xAA,0x14,0x0B,0x01,0x14,0x34
                    [Byte[]] $SetInput12 = 0xAA,0x14,0x0C,0x01,0x14,0x35
                    [Byte[]] $SetInput13 = 0xAA,0x14,0x0D,0x01,0x14,0x36
                    [Byte[]] $SetInput14 = 0xAA,0x14,0x0E,0x01,0x14,0x37
                    [Byte[]] $SetInput15 = 0xAA,0x14,0x0F,0x01,0x14,0x38
                    [Byte[]] $SetInput16 = 0xAA,0x14,0x10,0x01,0x14,0x39
                    [Byte[]] $SetInput17 = 0xAA,0x14,0x11,0x01,0x14,0x3A
                    [Byte[]] $SetInput18 = 0xAA,0x14,0x12,0x01,0x14,0x3B
                    [Byte[]] $SetInput19 = 0xAA,0x14,0x13,0x01,0x14,0x3C
                    [Byte[]] $SetInput20 = 0xAA,0x14,0x14,0x01,0x14,0x3D

                }

            $placeholder = "placeholder"

            $poweron_array = $placeholder,$PowerOn1,$PowerOn2,$PowerOn3,$PowerOn4,$PowerOn5,$PowerOn6,$PowerOn7,$PowerOn8,$PowerOn9,$PowerOn10,$PowerOn11,$PowerOn12,$PowerOn13,$PowerOn14,$PowerOn15,$PowerOn16,$PowerOn17,$PowerOn18,$PowerOn19,$PowerOn20

            $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20

                $port.open()
                start-sleep -m 2000
                $port.Write($poweron_array[$i], 0, $poweron_array[$i].Count)	
                start-sleep -m 2000
                $port.Write($changeinput_array[$i], 0, $changeinput_array[$i].Count)
                start-sleep -m 2000
                $port.close()
                start-sleep -m 2000

            }
        
} #end of function

function LGfix
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
	$COUNT = $args[2]

    #sending fix commands depending on input provided

    $port.open()
    start-sleep -m 2000
    $port.WriteLine("ka 00 01")	#broadcast turn all screens on
    start-sleep -m 2000
    $port.Close()
    
    start-sleep -m 2000

    $i = 1

    for ($i = 1; $i -le $COUNT; $i++) 
    
        {

			if      ($INPT[$i] -eq "HDMI")
				{
                    $SetInput1 = "xb 01 90"
                    $SetInput2 = "xb 02 90"
                    $SetInput3 = "xb 03 90"
                    $SetInput4 = "xb 04 90"
                    $SetInput5 = "xb 05 90"
                    $SetInput6 = "xb 06 90"
                    $SetInput7 = "xb 07 90"
                    $SetInput8 = "xb 08 90"
                    $SetInput9 = "xb 09 90"
                    $SetInput10 = "xb 10 90"
                    $SetInput11 = "xb 11 90"
                    $SetInput12 = "xb 12 90"
                    $SetInput13 = "xb 13 90"
                    $SetInput14 = "xb 14 90"
                    $SetInput15 = "xb 15 90"
                    $SetInput16 = "xb 16 90"
                    $SetInput17 = "xb 17 90"
                    $SetInput18 = "xb 18 90"
                    $SetInput19 = "xb 19 90"
                    $SetInput20 = "xb 20 90"

                    $placeholder = "placeholder"
                    $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20
        
                    $port.open()
                    start-sleep -m 2000
                    $port.WriteLine($changeinput_array[$i])	# set screen input to HDMI
                    start-sleep -m 2000
                    $port.Close()
                    start-sleep -m 2000
				}
			elseif  ($INPT[$i] -eq "HDMI1")
				{
                    $SetInput1 = "xb 01 a0"
                    $SetInput2 = "xb 02 a0"
                    $SetInput3 = "xb 03 a0"
                    $SetInput4 = "xb 04 a0"
                    $SetInput5 = "xb 05 a0"
                    $SetInput6 = "xb 06 a0"
                    $SetInput7 = "xb 07 a0"
                    $SetInput8 = "xb 08 a0"
                    $SetInput9 = "xb 09 a0"
                    $SetInput10 = "xb 10 a0"
                    $SetInput11 = "xb 11 a0"
                    $SetInput12 = "xb 12 a0"
                    $SetInput13 = "xb 13 a0"
                    $SetInput14 = "xb 14 a0"
                    $SetInput15 = "xb 15 a0"
                    $SetInput16 = "xb 16 a0"
                    $SetInput17 = "xb 17 a0"
                    $SetInput18 = "xb 18 a0"
                    $SetInput19 = "xb 19 a0"
                    $SetInput20 = "xb 20 a0"

                    $placeholder = "placeholder"
                    $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20
        
                    $port.open()
                    start-sleep -m 2000
                    $port.WriteLine($changeinput_array[$i])	# set screen input to HDMI1
                    start-sleep -m 2000
                    $port.Close()
                    start-sleep -m 2000
				}
			elseif  ($INPT[$i] -eq "HDMI2")
				{
                    $SetInput1 = "xb 01 a1"
                    $SetInput2 = "xb 02 a1"
                    $SetInput3 = "xb 03 a1"
                    $SetInput4 = "xb 04 a1"
                    $SetInput5 = "xb 05 a1"
                    $SetInput6 = "xb 06 a1"
                    $SetInput7 = "xb 07 a1"
                    $SetInput8 = "xb 08 a1"
                    $SetInput9 = "xb 09 a1"
                    $SetInput10 = "xb 10 a1"
                    $SetInput11 = "xb 11 a1"
                    $SetInput12 = "xb 12 a1"
                    $SetInput13 = "xb 13 a1"
                    $SetInput14 = "xb 14 a1"
                    $SetInput15 = "xb 15 a1"
                    $SetInput16 = "xb 16 a1"
                    $SetInput17 = "xb 17 a1"
                    $SetInput18 = "xb 18 a1"
                    $SetInput19 = "xb 19 a1"
                    $SetInput20 = "xb 20 a1"

                    $placeholder = "placeholder"
                    $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20
        
                    $port.open()
                    start-sleep -m 2000
                    $port.WriteLine($changeinput_array[$i])	# set screen input to HDMI2
                    start-sleep -m 2000
                    $port.Close()
                    start-sleep -m 2000
				}
			elseif  ($INPT[$i] -eq "DP_PC")
				{
                    $SetInput1 = "xb 01 d0"
                    $SetInput2 = "xb 02 d0"
                    $SetInput3 = "xb 03 d0"
                    $SetInput4 = "xb 04 d0"
                    $SetInput5 = "xb 05 d0"
                    $SetInput6 = "xb 06 d0"
                    $SetInput7 = "xb 07 d0"
                    $SetInput8 = "xb 08 d0"
                    $SetInput9 = "xb 09 d0"
                    $SetInput10 = "xb 10 d0"
                    $SetInput11 = "xb 11 d0"
                    $SetInput12 = "xb 12 d0"
                    $SetInput13 = "xb 13 d0"
                    $SetInput14 = "xb 14 d0"
                    $SetInput15 = "xb 15 d0"
                    $SetInput16 = "xb 16 d0"
                    $SetInput17 = "xb 17 d0"
                    $SetInput18 = "xb 18 d0"
                    $SetInput19 = "xb 19 d0"
                    $SetInput20 = "xb 20 d0"

                    $placeholder = "placeholder"
                    $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20

                    $port.open()
                    start-sleep -m 2000
                    $port.WriteLine($changeinput_array[$i])	# set screen input to DisplayPort
                    start-sleep -m 2000
                    $port.Close()
                    start-sleep -m 2000
                }
            elseif  ($INPT[$i] -eq "DP_DTV")
				{
                    $SetInput1 = "xb 01 c0"
                    $SetInput2 = "xb 02 c0"
                    $SetInput3 = "xb 03 c0"
                    $SetInput4 = "xb 04 c0"
                    $SetInput5 = "xb 05 c0"
                    $SetInput6 = "xb 06 c0"
                    $SetInput7 = "xb 07 c0"
                    $SetInput8 = "xb 08 c0"
                    $SetInput9 = "xb 09 c0"
                    $SetInput10 = "xb 10 c0"
                    $SetInput11 = "xb 11 c0"
                    $SetInput12 = "xb 12 c0"
                    $SetInput13 = "xb 13 c0"
                    $SetInput14 = "xb 14 c0"
                    $SetInput15 = "xb 15 c0"
                    $SetInput16 = "xb 16 c0"
                    $SetInput17 = "xb 17 c0"
                    $SetInput18 = "xb 18 c0"
                    $SetInput19 = "xb 19 c0"
                    $SetInput20 = "xb 20 c0"

                    $placeholder = "placeholder"
                    $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20

                    $port.open()
                    start-sleep -m 2000
                    $port.WriteLine($changeinput_array[$i])	# set screen input to DisplayPort
                    start-sleep -m 2000
                    $port.Close()
                    start-sleep -m 2000
				}
			elseif  ($INPT[$i] -eq "DVI")
				{
                    $SetInput1 = "xb 01 70"
                    $SetInput2 = "xb 02 70"
                    $SetInput3 = "xb 03 70"
                    $SetInput4 = "xb 04 70"
                    $SetInput5 = "xb 05 70"
                    $SetInput6 = "xb 06 70"
                    $SetInput7 = "xb 07 70"
                    $SetInput8 = "xb 08 70"
                    $SetInput9 = "xb 09 70"
                    $SetInput10 = "xb 10 70"
                    $SetInput11 = "xb 11 70"
                    $SetInput12 = "xb 12 70"
                    $SetInput13 = "xb 13 70"
                    $SetInput14 = "xb 14 70"
                    $SetInput15 = "xb 15 70"
                    $SetInput16 = "xb 16 70"
                    $SetInput17 = "xb 17 70"
                    $SetInput18 = "xb 18 70"
                    $SetInput19 = "xb 19 70"
                    $SetInput20 = "xb 20 70"

                    $placeholder = "placeholder"
                    $changeinput_array = $placeholder,$SetInput1,$SetInput2,$SetInput3,$SetInput4,$SetInput5,$SetInput6,$SetInput7,$SetInput8,$SetInput9,$SetInput10,$SetInput11,$SetInput12,$SetInput13,$SetInput14,$SetInput15,$SetInput16,$SetInput17,$SetInput18,$SetInput19,$SetInput20

                    $port.open()
                    start-sleep -m 2000
                    $port.WriteLine($changeinput_array[$i])	
                    start-sleep -m 2000
                    $port.Close()
                    start-sleep -m 2000
				}
        
        }
                
} #end of function

function NECcheck2
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
    $COUNT = $args[2]

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

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20

    $global:screen_status = "Good"
        
    $global:reset_displays = "no"

    $POWER_ERROR_TYPE = @()
    $POWER_ERROR_TYPE += ("Placeholder" -join " ")    
    $POWER_ERROR_DISPLAY = @()
    $POWER_ERROR_DISPLAY += ("Placeholder" -join " ")    

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

    $i = 1

	#done with the main variables

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){

                        #setting variables based on arguments given to script

                        if 		($INPT[$i] -eq "HDMI")		{$input_expected = 48,48,49,49; $input_expected_english = "HDMI"}
						elseif 	($INPT[$i] -eq "DP")        {$input_expected = 48,48,48,70; $input_expected_english = "Display Port"}
						elseif 	($INPT[$i] -eq "DVI")		{$input_expected = 48,48,48,51; $input_expected_english = "DVI"}
						elseif 	($INPT[$i] -eq "DVD_HD1")   {$input_expected = 48,48,49,50; $input_expected_english = "DVD_HD1 (HDMI)"}
                        else							    {$input_expected = "Unknown"; $input_expected_english = "Unknown"}

                        $power_expected = 48,48,48,49
                    
                                  #opening port and checking input and power for screens
                        
                            $port.open()

                                start-sleep -m 2000
                                $port.Write($power_array[$i], 0, $power_array[$i].Count)	#check power status
                                start-sleep -m 2000
                                $power_temp = $port.ReadExisting()
                                start-sleep -m 2000
                                $power_return = [System.Text.Encoding]::UTF8.GetBytes($power_temp)
                                start-sleep -m 2000
                                $port.Write($input_array[$i], 0, $input_array[$i].Count)	#check input
                                start-sleep -m 2000
                                $input_temp = $port.ReadExisting()
                                start-sleep -m 2000
                                $input_return = [System.Text.Encoding]::UTF8.GetBytes($input_temp)
                                start-sleep -m 2000

                            $port.Close()
                            start-sleep -m 2000

                        $input_return_short = $input_return[20],$input_return[21],$input_return[22],$input_return[23]
                        $power_return_short = $power_return[20],$power_return[21],$power_return[22],$power_return[23]
                    
                                #comparing returned values to what we expect
                                
                                if ($power_return_short[0] -eq 48 -and $power_return_short[1] -eq 48 -and $power_return_short[2] -eq 48 -and $power_return_short[3] -eq 52) {$PowerIsOff = "True"}
                                
                                if ($power_temp -eq "")
                                    {
                                    $screen_status = "Bad"
                                    $POWER_ERROR_TYPE += ("No Response" -join " ")
                                    $POWER_ERROR_DISPLAY += ("$i" -join " ")    
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                    write-output "The display did not send a response." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($PowerIsOff -eq "True")
                                    {
                                    $screen_status = "Bad"
                                    $POWER_ERROR_TYPE += ("Display Off" -join " ")
                                    $POWER_ERROR_DISPLAY += ("$i" -join " ")    
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                    write-output "The display is still powered off." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return_short[0] -ne $power_expected[0] -or $power_return_short[1] -ne $power_expected[1] -or $power_return_short[2] -ne $power_expected[2] -or $power_return_short[3] -ne $power_expected[3] -and $power_temp -ne "" -and $PowerIsOff -ne "True")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
                                    $POWER_ERROR_TYPE += ("Unknown Power State" -join " ")
                                    $POWER_ERROR_DISPLAY += ("$i" -join " ")    

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                    write-output "The display is in an unknown power state." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }    

                                if ($input_return_short[0] -ne $input_expected[0] -or $input_return_short[1] -ne $input_expected[1] -or $input_return_short[2] -ne $input_expected[2] -or $input_return_short[3] -ne $input_expected[3] -and $power_temp -ne "" -and $PowerIsOff -ne "True")
                                    {
                                    $screen_status = "Bad"
    
                                    if 		($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 49 -and $input_return_short[3] -eq 49)	{$input_return_english = "HDMI"}
                                    elseif 	($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 48 -and $input_return_short[3] -eq 70)	{$input_return_english = "Display Port"}
                                    elseif 	($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 48 -and $input_return_short[3] -eq 51)	{$input_return_english = "DVI"}
                                    elseif 	($input_return_short[0] -eq 48 -and $input_return_short[1] -eq 48 -and $input_return_short[2] -eq 49 -and $input_return_short[3] -eq 50)	{$input_return_english = "DVD_HD1 (HDMI)"}
                                    else 									                                                                                                            {$input_return_english = "Unknown"}
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to reset the input to $input_expected_english but failed." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                        }
                              
                                #writing log information
                                write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check After Reset" | out-file -append "$history_log"    
                                write-output "$time" | out-file -append "$history_log"
                                write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
                                write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
                                write-output "Power Status Returned - $power_return_short" | out-file -append "$history_log"
                                write-output "`r" | out-file -append "$history_log"
                                write-output "Input Status Expected - $input_expected" | out-file -append "$history_log"
                                write-output "Input Status Returned - $input_return_short" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
                                write-output "Screen Status - $screen_status" | out-file -append "$history_log"

                    } #end of "for loop"

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

                    if ($screen_status -eq "Good")

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: SUCCESS" | out-file -append "$error_log"
                            write-output "The displays have been successfully reset." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            # restart Content Player to make sure content scales properly
                            RestartCP

                            Write-Host "Everything is AOK"

                        }
                    
                    elseif ($screen_status -eq "Bad" -and $POWER_ERROR_TYPE[1] -eq "No Response")

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: FAILED" | out-file -append "$error_log"
                            write-output "FWIRMM was unable to reset the displays." | out-file -append "$error_log"
                            write-output "No response was received from Display $($POWER_ERROR_DISPLAY[1])." | out-file -append "$error_log"
                            write-output "Display $($POWER_ERROR_DISPLAY[1]) may have suffered a critical issue." | out-file -append "$error_log"
                            write-output "As a result, any displays in the RS232 daisy chain beyond Display $($POWER_ERROR_DISPLAY[1]) may be unreachable via RS232." | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "This issue may be the result of three possible scenarios:" | out-file -append "$error_log"
                            write-output "The RS232 cable leading to Display $($POWER_ERROR_DISPLAY[1]) may have become unplugged or may have been damaged." | out-file -append "$error_log"
                            write-output "Source power to Display $($POWER_ERROR_DISPLAY[1]) may have been lost." | out-file -append "$error_log"
                            write-output "Display $($POWER_ERROR_DISPLAY[1]) itself may have a critical component failure." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            Write-Host "FWIRMM detected an issue with the displays and attempted to reset the displays, but failed."

                        }

                    else

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: FAILED" | out-file -append "$error_log"
                            write-output "FWIRMM was unable to reset the displays." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            Write-Host "FWIRMM detected an issue with the displays, attempted to reset the displays, but failed."

                        }

} #end of function

function SAMcheck2
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
    $COUNT = $args[2]

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

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20

    $global:screen_status = "Good"
        
    $global:reset_displays = "no"

    $POWER_ERROR_TYPE = @()
    $POWER_ERROR_TYPE += ("Placeholder" -join " ")    
    $POWER_ERROR_DISPLAY = @()
    $POWER_ERROR_DISPLAY += ("Placeholder" -join " ")    

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

    $i = 1

	#done with the main variables

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){
					
                        #setting variables based on arguments given to script
                        
                        if 		($INPT[$i] -eq "HDMI")		{$input_expected = 33; $input_expected_english = "HDMI"}
                        elseif 	($INPT[$i] -eq "HDMI_PC")	{$input_expected = 34; $input_expected_english = "HDMI_PC"}
						elseif 	($INPT[$i] -eq "HDMI2")	    {$input_expected = 35; $input_expected_english = "HDMI2"}
						elseif 	($INPT[$i] -eq "HDMI2_PC")	{$input_expected = 36; $input_expected_english = "HDMI2_PC"}
						elseif 	($INPT[$i] -eq "DP")        {$input_expected = 37; $input_expected_english = "Display Port"}
						elseif 	($INPT[$i] -eq "DVI")		{$input_expected = 24; $input_expected_english = "DVI"}
                        elseif 	($INPT[$i] -eq "DVI_video") {$input_expected = 31; $input_expected_english = "DVI_video"}
                        elseif 	($INPT[$i] -eq "VGA")       {$input_expected = 20; $input_expected_english = "VGA"}
                        else							    {$input_expected = "Unknown"; $input_expected_english = "Unknown"}
                        
                        $power_expected = 1
    
                                #opening port and checking input and power for screens
                        
                                $port.open()
                                    start-sleep -m 2000
                                    $port.Write($power_array[$i], 0, $power_array[$i].Count)	#check power status
                                    start-sleep -m 2000
                                    $power_temp = $port.ReadExisting()
                                    start-sleep -m 2000
                                    $power_return = [System.Text.Encoding]::UTF8.GetBytes($power_temp)
                                    start-sleep -m 2000
                                    $port.Write($input_array[$i], 0, $input_array[$i].Count)	#check input
                                    start-sleep -m 2000
                                    $input_temp = $port.ReadExisting()
                                    start-sleep -m 2000
                                    $input_return = [System.Text.Encoding]::UTF8.GetBytes($input_temp)
                                    start-sleep -m 2000                                    
                                $port.Close()
                                
                                #comparing returned values to what we expect
                                
                                if ($power_temp -eq "")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
                                    $POWER_ERROR_TYPE += ("No Response" -join " ")
                                    $POWER_ERROR_DISPLAY += ("$i" -join " ")    
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                    write-output "The display did not send a response." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return[6] -eq 0)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
                                    $POWER_ERROR_TYPE += ("Display Off" -join " ")
                                    $POWER_ERROR_DISPLAY += ("$i" -join " ")    
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "Display Reset Attempt" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                    write-output "The display is still powered off." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return[6] -ne $power_expected -and $power_temp -ne "" -and $power_return[6] -ne 0)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
                                    $POWER_ERROR_TYPE += ("Unknown Power State" -join " ")
                                    $POWER_ERROR_DISPLAY += ("$i" -join " ")    
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                    write-output "The display is in an unknown power state." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($input_return[6] -ne $input_expected -and $power_temp -ne "" -and $power_return[6] -ne 0)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
    
                                    if 		($input_return[6] -eq 33)		{$input_return_english = "HDMI"}
                                    elseif 	($input_return[6] -eq 36)		{$input_return_english = "HDMI 2"}
                                    elseif 	($input_return[6] -eq 37)		{$input_return_english = "Display Port"}
                                    elseif 	($input_return[6] -eq 31)		{$input_return_english = "DVI"}
                                    elseif 	($input_return[6] -eq 20)		{$input_return_english = "VGA"}
                                    else 									{$input_return_english = "Unknown"}
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "FWIRMM attempted to reset the input to $input_expected_english but failed." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }
        
                                #writing log information
    
								write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check After Reset" | out-file -append "$history_log"    
								write-output "$time" | out-file -append "$history_log"
								write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
								write-output "Power Status Returned - $($power_return[6])" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Input Status Expected - $input_expected" | out-file -append "$history_log"
								write-output "Input Status Returned - $($input_return[6])" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Screen Status - $screen_status" | out-file -append "$history_log"

    
                    }#end of "for loop"

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

                    if ($screen_status -eq "Good")

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "Display Reset Attempt" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "Reset Result: SUCCESS" | out-file -append "$error_log"
                            write-output "The displays have been successfully reset." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            # restart Content Player to make sure content scales properly
                            RestartCP

                            Write-Host "Everything is AOK"

                        }

                    elseif ($screen_status -eq "Bad" -and $POWER_ERROR_TYPE[1] -eq "No Response")

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: FAILED" | out-file -append "$error_log"
                            write-output "FWIRMM was unable to reset the displays." | out-file -append "$error_log"
                            write-output "No response was received from Display $($POWER_ERROR_DISPLAY[1])." | out-file -append "$error_log"
                            write-output "Display $($POWER_ERROR_DISPLAY[1]) may have suffered a critical issue." | out-file -append "$error_log"
                            write-output "Any displays in the RS232 daisy chain beyond Display $($POWER_ERROR_DISPLAY[1]) may be unreachable via RS232." | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "This issue may be the result of three possible scenarios:" | out-file -append "$error_log"
                            write-output "The RS232 cable leading to Display $($POWER_ERROR_DISPLAY[1]) may have become unplugged or may have been damaged." | out-file -append "$error_log"
                            write-output "Source power to Display $($POWER_ERROR_DISPLAY[1]) may have been lost." | out-file -append "$error_log"
                            write-output "Display $($POWER_ERROR_DISPLAY[1]) itself may have a critical component failure." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            Write-Host "FWIRMM detected an issue with the displays and attempted to reset the displays, but failed."

                        }
                
                    else

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "Display Reset Results" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "Reset Result: FAILED" | out-file -append "$error_log"
                            write-output "FWIRMM was unable to reset the displays." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            Write-Host "FWIRMM detected an issue with the displays, attempted to reset the displays, but failed."

                        }

} #end of function

function LGcheck2
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
	$INPT = $args[1]
    $COUNT = $args[2]
    
    $chkPower1 = "ka 01 ff"
    $chkPower2 = "ka 02 ff"
    $chkPower3 = "ka 03 ff"
    $chkPower4 = "ka 04 ff"
    $chkPower5 = "ka 05 ff"
    $chkPower6 = "ka 06 ff"
    $chkPower7 = "ka 07 ff"
    $chkPower8 = "ka 08 ff"
    $chkPower9 = "ka 09 ff"
    $chkPower10 = "ka 10 ff"
    $chkPower11 = "ka 11 ff"
    $chkPower12 = "ka 12 ff"
    $chkPower13 = "ka 13 ff"
    $chkPower14 = "ka 14 ff"
    $chkPower15 = "ka 15 ff"
    $chkPower16 = "ka 16 ff"
    $chkPower17 = "ka 17 ff"
    $chkPower18 = "ka 18 ff"
    $chkPower19 = "ka 19 ff"
    $chkPower20 = "ka 20 ff"

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

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $input_array = $placeholder,$chkInput1,$chkInput2,$chkInput3,$chkInput4,$chkInput5,$chkInput6,$chkInput7,$chkInput8,$chkInput9,$chkInput10,$chkInput11,$chkInput12,$chkInput13,$chkInput14,$chkInput15,$chkInput16,$chkInput17,$chkInput18,$chkInput19,$chkInput20

    $global:screen_status = "Good"

    $global:reset_displays = "no"

    $POWER_ERROR_TYPE = @()
    $POWER_ERROR_TYPE += ("Placeholder" -join " ")    
    $POWER_ERROR_DISPLAY = @()
    $POWER_ERROR_DISPLAY += ("Placeholder" -join " ")    

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

	$i = 1
	
    #done with the main variables
    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
	
					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){
					
					#setting variables based on arguments given to script
					if 		($INPT[$i] -eq "HDMI")		{$input_expected = "b 0"+$i+" OK90x"; $input_expected_english = "HDMI"}
					elseif 	($INPT[$i] -eq "HDMI1")	    {$input_expected = "b 0"+$i+" OKa0x"; $input_expected_english = "HDMI 1"}
					elseif 	($INPT[$i] -eq "HDMI2")	    {$input_expected = "b 0"+$i+" OKa1x"; $input_expected_english = "HDMI 2"}
                    elseif 	($INPT[$i] -eq "DP_PC")     {$input_expected = "b 0"+$i+" OKd0x"; $input_expected_english = "Display Port PC"}
					elseif 	($INPT[$i] -eq "DP_DTV")    {$input_expected = "b 0"+$i+" OKc0x"; $input_expected_english = "Display Port DTV"}
					elseif 	($INPT[$i] -eq "DVI")       {$input_expected = "b 0"+$i+" OK70x"; $input_expected_english = "DVI"}
					else							    {$input_expected = "Unknown"; $input_expected_english = "Unknown"}
					
					$power_expected = "a 0"+$i+" OK01x"

							#opening port and checking input and power for screens
					
							$port.open()
                            start-sleep -m 2000
                            $port.WriteLine("")
                            start-sleep -m 2000
                            $port.WriteLine($power_array[$i])	#check power status
                            start-sleep -m 2000
                            $power_return = $port.ReadExisting()
                            start-sleep -m 2000
                            $port.WriteLine($input_array[$i])	#check input
                            start-sleep -m 2000
                            $input_return = $port.ReadExisting()
                            start-sleep -m 2000
							$port.Close()
							
							#comparing returned values to what we expect
                            
                            if ($power_return -eq "")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"
                                $POWER_ERROR_TYPE += ("No Response" -join " ")
                                $POWER_ERROR_DISPLAY += ("$i" -join " ")    

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
                                write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
                                write-output "The display did not send a response." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }                            

							if ($power_return -eq "a 0"+$i+" OK00x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"
                                $POWER_ERROR_TYPE += ("Display Off" -join " ")
                                $POWER_ERROR_DISPLAY += ("$i" -join " ")    

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
                                write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
								write-output "The display is still powered off." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }

                            if ($power_return -ne $power_expected -and $power_return -ne "" -and $power_return -ne "a 0"+$i+" OK00x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"
                                $POWER_ERROR_TYPE += ("Unknown Power State" -join " ")
                                $POWER_ERROR_DISPLAY += ("$i" -join " ")    

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
								write-output "FWIRMM attempted to power on the display but failed." | out-file -append "$error_log"
								write-output "The display is in an unknown power state." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }
                                
							if ($input_return -ne $input_expected -and $power_return -ne "" -and $power_return -ne "a 0"+$i+" OK00x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								if 		($input_return -eq "b 0"+$i+" OK90x")		{$input_return_english = "HDMI"}
								elseif 	($input_return -eq "b 0"+$i+" OKa0x")		{$input_return_english = "HDMI 1"}
								elseif 	($input_return -eq "b 0"+$i+" OKa1x")		{$input_return_english = "HDMI 2"}
								elseif 	($input_return -eq "b 0"+$i+" OKd0x")		{$input_return_english = "Display Port"}
								elseif 	($input_return -eq "b 0"+$i+" OK70x")		{$input_return_english = "DVI"}
								else 												{$input_return_english = "Unknown"}

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY RESET ATTEMPT" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
                                write-output "FWIRMM attempted to reset the input to $input_expected_english but failed." | out-file -append "$error_log"
								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
								}

							#writing log information

								write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check After Reset" | out-file -append "$history_log"    
								write-output "$time" | out-file -append "$history_log"
								write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
								write-output "Power Status Returned - $power_return" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Input Status Expected - $input_expected" | out-file -append "$history_log"
								write-output "Input Status Returned - $input_return" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Screen Status - $screen_status" | out-file -append "$history_log"

							#end of "for loop"
                    }
                    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

                    if ($screen_status -eq "Good")

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: SUCCESS" | out-file -append "$error_log"
                            write-output "The displays have been successfully reset." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            # restart Content Player to make sure content scales properly
                            RestartCP

                            Write-Host "Everything is AOK"

                        }
                
                    elseif ($screen_status -eq "Bad" -and $POWER_ERROR_TYPE[1] -eq "No Response")

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: FAILED" | out-file -append "$error_log"
                            write-output "FWIRMM was unable to reset the displays." | out-file -append "$error_log"
                            write-output "No response was received from Display $($POWER_ERROR_DISPLAY[1])." | out-file -append "$error_log"
                            write-output "Display $($POWER_ERROR_DISPLAY[1]) may have suffered a critical issue." | out-file -append "$error_log"
                            write-output "Any displays in the RS232 daisy chain beyond Display $($POWER_ERROR_DISPLAY[1]) may be unreachable via RS232." | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "This issue may be the result of three possible scenarios:" | out-file -append "$error_log"
                            write-output "The RS232 cable leading to Display $($POWER_ERROR_DISPLAY[1]) may have become unplugged or may have been damaged." | out-file -append "$error_log"
                            write-output "Source power to Display $($POWER_ERROR_DISPLAY[1]) may have been lost." | out-file -append "$error_log"
                            write-output "Display $($POWER_ERROR_DISPLAY[1]) itself may have a critical component failure." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            Write-Host "FWIRMM detected an issue with the displays and attempted to reset the displays, but failed."

                        }

                    else

                        {
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                            write-output "DISPLAY RESET RESULTS" | out-file -append "$error_log"
                            write-output "$time" | out-file -append "$error_log"
                            write-output "`r" | out-file -append "$error_log"
                            write-output "Reset Result: FAILED" | out-file -append "$error_log"
                            write-output "FWIRMM was unable to reset the displays." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"

                            Write-Host "FWIRMM detected an issue with the displays and attempted to reset the displays, but failed."
                        
                        }
} #end of function

function NECoffcheck
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
    $COUNT = $args[2]

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

    $placeholder = "placeholder"

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $PowerIsOn = "False"

    $global:screen_status = "Good"

    $global:reset_displays = "no"

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

    $i = 1

	#done with the main variables

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){

                        #setting variables based on arguments given to script

                        $power_expected = 48,48,48,52
                    
                                  #opening port and checking input and power for screens
                        
                            $port.open()

                                start-sleep -m 2000
                                $port.Write($power_array[$i], 0, $power_array[$i].Count)	#check power status
                                start-sleep -m 2000
                                $power_temp = $port.ReadExisting()
                                start-sleep -m 2000
                                $power_return = [System.Text.Encoding]::UTF8.GetBytes($power_temp)
                                start-sleep -m 2000

                            $port.Close()
                            start-sleep -m 2000

                        $power_return_short = $power_return[20],$power_return[21],$power_return[22],$power_return[23]

                                #comparing returned values to what we expect
                                if ($power_return_short[0] -eq 48 -and $power_return_short[1] -eq 48 -and $power_return_short[2] -eq 48 -and $power_return_short[3] -eq 49) {$PowerIsOn = "True"}
                                
                                if ($PowerIsOn -eq "True")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "Currently outside of working hours." | out-file -append "$error_log"                        
                                    write-output "FWIRMM has detected that the display is powered on." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power off the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return_short[0] -ne $power_expected[0] -or $power_return_short[1] -ne $power_expected[1] -or $power_return_short[2] -ne $power_expected[2] -or $power_return_short[3] -ne $power_expected[3] -and $power_temp -ne "" -and $PowerIsOn -ne "True")
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"
    
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "Currently outside of working hours." | out-file -append "$error_log"                        
                                    write-output "FWIRMM has detected that the display is in an unknown power state." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power off the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }    

                                #writing log information
    
                                write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check (outside of working hours)" | out-file -append "$history_log"    
                                write-output "$time" | out-file -append "$history_log"
                                write-output "Display ID - $i" | out-file -append "$history_log"
                                write-output "`r" | out-file -append "$history_log"
                                write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
                                write-output "Power Status Returned - $power_return_short" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
                                write-output "Screen Status - $screen_status" | out-file -append "$history_log"

                    } #end of "for loop"

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "Turn Off Displays? - $reset_displays" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

} #end of function

function SAMoffcheck
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
    $COUNT = $args[2]

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
            
    $placeholder = "placeholder"

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $PowerIsOn = "False"

    $global:screen_status = "Good"
        
    $global:reset_displays = "no"

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

    $i = 1

    #done with the main variables
    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){
					
                        #setting variables based on arguments given to script
                                                
                        $power_expected = 0
    
                                #opening port and checking input and power for screens
                        
                                $port.open()
                                    start-sleep -m 2000
                                    $port.Write($power_array[$i], 0, $power_array[$i].Count)	#check power status
                                    start-sleep -m 2000
                                    $power_temp = $port.ReadExisting()
                                    start-sleep -m 2000
                                    $power_return = [System.Text.Encoding]::UTF8.GetBytes($power_temp)
                                    start-sleep -m 2000                                    
                                $port.Close()
                                
                                #comparing returned values to what we expect

                                if ($power_return[6] -eq 1)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "Currently outside of working hours." | out-file -append "$error_log"                        
                                    write-output "FWIRMM has detected that the display is powered on." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power off the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }

                                if ($power_return[6] -ne $power_expected -and $power_temp -ne "" -and $power_return[6] -ne 1)
                                    {
                                    $screen_status = "Bad"
                                    $script:reset_displays = "yes"

                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
                                    write-output "$time" | out-file -append "$error_log"
                                    write-output "Display ID - $i" | out-file -append "$error_log"
                                    write-output "`r" | out-file -append "$error_log"
                                    write-output "Currently outside of working hours." | out-file -append "$error_log"                        
                                    write-output "FWIRMM has detected that the display is in an unknown power state." | out-file -append "$error_log"
                                    write-output "FWIRMM will attempt to power off the display." | out-file -append "$error_log"
                                    write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                    }
        
                                #writing log information
    
								write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                                write-output "Display Status Check (outside of working hours)" | out-file -append "$history_log"    
								write-output "$time" | out-file -append "$history_log"
								write-output "Display ID - $i" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
								write-output "Power Status Returned - $($power_return[6])" | out-file -append "$history_log"
								write-output "`r" | out-file -append "$history_log"
								write-output "Screen Status - $screen_status" | out-file -append "$history_log"

    
                    }#end of "for loop"

                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "Turn Off Displays? - $reset_displays" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

} #end of function

function LGoffcheck
{
	#setting variables

    $PORTNAME = $args[0]
    $port = new-Object System.IO.Ports.SerialPort $PORTNAME,9600,None,8,one
    $COUNT = $args[2]
    
    $chkPower1 = "ka 01 ff"
    $chkPower2 = "ka 02 ff"
    $chkPower3 = "ka 03 ff"
    $chkPower4 = "ka 04 ff"
    $chkPower5 = "ka 05 ff"
    $chkPower6 = "ka 06 ff"
    $chkPower7 = "ka 07 ff"
    $chkPower8 = "ka 08 ff"
    $chkPower9 = "ka 09 ff"
    $chkPower10 = "ka 10 ff"
    $chkPower11 = "ka 11 ff"
    $chkPower12 = "ka 12 ff"
    $chkPower13 = "ka 13 ff"
    $chkPower14 = "ka 14 ff"
    $chkPower15 = "ka 15 ff"
    $chkPower16 = "ka 16 ff"
    $chkPower17 = "ka 17 ff"
    $chkPower18 = "ka 18 ff"
    $chkPower19 = "ka 19 ff"
    $chkPower20 = "ka 20 ff"

    $placeholder = "placeholder"

    $power_array = $placeholder,$chkPower1,$chkPower2,$chkPower3,$chkPower4,$chkPower5,$chkPower6,$chkPower7,$chkPower8,$chkPower9,$chkPower10,$chkPower11,$chkPower12,$chkPower13,$chkPower14,$chkPower15,$chkPower16,$chkPower17,$chkPower18,$chkPower19,$chkPower20

    $PowerIsOn = "False"

    $global:screen_status = "Good"
	
	$global:reset_displays = "no"

	$time = Get-Date
	$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
	$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

	$i = 1
	
	#done with the main variables
    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

					#begin "for loop" restricted by the screen quantity argument given to script

					for ($i = 1; $i -le $COUNT; $i++){
										
					$power_expected = "a 0"+$i+" OK00x"

							#opening port and checking input and power for screens
					
							$port.open()
                            start-sleep -m 2000
                            $port.WriteLine($power_array[$i])	#check power status
                            start-sleep -m 2000
                            $power_return = $port.ReadExisting()
                            start-sleep -m 2000
							$port.Close()
							
							#comparing returned values to what we expect
							
							if ($power_return -eq "a 0"+$i+" OK01x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
                                write-output "Currently outside of working hours." | out-file -append "$error_log"                        
                                write-output "FWIRMM has detected that the display is powered on." | out-file -append "$error_log"
                                write-output "FWIRMM will attempt to power off the display." | out-file -append "$error_log"
                            write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }

                            if ($power_return -ne $power_expected -and $power_return -ne "" -and $power_return -ne "a 0"+$i+" OK01x")
								{
								$screen_status = "Bad"
								$script:reset_displays = "yes"

								write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                write-output "DISPLAY ISSUE DETECTED!" | out-file -append "$error_log"
								write-output "$time" | out-file -append "$error_log"
								write-output "Display ID - $i" | out-file -append "$error_log"
								write-output "`r" | out-file -append "$error_log"
                                write-output "Currently outside of working hours." | out-file -append "$error_log"                        
                                write-output "FWIRMM has detected that the display is in an unknown power state." | out-file -append "$error_log"
                                write-output "FWIRMM will attempt to power off the display." | out-file -append "$error_log"
                                write-output "---------------------------------------------------------------------------------------" | out-file -append "$error_log"
                                }

							#writing log information

                            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                            write-output "Display Status Check (outside of working hours)" | out-file -append "$history_log"    
                            write-output "$time" | out-file -append "$history_log"
                            write-output "Display ID - $i" | out-file -append "$history_log"
                            write-output "`r" | out-file -append "$history_log"
                            write-output "Power Status Expected - $power_expected" | out-file -append "$history_log"
                            write-output "Power Status Returned - $power_return" | out-file -append "$history_log"
                            write-output "`r" | out-file -append "$history_log"
                            write-output "Screen Status - $screen_status" | out-file -append "$history_log"
							
                    } #end of "for loop"
                    
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "Turn Off Displays? - $reset_displays" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
                    write-output "--------------------------------------------------------------------" | out-file -append "$history_log"

} #end of function

function EnableLock
{
    $timeout = 1
    while ((Test-Path $Lockfile) -and $timeout -lt 15)
        {
            start-sleep -s 10
            $timeout++
        }

    If 	(-Not (Test-Path $Lockfile))
        {
            New-Item -Path $currentdir -Name "Lock.file" -ItemType "file" -Value "If you can see this file, the RS232 monitoring script is currently running." | Out-Null
            Set-ItemProperty -Path $Lockfile -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
        }
} #end of function

function DisableLock
{
    Remove-Item -Path "$currentdir\Lock.file" -Force
} #end of function

function RestartCP
{

    $signage = Get-Process signage -ErrorAction SilentlyContinue

    # check if signage is running. only restart signage if signage is already running.

    if ($signage)
    
        {
            #$signagepath = Get-Process -Name signage | Select -ExpandProperty path | out-string
            #$signagepath = $signagepath -replace "`t|`n|`r",""

            # stop signage.

            $signage | Stop-Process -Force

            Start-sleep 5

            $signage = Get-Process signage -ErrorAction SilentlyContinue

            # if stopping failed, log and exit.

            if ($signage)
        
                {write-output "Content Player couldn't be stopped or restarted." | timestamp | out-file -append "$history_log"}

            # if stopping was succesful, restart signage.

            else
                
                {
                    write-output "Content Player was stopped." | timestamp | out-file -append "$history_log"

                    $scheduledtask = schtasks /query /tn StartCP

                    If 	($scheduledtask)
                    
                        {schtasks /Run /TN StartCP}
        
                    <# if scheduled task does not exist create file or something to alert that the scheduled task does not exist.

                    else
                    
                        {  }

                    #>
                
                    start-sleep 10

                    $signage = Get-Process signage -ErrorAction SilentlyContinue

                    if ($signage)
                
                        {write-output "Content Player was restarted." | timestamp | out-file -append "$history_log"}
        
                    else
                        
                        {write-output "Content Player failed to restart." | timestamp | out-file -append "$history_log"}
        
                }


        }


} #end of function

function OffHoursStatusCheck
{
    # checking last three statuses recorded to history log
    $laststatus = select-string $history_log -pattern "Reset Displays" | Select-Object -last 3

    # reporting back to RMM the last status check during working hours

    # if      ($laststatus.Line[0] -match "yes" -and $laststatus.Line[1] -match "yes" -and $laststatus.Line[2] -match "yes") # this line replaced with powershell 2 compatible line below

    if ($laststatus.count -eq 3 -and (($laststatus[0] | Select -ExpandProperty "Line") -match "yes") -and (($laststatus[1] | Select -ExpandProperty "Line") -match "yes") -and (($laststatus[2] | Select -ExpandProperty "Line") -match "yes"))             
                {
                    Write-host "Screens were in failed state when last checked during work hours."
                }
    else
                {
                    Write-Host "Everything is AOK"
                }    
} #end of function


<# 
#Check for other instances of the script already running and wait until they are done
#Instances disabled - using lock file method instead.
  
$instances = @(Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%DisplayMonitoring%'")

while ($instances.count -gt 1)
{
start-sleep -s 10
$instances = @(Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%DisplayMonitoring%'")
}
#>

# Get working directory
$currentdir = split-path -parent $MyInvocation.MyCommand.Definition
$Lockfile = "$currentdir\Lock.file"

#Enable Lock for script - esnures only 1 copy of the script is running at any 1 time
EnableLock

#Getting argument
$ARG = $args[0]

#Checking for XML file.
$XMLinfo="C:\Windows\LTSvc\plugins\FWIRMM_RS232.XML"
If 	(-Not (Test-Path $XMLinfo)) {Write-host "XML File Not Found.";DisableLock;Exit}

#Grab information from XML file
[xml]$info = (get-content $XMLinfo)

#Set variables
$MFG = $info.SelectNodes("//MFG") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue

#3 Letter codes supported for each MFG
$NEC_array = "NEC","ADV"
$SAM_array = "SAM"
$LG_array = "LGD","GSM","GN"

# if the MFG provided is not supported script will output message and exit.
if ($NEC_array -notcontains $MFG -and $SAM_array -notcontains $MFG -and $LG_array -notcontains $MFG) {write-host "This script does not support the provided manufacturer. Script must now exit without monitoring.";DisableLock;Exit}

# getting monitoring variables from XML
$PORTNAME = $info.SelectNodes("//Port") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
$COUNT = $info.SelectNodes("//NumberOfScreens") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
$COUNT = [int]$COUNT

$INPT = @()
$INPT += ("Placeholder" -join " ")
for ($i = 1; $i -le $COUNT; $i++)
        {
            $temp = $info.SelectNodes("//Screen"+$i+"/Input") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
            $INPT += ($temp -join " ")
        }

# if any inputs in the XML are unknown, output message, and exit script.
if ($INPT -contains "Unknown")          {Write-Host "Display(s) may be using unknown/unsupported input. Script must now exit without monitoring.";DisableLock;Exit}

#checking for Working Hours XML
$XMLhours="C:\Windows\LTSvc\plugins\FWIRMM_RS232_HOURS.XML"
If 	(Test-Path $XMLhours) {$TimeRestrictions = "True"}
Else                      {$TimeRestrictions = "False"}
$IsWorkingHours = "True"
$TurnOn = "False"   #may change to "Off Hours" depending on if Rob wants them monitored during off times.
$TurnOff = "False"

# Declaring history log and error log
$history_log = "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog.txt"
$error_log = "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog.txt"

# Check if history log is over 200mb
if ((Test-Path -path $history_log) -and ((Get-Item $history_log).length -gt 200000000))
        {
            #grab last status entry from log
            $laststatusentry = select-string $history_log -pattern "Reset Displays" | Select-Object -last 3

            #finding number from the last "old" history log and adding 1
            $last_old_historylog = Get-ChildItem -Path $currentdir -Include *HistoryLog* -Name | Select-Object -last 1
            
                if ($last_old_historylog -match "Log\d+") 
                    {
                        $num = [string]$matches.Values -replace '\D+(\d+)','$1'
                        $num = [int]$num
                        $num = $num + 1
                    }
                else
                    {
                        $num = 1
                    }
            
            Copy-item $history_log -Destination "$currentdir\FWIRMM_Dynamic_RS232_HistoryLog$num.old"
            Remove-item $history_log

            #write last status entry from previous log to the new log
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "Last Display Status from Previous Log" | out-file -append "$history_log"
            write-output $laststatusentry.Line[0] | out-file -append "$history_log"
            write-output $laststatusentry.Line[1] | out-file -append "$history_log"
            write-output $laststatusentry.Line[2] | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"
            write-output "--------------------------------------------------------------------" | out-file -append "$history_log"            
        }

# Check if error log is over 2mb
if ((Test-Path -path $error_log) -and ((Get-Item $error_log).length -gt 2000000))
        {
            $last_old_errorlog = Get-ChildItem -Path $currentdir -Include *ErrorLog* -Name | Select-Object -last 1
            
                if ($last_old_errorlog -match "Log\d+") 
                    {
                        $num = [string]$matches.Values -replace '\D+(\d+)','$1'
                        $num = [int]$num
                        $num = $num + 1
                    }
                else
                    {
                        $num = 1
                    }
            
            Copy-item $error_log -Destination "$currentdir\FWIRMM_Dynamic_RS232_ErrorLog$num.old"
            Remove-item $error_log
            New-Item $error_log
        }


# Check if the TurnOn or TurnOff argument was sent

if      ($NEC_array -contains $MFG -and $ARG -eq "TurnOn")      {NECon $PORTNAME $INPT $COUNT NoLog}
elseif  ($SAM_array -contains $MFG -and $ARG -eq "TurnOn")      {SAMon $PORTNAME $INPT $COUNT NoLog}
elseif  ($LG_array -contains $MFG -and $ARG -eq "TurnOn")       {LGon $PORTNAME $INPT $COUNT NoLog}

if      ($NEC_array -contains $MFG -and $ARG -eq "TurnOff")     {NECoff $PORTNAME $INPT $COUNT NoLog}
elseif  ($SAM_array -contains $MFG -and $ARG -eq "TurnOff")     {SAMoff $PORTNAME $INPT $COUNT NoLog}
elseif  ($LG_array -contains $MFG -and $ARG -eq "TurnOff")      {LGoff $PORTNAME $INPT $COUNT NoLog}

#Working Hours check

If ($TimeRestrictions -eq "True")

{

    [xml]$hours = (get-content $XMLhours)
    $OnTime = $hours.SelectNodes("//OnTime") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    $OffTime = $hours.SelectNodes("//OffTime") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    $DaysOff = $hours.SelectNodes("//DaysOff") | Select-Object -Expand '#text' -ErrorAction SilentlyContinue
    If ($null -ne $DaysOff) {$DaysOff = $DaysOff.split(",")}

    #Set the dates 
    $Now = Get-Date 
    $Day = $Now.DayOfWeek
    $OnTimeHour = $Ontime.Substring(0,2)
    $OnTimeMinutes = $OnTime.Substring(3,2)
    $OffTimeHour = $Offtime.Substring(0,2)
    $OffTimeMinutes = $OffTime.Substring(3,2)
    $TodayStart = Get-Date -Hour $OnTimeHour -Minute $OnTimeMinutes -Second 00 -Day $Now.Day -Month $Now.Month
    $TodayEnd = Get-Date -Hour $OffTimeHour -Minute $OffTimeMinutes -Second 00 -Day $Now.Day -Month $Now.Month
    $Add5 = New-Timespan -Minutes 7
    $TodayStartPlus5 = $TodayStart + $Add5
    $TodayEndPlus5 = $TodayEnd + $Add5

    # Check if the time is currently within work hours
    if ($Now -lt $TodayStart -or $Now -gt $TodayEnd)            {$IsWorkingHours = "False"}   
    if ($DaysOff -contains $Day)                                {$IsWorkingHours = "False";$OffDay = "True"}
    if ($Now -gt $TodayStart -and $Now -lt $TodayStartPlus5)    {$TurnOn = "True"}
    if ($Now -gt $TodayEnd -and $Now -lt $TodayEndPlus5)        {$TurnOff = "True"}

}

# global script variable determining if displays need to be reset
$reset_displays = "no"

# script checks for display count

if ($COUNT -gt 20)                      {Write-Output "This script can only support a maximum of 20 displays.  Script will now exit.";DisableLock;Exit}

# check if screens need to be turned on for the day

if      ($NEC_array -contains $MFG -and $TurnOn -eq "True" -and $OffDay -ne "True")       {NECon $PORTNAME $INPT $COUNT}
elseif  ($SAM_array -contains $MFG -and $TurnOn -eq "True" -and $OffDay -ne "True")       {SAMon $PORTNAME $INPT $COUNT}
elseif  ($LG_array -contains $MFG -and $TurnOn -eq "True" -and $OffDay -ne "True")        {LGon $PORTNAME $INPT $COUNT}
    
# check if screens need to be turned off for the night

if      ($NEC_array -contains $MFG -and $TurnOff -eq "True" -and $OffDay -ne "True")      {NECoff $PORTNAME $INPT $COUNT}
elseif  ($SAM_array -contains $MFG -and $TurnOff -eq "True" -and $OffDay -ne "True")      {SAMoff $PORTNAME $INPT $COUNT}
elseif  ($LG_array -contains $MFG -and $TurnOff -eq "True" -and $OffDay -ne "True")       {LGoff $PORTNAME $INPT $COUNT}

# check if not currently working hours and if so, run off hours check

if      ($NEC_array -contains $MFG -and $IsWorkingHours -eq "False")     {NECoffcheck $PORTNAME $INPT $COUNT}
elseif  ($SAM_array -contains $MFG -and $IsWorkingHours -eq "False")     {SAMoffcheck $PORTNAME $INPT $COUNT}
elseif  ($LG_array -contains $MFG -and $IsWorkingHours -eq "False")      {LGoffcheck $PORTNAME $INPT $COUNT}

# if currently outside of working hours and screens need to be turned off, run turn off function

if      ($NEC_array -contains $MFG -and $IsWorkingHours -eq "False" -And $reset_displays -eq "yes")         {NECoff $PORTNAME $INPT $COUNT Fix}
elseif  ($SAM_array -contains $MFG -and $IsWorkingHours -eq "False" -And $reset_displays -eq "yes")         {SAMoff $PORTNAME $INPT $COUNT Fix}
elseif  ($LG_array -contains $MFG -and $IsWorkingHours -eq "False" -And $reset_displays -eq "yes")          {LGoff $PORTNAME $INPT $COUNT Fix}
elseif  ($IsWorkingHours -eq "False" -And $reset_displays -ne "yes")                                        {OffHoursStatusCheck;DisableLock;Exit}

# if it is currently working hours, run screen check function based on manufacturer

if      ($NEC_array -contains $MFG)     {NECcheck $PORTNAME $INPT $COUNT}
elseif  ($SAM_array -contains $MFG)     {SAMcheck $PORTNAME $INPT $COUNT}
elseif  ($LG_array -contains $MFG)      {LGcheck $PORTNAME $INPT $COUNT}

# after screen check is complete, check value of reset_displays variable and runs the fix function if necessary

if      ($NEC_array -contains $MFG -And $reset_displays -eq "yes")      {NECfix $PORTNAME $INPT $COUNT}
elseif  ($SAM_array -contains $MFG -And $reset_displays -eq "yes")      {SAMfix $PORTNAME $INPT $COUNT}
elseif  ($LG_array -contains $MFG -And $reset_displays -eq "yes")       {LGfix $PORTNAME $INPT $COUNT}
else                                                                    {write-host "Everything is AOK";DisableLock;Exit}  #if the screens are in the desired state, the script will output a success message to RMM

# give the displays some time to start up before the second check

start-sleep -s 30

# second check of the screens after the reset is sent

if      ($NEC_array -contains $MFG -And $reset_displays -eq "yes")     {NECcheck2 $PORTNAME $INPT $COUNT}
elseif  ($SAM_array -contains $MFG -And $reset_displays -eq "yes")     {SAMcheck2 $PORTNAME $INPT $COUNT}
elseif  ($LG_array -contains $MFG -And $reset_displays -eq "yes")      {LGcheck2 $PORTNAME $INPT $COUNT}

DisableLock
Exit