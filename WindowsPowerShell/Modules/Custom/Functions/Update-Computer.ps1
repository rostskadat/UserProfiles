function Update-Computer {
    ##############################################################################
    ##
    ## Update-Computer
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    A wrapper around the 'Get-WindowsUpdate' to update the computer
    
    .EXAMPLE
    
    PS > Update-Computer
    Update the computer
    
    #>
    Set-StrictMode -Version 3

    if (Test-Administrator) {
        Get-WindowsUpdate
    }
    else {
        $ArgumentList = "-NoProfile -WindowStyle Hidden & `"Get-WindowsUpdate`""
        Start-Process powershell -Verb runAs -WindowStyle Hidden -ArgumentList $ArgumentList
    }
}
