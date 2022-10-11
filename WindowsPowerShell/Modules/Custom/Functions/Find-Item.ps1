function Find-Item {
    ##############################################################################
    ##
    ## Find-Item
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Set the hidden file attribute on dot files
    
    .EXAMPLE
    
    PS > Find-Item -Recurse
    Hide all dot files recursively
    
    #>
    [CmdletBinding()]
    Param(
        ## The term to search for
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Pattern,
        [Parameter(Mandatory = $false)]
        $Path = '',
        [switch]
        $Recurse = $false,
        [switch]
        $CaseSensitive = $false
    )
    Set-StrictMode -Version 3

    Get-ChildItem -Force -Recurse:$Recurse $Path |
        ForEach-Object { 
            Select-String -Path $_.FullName -CaseSensitive:$CaseSensitive -Pattern $Pattern -ErrorAction SilentlyContinue 
        }
}


