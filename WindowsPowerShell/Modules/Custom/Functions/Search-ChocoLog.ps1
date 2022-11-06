function Search-ChocoLog {
    ##############################################################################
    ##
    ## Search-ChocoLog
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Search Choco install log for a given term
    
    .EXAMPLE
    
    PS > Search-ChocoLog PowerShell
    Searches choco install log for the term Powershell
    
    #>
    
    Param(
        ## The term to search for
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Pattern
    )
    Set-StrictMode -Version 3

    if ([environment]::OSVersion.Platform -eq 'Unix') {
        Write-Warning "This cmdlet is not available on this platform."
        return
    }

    $CHOCO_INSTALL_LOG = "C:\ProgramData\chocolatey\logs\chocolatey.log"
    if (Test-Path $CHOCO_INSTALL_LOG) {
        Get-Content $CHOCO_INSTALL_LOG | Select-String $Pattern
    }
}