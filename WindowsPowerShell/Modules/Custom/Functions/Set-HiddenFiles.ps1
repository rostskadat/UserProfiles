function Set-HiddenFiles {
    ##############################################################################
    ##
    ## Set-HiddenFiles
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Set the hidden file attribute on dot files
    
    .EXAMPLE
    
    PS > Set-HiddenFiles -Recurse
    Hide all dot files recursively
    
    #>
    [CmdletBinding()]
    Param(
        ## The term to search for
        [switch]
        $Recurse = $False,
        [switch]
        $Show = $False
    )
    Set-StrictMode -Version 3

    $files = Get-ChildItem -Force -Recurse:$Recurse -ErrorAction SilentlyContinue
    $files = $files | Where-Object {$_.Name -match '^\..*'}
    if (-not $Show) {
        Write-Host "Hiding $($files.Length) files ..."
        $files | ForEach-Object { $_.Attributes += 'Hidden'}
    } else { 
        Write-Host "Showing $($files.Length) files ..."
        $files | ForEach-Object { $_.Attributes -= 'Hidden'}
    }
}