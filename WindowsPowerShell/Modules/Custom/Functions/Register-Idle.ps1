$SQLITE_DATE_FMT = "yyyy-MM-dd'T'HH:mm:ss"
<#
    
.SYNOPSIS

Register idle time in an SQLite DB. Useful to incurr your time

.EXAMPLE

PS > Register-Idle -InitDB
Initialize the SQLite DB and exit

PS > Register-Idle -Dump | Export-Csv -Path Idle.csv
Enter a loop to register idle time during the day

PS > Register-Idle -Dump -Readable -ByWeek

Week Hours Minutes
---- ----- -------
41       7      24
42      39      35
43       3      22

Gives you an idea of the time you spent working each week

PS > Register-Idle -Schedule
Create the Scheduled Task. Note that the Trigger (AtLogon) fails, and must be setup manually 

#>
function Register-Idle {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'init')]
        [Parameter(HelpMessage = 'Create an initialize the database to register working period')]
        [switch]
        $InitDB = $false,
        [Parameter(ParameterSetName = 'init')]
        [Parameter(HelpMessage = 'Create the schedule task to run the script at logon')]
        [switch]
        $Schedule = $false,
        [Parameter(ParameterSetName = 'run')]
        [Parameter(HelpMessage = 'Run the script to monitor your activity and save it to file')]
        [switch]
        $Run,
        [Parameter(ParameterSetName = 'init')]
        [Parameter(ParameterSetName = 'run')]
        [ValidateNotNullOrEmpty()]
        [String]
        $IdleDB = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Idle.db'),
        [Parameter(ParameterSetName = 'run')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Log = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Idle.log'),
        [Parameter(ParameterSetName = 'run')]
        [ValidateRange(1, 10)]
        [int16] 
        $MinBreakTimeInMinutes = 7,
        [Parameter(ParameterSetName = 'dump')]
        [Parameter(HelpMessage = 'Whether to dump the database')]
        [switch]
        $Dump = $false,
        [Parameter(ParameterSetName = 'dump')]
        [Parameter(HelpMessage = 'Whether to dump the database group by daily period. Imply -Dump.')]
        [switch]
        $ByDay = $false,
        [Parameter(ParameterSetName = 'dump')]
        [Parameter(HelpMessage = 'Whether to dump the database group by weekly period. Imply -Dump.')]
        [switch]
        $ByWeek = $false,
        [Parameter(ParameterSetName = 'dump')]
        [Parameter(HelpMessage = 'Whether to dump the database in a human readable format. Imply -Dump.')]
        [switch]
        $Readable = $false    
    )
    Begin {
        if (-not (Get-Module -ListAvailable PSSQLite)) { 
            Write-Host 'Installing PSSQLite ...'
            Install-Module -Name PSSQLite -Scope CurrentUser -AllowClobber -Force
            Import-Module -Name PSSQLite
        }
        function Start-Period {
            param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $StartDate,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $StopDate
            )
            try {
                Invoke-SqliteQuery -Query 'INSERT INTO WorkingPeriods (StartDate, StopDate, Consolidated) VALUES (@StartDate, @StopDate, 0)' -DataSource $IdleDB -SqlParameters @{
                    StartDate = $StartDate.ToString($SQLITE_DATE_FMT)
                    StopDate  = $StopDate.ToString($SQLITE_DATE_FMT)
                }
            }
            catch {
                Write-Error $_
            }
        }
        
        function Update-Period {
            param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $StopDate
            )
            try {
                Invoke-SqliteQuery -Query 'UPDATE WorkingPeriods SET StopDate = @StopDate WHERE Consolidated = 0' -DataSource $IdleDB -SqlParameters @{
                    StopDate = $StopDate.ToString($SQLITE_DATE_FMT)
                }
            }
            catch {
                Write-Error $_
            }
        }

        function Get-LastPeriod {
            try {
                Invoke-SqliteQuery -Query 'SELECT MAX(StartDate) AS StartDate, StopDate, Consolidated FROM WorkingPeriods' -DataSource $IdleDB | ForEach-Object {
                    if ($null -ne $_.StartDate) {
                        [PSCustomObject] @{ 
                            StartDate    = [DateTime]$_.StartDate
                            StopDate     = [DateTime]$_.StopDate
                            Consolidated = $_.Consolidated
                        }
                    }
                }
            }
            catch {
                Write-Error $_
            }
        }

        function Stop-Period {
            param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $StopDate
            )
            try {
                Invoke-SqliteQuery -Query 'UPDATE WorkingPeriods SET StopDate = @StopDate, Consolidated = 1 WHERE Consolidated = 0' -DataSource $IdleDB -SqlParameters @{
                    StopDate = $StopDate.ToString($SQLITE_DATE_FMT)
                }
            }
            catch {
                Write-Error $_
            }
        }
        function Format-Time {
            param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $Date
            )
            return $Date.ToString('%H:%m')
        }
    }
    Process {

        if ($InitDB) {
            try {
                Invoke-SqliteQuery -Query 'CREATE TABLE IF NOT EXISTS WorkingPeriods ( StartDate TEXT, StopDate TEXT, Consolidated BOOLEAN NOT NULL CHECK (Consolidated IN (0, 1)));' -DataSource $IdleDB
                Write-Host "DB '$IdleDB' initialized OK" -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }      
            return
        }

        if ($Schedule) {
            # Ref: https://devblogs.microsoft.com/scripting/use-powershell-to-create-scheduled-tasks/ 
            $Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "Import-Module -Force -Global Custom ; Register-Idle"'
            $Trigger = New-ScheduledTaskTrigger -AtLogOn
            Register-ScheduledTask -TaskName 'Register-Idle' -Description 'Register idle periods' -Action $Action -Trigger $Trigger
            Write-Host "Check that the trigger for the 'Register-Idle' task is set to be execute AtLogon" -ForegroundColor Green
            return
        }
        

        if ($Dump) {
            if ($ByDay) {
                $Result = Invoke-SqliteQuery -Query "SELECT StartDate, Consolidated, SUM(strftime('%s', StopDate) - strftime('%s', StartDate)) AS DeltaSecond FROM WorkingPeriods GROUP BY strftime('%Y%m%d', StartDate) ORDER BY StartDate" -DataSource $IdleDB
                $FormatBlock = { [PSCustomObject] @{ 'Date' = ([DateTime]$_.StartDate).Date ; 'Hours' = [System.Math]::Truncate($_.DeltaSecond / 3600) ; 'Minutes' = [System.Math]::Truncate(($_.DeltaSecond % 3600) / 60) } }
            }
            elseif ($ByWeek) {
                $Result = Invoke-SqliteQuery -Query "SELECT strftime('%W', StartDate) AS Week, Consolidated, SUM(strftime('%s', StopDate) - strftime('%s', StartDate)) AS DeltaSecond FROM WorkingPeriods GROUP BY strftime('%Y%W', StartDate) ORDER BY StartDate" -DataSource $IdleDB
                $FormatBlock = { [PSCustomObject] @{ 'Week' = $_.Week ; 'Hours' = [System.Math]::Truncate($_.DeltaSecond / 3600) ; 'Minutes' = [System.Math]::Truncate(($_.DeltaSecond % 3600) / 60) } }
            }
            else {
                $Result = Invoke-SqliteQuery -Query 'SELECT * FROM WorkingPeriods ORDER BY StartDate' -DataSource $IdleDB
                $FormatBlock = { $_ }
            }
            if ($Readable) {
                $Result | ForEach-Object $FormatBlock
            }
            else {
                $Result
            }                    
            return
        }

        Set-StrictMode -Version 3

        # First killing residual scripts... 
        $Process = Get-ProcessCommandLine -Name powershell | Where-Object { $_.CommandLine -match 'Register-Idle' -and $PID -ne $_.ProcessId } 
        if ($null -ne $Process) {
            Stop-Process $Process.ProcessId
        }

        Start-Transcript -Force -Append -Path $Log

        # I only register working periods
        While ($true) {
            $Now = Get-Date
            # First determine whether idle or working
            $IdleTime = [Math]::Floor([Decimal] (Get-IdleTime).TotalMinutes)
            if ($IdleTime -lt $MinBreakTimeInMinutes) {
                # three main cases
                # Restart from a suspended period (unconsolidated period that is older than $MinBreakTimeInMinutes)
                # Restart from an idle period (consolidated period older than $MinBreakTimeInMinutes)
                # Still working (unconsolidated period later than $MinBreakTimeInMinutes)
                $LastPeriod = Get-LastPeriod
                if ($null -eq $LastPeriod -or $LastPeriod.Consolidated) {
                    # Start new working period ...
                    Start-Period $Now $Now
                    Write-Host ("[$Now] | (Last is Consolidated): Start @ $(Format-Time $Now).")
                }
                elseif ($LastPeriod.StopDate -lt $Now.AddMinutes( - $MinBreakTimeInMinutes)) {
                    # we were suspended, stop previous period and start a new one
                    Stop-Period $LastPeriod.StopDate
                    Start-Period $Now $Now
                    Write-Host ("[$Now] | (Last is Not consolidated): Stop @ $(Format-Time $LastPeriod.StopDate). Start @ $(Format-Time $Now).")
                }
                else {
                    # Still working... just updating the current period
                    Update-Period $Now
                    Write-Verbose ("[$Now] | (Last is Not consolidated): Update @ $(Format-Time $Now).")
                }
            }
            elseif ($IdleTime -eq $MinBreakTimeInMinutes) {
                # Stop last period
                $StartIdleTime = $Now.AddMinutes( - $IdleTime)
                Stop-Period $StartIdleTime
                Write-Host "[$Now] | Idle Time = MinBreakTime ($MinBreakTimeInMinutes): Stopped Working period @ $StartIdleTime"
            }
            else {
                Write-Verbose "[$Now] | Idle Time > MinBreakTime ($MinBreakTimeInMinutes): Not doing anything ..."
            }
            Start-Sleep -Milliseconds (60 * 1000)
        }
        Stop-Transcript
    }
}