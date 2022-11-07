<#
 .Synopsis
  Display the last reboots

 .Description
  The function displays the last reboots and the amount of time each took.

 .Parameter Days
  The number of days in the past to display. Default to 10.

 .Example
   # Show the activity for the last 10 days.
   Show-LastReboot
#>
function Show-LastReboot {
    Param(
        [ValidateRange(1,60)]
        [int16] 
        $Days = 10
    )
    Process {
        if ([environment]::OSVersion.Platform -eq 'Unix') {
            Write-Warning "This cmdlet is not available on this platform."
            return
        }
    
        -1..-$Days | ForEach-Object {
            $When =  (Get-Date).AddDays($_)
            $After =  Get-Date $When  -Hour 0  -Minute 0  -Second 0
            $Before = Get-Date $When  -Hour 23 -Minute 59 -Second 59
            $DayEvents =(Get-Eventlog -Entrytype Information -Logname System -After $After -Before $Before).TimeGenerated
            if($null -ne $DayEvents) {
                $Span = New-Timespan -Start ($DayEvents | Select-Object -Last 1) -End ($DayEvents | Select-Object -First 1)
                "Your computer worked hard on {0} - for {1}:{2}:{3} hours" -F $When.ToString('yyyy-MM-dd'),$Span.Hours,$Span.Minutes,$Span.Seconds
            } else {
                $msg = "Holiday for your computer on {0}. It is not powered on" -F $When.ToString('yyyy-MM-dd') 
                Write-host $msg -foregroundcolor green
            }
        }
    }
}
