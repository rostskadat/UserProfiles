$SQLITE_DATE_FMT = "yyyy-MM-dd'T'HH:mm:ss"
<#
    
.SYNOPSIS

Register idle time in an SQLite DB. Useful to incurr your time

.EXAMPLE

PS > Register-Breaks -InitDB
Initialize the SQLite DB and exit

PS > Register-Breaks -Dump | Export-Csv -Path Break.csv
Enter a loop to register idle time during the day

PS > Register-Breaks -DumpWork | Select-Object { ([DateTime]$_.StartDate).Date ; $_.DeltaSecond / 3600 } ([DateTime]$_.StartDate).Date ; $_.DeltaSecond / 3600
-------------------------------------------------------
{14/10/2022 0:00:00, 7,40722222222222}
{17/10/2022 0:00:00, 8,70472222222222}
{18/10/2022 0:00:00, 7,57277777777778}

Gives you an idea of the time you spent working 

#>
function Register-Breaks {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $BreakDB = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Break.db'),
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $BreakLog = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Break.log'),
        [ValidateRange(1, 10)]
        [int16] 
        $MinBreakTimeInMinutes = 7,
        [Parameter(HelpMessage = 'Whether the Break database should be initialized or not')]
        [switch]
        $InitDB = $false,
        [Parameter(HelpMessage = 'Whether to dump the Break database. You can use it in conjunction with Export-Csv')]
        [switch]
        $DumpRaw = $false,
        [Parameter(HelpMessage = 'Whether to dump the Break database group by period.')]
        [switch]
        $DumpWork = $false
    )
    Begin {
        if (-not (Get-Module -ListAvailable PSSQLite)) { 
            Write-Host 'Installing PSSQLite ...'
            Install-Module -Name PSSQLite -Scope CurrentUser -AllowClobber -Force
            Import-Module -Name PSSQLite
        }
        <#
    
        .SYNOPSIS
    
        Start a period in the DB
    
        #>
        function Start-Period {
            param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $StartDate,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [DateTime]
                $StopDate,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]
                $Status
            )
            try {
                Invoke-SqliteQuery -Query 'INSERT INTO Break (StartDate, StopDate, Status, Consolidated) VALUES (@StartDate, @StopDate, @Status, 0)' -DataSource $BreakDB -SqlParameters @{
                    StartDate = $StartDate.ToString($SQLITE_DATE_FMT)
                    StopDate  = $StopDate.ToString($SQLITE_DATE_FMT)
                    Status    = $Status
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
                Invoke-SqliteQuery -Query 'UPDATE Break SET StopDate = @StopDate WHERE Consolidated = 0' -DataSource $BreakDB -SqlParameters @{
                    StopDate = $StopDate.ToString($SQLITE_DATE_FMT)
                }
            }
            catch {
                Write-Error $_
            }
        }

        function Get-LastPeriod {
            try {
                Invoke-SqliteQuery -Query 'Select MAX(StartDate) AS StartDate, StopDate FROM Break WHERE Consolidated = 0' -DataSource $BreakDB | ForEach-Object {
                    if ($null -ne $_.StartDate) {
                        [PSCustomObject] @{ 
                            StartDate = [DateTime]$_.StartDate
                            StopDate  = [DateTime]$_.StopDate
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
                Invoke-SqliteQuery -Query 'UPDATE Break SET StopDate = @StopDate, Consolidated = 1 WHERE Consolidated = 0' -DataSource $BreakDB -SqlParameters @{
                    StopDate = $StopDate.ToString($SQLITE_DATE_FMT)
                }
            }
            catch {
                Write-Error $_
            }
        }
    }
    Process {

        if ($InitDB) {
            try {
                Invoke-SqliteQuery -Query 'CREATE TABLE IF NOT EXISTS Break ( StartDate TEXT, StopDate TEXT, Status TEXT, Consolidated BOOLEAN NOT NULL CHECK (Consolidated IN (0, 1)));' -DataSource $BreakDB
                # Bootstrapping an initial register
                $Yesterday = (Get-Date).AddDays(-1).Date
                Start-Period $Yesterday $Yesterday ([Status]::Idle).ToString()
                # NOTE: I leave it open in order to simulate the fact that the last
                #   execution was either interrupted or the computer might have been
                #   suspended
                Write-Host "DB '$BreakDB' initialized OK" -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }            
            return
        }
        
        if ($DumpRaw) {
            Invoke-SqliteQuery -Query 'SELECT * FROM Break;' -DataSource $BreakDB
            return
        }

        if ($DumpWork) {
            Invoke-SqliteQuery -Query "SELECT StartDate, SUM(strftime('%s', StopDate) - strftime('%s', StartDate)) AS DeltaSecond FROM Break WHERE Status = 'Working' AND Consolidated = '1' GROUP BY strftime('%Y%m%d', StartDate)" -DataSource $BreakDB
            return
        }

        # Start-Transcript -Path $BreakLog

        Set-StrictMode -Version 3

        # First killing residual scripts... 
        Get-ProcessCommandLine -Name powershell | 
            Where-Object { $_.CommandLine -match 'Register-Breaks' -and $PID -ne $_.ProcessId } | 
            Stop-Process 

        $StartIdleTime = $null

        While ($true) {
            $Now = Get-Date
            # First determine whether idle or working
            $IdleTime = [Math]::Floor([Decimal] (Get-IdleTime).TotalMinutes)
            if ($IdleTime -eq 0) {
                # currently working ...
                # Let's get the latest unconsolidated period, to find out whether
                #   we have been suspended since the last write to DB.
                $LastPeriod = Get-LastPeriod
                if ($null -ne $LastPeriod -and $LastPeriod.StartDate.Date -ne $Now.Date) {
                    Write-Host ("[$Now] | Detected suspended period since " + $LastPeriod.StopDate + ' ... Reseting counters.')
                    # the computer was suspended. I need to stop the last consolidated period
                    Stop-Period $LastPeriod.StopDate
                    # And reset a few counters...
                    Start-Period $Now $Now ([Status]::Working).ToString()
                }
                elseif ($null -ne $StartIdleTime) {
                    # we were idle until now
                    $RealIdleTime = [Math]::Floor([Decimal] ($Now - $StartIdleTime).TotalMinutes)
                    if ($RealIdleTime -ge $MinBreakTimeInMinutes) {
                        # This was a real break ...
                        Stop-Period $Now
                        Start-Period $Now $Now ([Status]::Working).ToString()
                        Write-Host "[$Now] | Idle Time (0'): Idle Period ($StartIdleTime -> $Now) -> Work period ($Now -> ...)"
                    }
                    else {
                        Write-Host "[$Now] | Idle Time ($RealIdleTime ' < ${MinBreakTimeInMinutes}): not doing anyting yet ..."
                        # Still working ...
                        Update-Period $Now
                    }
                }
                else {
                    # Still working ...
                    Update-Period $Now
                    if ($null -ne $LastPeriod) {
                        $sd = $LastPeriod.StartDate
                    }
                    else {
                        $sd = '...'
                    }
                    Write-Host "[$Now] | Idle Time (0'): Updating working Period ($sd -> ${Now})"
                }
                $StartIdleTime = $null
            }
            elseif ($IdleTime -eq 1) {
                Update-Period $Now
                $StartIdleTime = $Now.AddMinutes( - 1)
                Write-Host "[$Now] | Idle Time (= 1'): Registering StartIdleTime = $StartIdleTime ..."
            }
            elseif ($IdleTime -eq $MinBreakTimeInMinutes) {
                Stop-Period $StartIdleTime
                Start-Period $StartIdleTime $Now ([Status]::Idle).ToString()
                Write-Host "[$Now] | Idle Time (= MinBreakTime): Work period (... -> $StartIdleTime) -> Idle period ($StartIdleTime -> $Now)"
            }
            elseif ($IdleTime -gt $MinBreakTimeInMinutes) {
                Update-Period $Now
                Write-Host "[$Now] | Idle Time (> MinBreakTime) > $MinBreakTimeInMinutes : Updating Idle period $StartIdleTime -> $Now..."
            }
            Start-Sleep -Milliseconds (60 * 1000)
        }
        # Stop-Transcript
    }
}