function Search-Jar {
    ##############################################################################
    ##
    ## Search-Jar
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Search for a given class in the Jars found in the current directory
    
    .EXAMPLE
    
    PS > Search-jar com.example.MyClass
    Searches for the class com.example.MyClass in the jars found in the current directory 
    
    #>
    Param(
        ## The class to search for
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Class
    )
    Set-StrictMode -Version 3
    
    ## Create the URL that contains the Twitter search results
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $jars = Get-ChildItem -Recurse *.jar -ErrorAction SilentlyContinue

    foreach ($jar in $jars) {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($jar)
        $archive.Entries | Where-Object { $_.FullName -match $Class } | Select-Object -First 1 | ForEach-Object { $jar.FullName }
    }
}