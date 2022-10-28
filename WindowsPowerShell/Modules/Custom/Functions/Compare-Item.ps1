function Compare-Item {
    ##############################################################################
    ##
    ## Compare-Item
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Compare 2 files
    
    .EXAMPLE
    
    PS > Compare-Item file1.txt file2.txt
    Find all the difference between the 2 files
    
    #>
    [CmdletBinding()]
    Param(
        ## The term to search for
        [Parameter(Mandatory = $true, HelpMessage = 'The first file to compare')]
        [ValidateNotNullOrEmpty()]
        $Path1,
        [Parameter(Mandatory = $true, HelpMessage = 'The second file to compare')]
        [ValidateNotNullOrEmpty()]
        $Path2,
        [Parameter(HelpMessage = 'Wether the file content should be sorted first')]
        [switch]
        $Sort = $false,
        [Parameter(HelpMessage = 'Wether the file content should be filtered to be unique')]
        [switch]
        $Unique = $false
    )
    Set-StrictMode -Version 3

    $Content1 = Get-Content $Path1
    $Content2 = Get-Content $Path2

    if ($Sort) {
        $Content1 = $Content1 | Sort-Object
        $Content2 = $Content2 | Sort-Object
    }

    if ($Unique) {
        $Content1 = $Content1 | Get-Unique
        $Content2 = $Content2 | Get-Unique
    }

    Compare-Object $Content1 $Content2
}


