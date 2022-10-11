function Get-ProcessCommandLine {
    ##############################################################################
    ##
    ## Get-ProcessCommandLine
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Return process command line
    
    .EXAMPLE
    
    PS > Get-ProcessCommandLine $pid

    
    #>
    [CmdletBinding()]
    Param(
        ## The term to search for
        [string]
        $Name,
        [double]
        $ProcessId,
        [string]
        $ExecutablePath,
        [string]
        $CommandLine
    )
    Set-StrictMode -Version 3
    $Parameters = $PSCmdlet.MyInvocation.BoundParameters
    if ($Parameters.Keys.Contains("Name")) {
        $Criteria = "WHERE {0} LIKE '%{1}%'" -f ("Name", $Parameters["Name"])    
    } elseif ($Parameters.Keys.Contains("ProcessId")) {
        $Criteria = "WHERE {0} = {1}" -f ("ProcessId", $Parameters["ProcessId"])    
    } elseif ($Parameters.Keys.Contains("ExecutablePath")) {
        $Criteria = "WHERE {0} LIKE '%{1}%'" -f ("ExecutablePath", $Parameters["ExecutablePath"])    
    } elseif ($Parameters.Keys.Contains("CommandLine")) {
        $Criteria = "WHERE {0} LIKE '%{1}%'" -f ("CommandLine", $Parameters["CommandLine"])    
    } else {
        $Criteria = ""
    }
    [wmisearcher]::new( "SELECT Name, ProcessId, ExecutablePath, CommandLine FROM Win32_Process {0}" -f $Criteria).Get()
}