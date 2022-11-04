function Start-DeviceManager {
    ##############################################################################
    ##
    ## Start-DeviceManager
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    A wrapper around the Device Manager in admin mode
    
    .EXAMPLE
    
    PS > Start-DeviceManager
    Start the Device Manager in admin mode
    
    #>
    Set-StrictMode -Version 3

    if (Test-Administrator) {
        mmc.exe "devmgmt.msc"
    }
    else {
        Start-Process mmc.exe -Verb RunAs -ArgumentList "devmgmt.msc"
    }
}


