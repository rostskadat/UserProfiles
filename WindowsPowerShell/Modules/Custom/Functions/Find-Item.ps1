function Find-Item {
    ##############################################################################
    ##
    ## Find-Item
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Find all child element whose name matches the given pattern
    
    .EXAMPLE
    
    PS > Find-Item '.txt' -Recurse 
    Find all the txt file in the current directory
    
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


