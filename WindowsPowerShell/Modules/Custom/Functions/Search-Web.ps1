function Search-Web {
    ##############################################################################
    ##
    ## Search-Web
    ##
    ## Inspired by Windows PowerShell Cookbook (O'Reilly)
    ## by Lee Holmes (http://www.leeholmes.com/guide)
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Search DuckDuckGo for a given term
    
    .EXAMPLE
    
    PS > Search-Web PowerShell
    Searches DuckDuckGo for the term "PowerShell"
    
    #>
    
    Param(
        ## The term to search for
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Pattern,
        [ValidateSet('DDG', 'Bing')]
        $Engine = 'DDG',
        [Alias("Lucky")]
        [switch]
        $IFeelLucky = $False,
        [Alias("Open")]
        [switch]
        $OpenInBrowser = $False
    )
    $ENGINES = @{
        'DDG'  = @{ 
            'query_url'   = 'https://duckduckgo.com/html/?q={0}'
            'url_pattern' = '.*uddg=([^&]*).*'
        }
        'Bing' = @{
            'query_url'   = 'http://www.bing.com/search?q={0}'
            'url_pattern' = '(.*)'
        }
    }
    Set-StrictMode -Version 3
    
    ## Create the URL that contains the Twitter search results
    Add-Type -Assembly System.Web
    $queryUrl = $ENGINES[$Engine]['query_url']
    $queryUrl = $queryUrl -f ([System.Web.HttpUtility]::UrlEncode($pattern))
    
    ## Download the web page
    $response = Invoke-WebRequest $queryUrl

    $HTML = New-Object -Com 'HTMLFile'
    $HTML.IHTMLDocument2_write($response.Content)
    
    ## Extract the text of the results, which are contained in
    ## segments that look like "<div class="b_title">...</div>"
    if ($Engine -eq 'DDG') {
        $results = $HTML.getElementsByTagName('a') | Where-Object { 
            $_.getAttributeNode('class').nodeValue -eq 'result__a' 
        }
    }
    else {
        $results = ($HTML.getElementsByTagName('div') | Where-Object { 
            $_.getAttributeNode('class').nodeValue -eq 'b_title' 
        }).getElementsByTagName("a") | Select-Object -Property href,innertext | Where-Object {$null -ne $_.innerText}
    }

    foreach ($result in $results) {
        ## Extract the URL, keeping only the text inside the quotes
        ## of the HREF
        $Url = [System.Web.HttpUtility]::UrlDecode($result.href)
        $Url = $Url -replace $ENGINES[$Engine]['url_pattern'], '$1'
    
        ## Extract the page name,  replace anything in angle
        ## brackets with an empty string.
        $Title = $result.innerText
    
        ## Output the item
        [PSCustomObject] @{ Title = $Title; Url = $Url }
        if ($OpenInBrowser) {
            Start-Process $Url
            break
        }
        if ($IFeelLucky) {
            break
        }
    }
}