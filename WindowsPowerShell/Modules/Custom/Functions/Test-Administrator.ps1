function Test-Administrator {
    ##############################################################################
    ##
    ## Test-Administrator
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Test whether the current user is in the Admin group
    
    .EXAMPLE
    
    PS > Test-Administrator 
    Test if the current user is in the Administrator group
    
    #>
    Set-StrictMode -Version 3

    if ([environment]::OSVersion.Platform -eq 'Unix') {
        Write-Warning "This cmdlet is not available on this platform."
        return $false
    }

    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
