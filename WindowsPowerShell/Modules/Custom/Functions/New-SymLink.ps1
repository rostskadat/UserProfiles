function New-SymLink {
    ##############################################################################
    ##
    ## New-SymLink
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    A wrapper around the 'New-Item' to create a Symlink
    
    .EXAMPLE
    
    PS > New-SymLink -Source C:\Path\to\Source -Target C:\Path\to\Target
    Create the Target Symlink pointing to Source
    
    #>
    [CmdletBinding()]
    Param(
        ## The term to search for
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Source,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Target
    )
    Set-StrictMode -Version 3

    if (Test-Administrator) {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source
    }
    else {
        $ArgumentList = "-NoProfile -WindowStyle Hidden & `"New-Item -ItemType SymbolicLink -Path $Target -Target $Source`""
        Start-Process powershell -Verb runAs -WindowStyle Hidden -ArgumentList $ArgumentList
    }
}





