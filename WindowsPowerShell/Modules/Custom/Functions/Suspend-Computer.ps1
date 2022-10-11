function Suspend-Computer {
    ##############################################################################
    ##
    ## Suspend-Computer
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Suspend the computer
    
    .EXAMPLE
    
    PS > Suspend-Computer
    Suspend the computer
    
    #>
    [CmdletBinding()]
    Param(
        ## how many second to wait before suspending
        $Seconds = 0
    )
    Set-StrictMode -Version 3

    if ($Seconds -gt 0) {
        Write-Host "Suspending in $Seconds second(s) ..."
    } else {
        Write-Host "Suspending now ..."
    }
    Start-Sleep -Seconds:$Seconds 

    Add-Type -Assembly System.Windows.Forms | Out-Null
    [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false)
}


