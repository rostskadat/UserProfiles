function Start-AzLab {
    ##############################################################################
    ##
    ## Start-AzLab
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    This will start an Azure Lab by login in into the console and setting common element (mainly location and default resource group)
    
    .EXAMPLE
    
    PS > Start-AzLab
    Start a Azure Lab
    
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Username,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Password,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Location = "East US",
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $ResourceGroup = "pluralsight-resource-group"
    )
    Set-StrictMode -Version 3

#    Get-AzTenant -TenantId 47da9ac4-f585-4753-bf40-7c7c8fe635cf
#    Id                                   Name                        Category Domains
#    --                                   ----                        -------- -------
#    47da9ac4-f585-4753-bf40-7c7c8fe635cf Pluralsight Labs Production Home     {psLabsProd.onmicrosoft.com, prod.pluralsightlabs.com}
    $SecureString = $Password | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureString
    Connect-AzAccount -Credential $Credential -ServicePrincipal

    Set-AzDefault -ResourceGroupName $ResourceGroup

    # Doing the same for az cli
#    az login
#    az config set "defaults.location=$Location"
#    az config set defaults.group=$ResourceGroup
}