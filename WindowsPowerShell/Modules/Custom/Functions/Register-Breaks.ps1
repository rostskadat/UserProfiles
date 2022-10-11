$SQLITE_DATE_FMT = "yyyy-MM-dd'T'HH:mm:ss"
<#
    
.SYNOPSIS

Register idle time in an SQLite DB. Useful to incurr your time

.EXAMPLE

PS > Register-Breaks -InitDB
Initialize the SQLite DB and exit

PS > Register-Breaks -Dump | Export-Csv -Path Break.csv
Enter a loop to register idle time during the day

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
        $Dump = $false
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

        if ($InitDB) {
            
            try {
                Invoke-SqliteQuery -Query 'CREATE TABLE IF NOT EXISTS Break ( StartDate TEXT, StopDate TEXT, Status TEXT, Consolidated BOOLEAN NOT NULL CHECK (Consolidated IN (0, 1)));' -DataSource $BreakDB
                Write-Host "DB '$BreakDB' initialized OK" -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }
    }
    Process {
        if ($InitDB) {
            return
        }
        
        if ($Dump) {
            Invoke-SqliteQuery -Query 'SELECT * FROM Break;' -DataSource $BreakDB
            return
        }

        Set-StrictMode -Version 3

        # First killing residual scripts... 
        Get-ProcessCommandLine -Name powershell | 
            Where-Object { $_.CommandLine -match 'Register-Breaks' -and $PID -ne $_.ProcessId } | 
            Stop-Process 

        Set-Content -Path $BreakLog -Value '# Log file for Register-Break ...'

        $StartIdleTime = $null

        $Now = Get-Date
        Start-Period $Now $Now ([Status]::Working).ToString()

        While ($true) {
            $Now = Get-Date
            # First determine whether idle or working
            $IdleTime = [Math]::Floor([Decimal] (Get-IdleTime).TotalMinutes)
            if ($IdleTime -eq 0) {
                # currently working ...
                if ($null -ne $StartIdleTime) {
                    $RealIdleTime = [Math]::Floor([Decimal] ($Now - $StartIdleTime).TotalMinutes)
                    # This was a real break ...
                    if ($RealIdleTime -ge $MinBreakTimeInMinutes) {
                        Stop-Period $Now
                        Start-Period $Now $Now ([Status]::Working).ToString()
                        Add-Content -Path $BreakLog -Value "[$Now] | Idle period $StartIdleTime -> $Now -> Work period -> $Now"
                    }
                    else {
                        Add-Content -Path $BreakLog -Value "[$Now] | Idle Time ($RealIdleTime ') < ${MinBreakTimeInMinutes}: not doing anyting yet ..."
                        # Still working ...
                        Update-Period $Now
                    }
                }
                else {
                    # Still working ...
                    Update-Period $Now
                    Add-Content -Path $BreakLog -Value "[$Now] | Updating Period with @ ${Now} ..."
                }
                $StartIdleTime = $null
            }
            elseif ($IdleTime -eq 1) {
                Update-Period $Now
                $StartIdleTime = $Now.AddMinutes( - 1)
                Add-Content -Path $BreakLog -Value "[$Now] | Idle Time (= 1'): Registering StartIdleTime to $StartIdleTime ..."
            }
            elseif ($IdleTime -eq $MinBreakTimeInMinutes) {
                Stop-Period $StartIdleTime
                Start-Period $StartIdleTime $Now ([Status]::Idle).ToString()
                Add-Content -Path $BreakLog -Value "[$Now] | Idle Time (= MinBreakTime): Work period -> $StartIdleTime -> Idle period -> $StartIdleTime -> $Now ..."
            }
            elseif ($IdleTime -gt $MinBreakTimeInMinutes) {
                Update-Period $Now
                Add-Content -Path $BreakLog -Value "[$Now] | Idle Time (> MinBreakTime) > $MinBreakTimeInMinutes : Updating Idle period $StartIdleTime -> $Now..."
            }

            # if ($IdleTime -eq 0) {
            #     $NewStatus = [Status]::Working
            # }
            # else {
            #     $NewStatus = [Status]::Idle
            # }
            # # Then check whether the status has changed
            # $StopPeriod = $NewStatus -ne $LastStatus
            # # Updating DB...
            # if ($StopPeriod) {
            #     Stop-Period $Now
            #     Start-Period $Now $NewStatus
            # }
            # else {
            #     Update-Period $Now
            # }
            # $LastStatus = $NewStatus
            Start-Sleep -Milliseconds (60 * 1000)
        }        
    }
}