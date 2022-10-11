Set-StrictMode -Version 3

$CUSTOM_MODULE_PATH = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-ChildItem "$CUSTOM_MODULE_PATH\Scripts" '*.ps1' -File |
    ForEach-Object { 
        . $_.FullName
    }

Get-ChildItem "$CUSTOM_MODULE_PATH\Functions" "*.ps1" -File  |
    ForEach-Object { 
        try {
            . $_.FullName 
            Export-ModuleMember -Function $_.BaseName
        }
        catch {
            Write-Error -Message "Failed to import function: $_"
        }
    }


