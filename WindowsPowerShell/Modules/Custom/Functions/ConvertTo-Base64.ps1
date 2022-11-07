function ConvertTo-Base64 {
    ##############################################################################
    ##
    ## ConvertTo-Base64
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Convert a text to base 64
    
    .EXAMPLE
    
    PS > ConvertTo-Base64 "text"
    Convert the text to base64
    
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, HelpMessage = 'The text to convert to base64')]
        [ValidateNotNullOrEmpty()]
        $Text
    )
    Set-StrictMode -Version 3

    [System.Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Text))
}


