function ConvertFrom-Base64 {
    ##############################################################################
    ##
    ## ConvertFrom-Base64
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Convert a text from base64
    
    .EXAMPLE
    
    PS > ConvertFrom-Base64 "base64"
    Convert the text from base64
    
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, HelpMessage = 'The text to convert from base64')]
        [ValidateNotNullOrEmpty()]
        $Base64
    )
    Set-StrictMode -Version 3

    [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($Base64))
}


