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
        $Location = 'East US',
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $TenantId = '47da9ac4-f585-4753-bf40-7c7c8fe635cf',
        [Parameter()]
        $ResourceGroup
    )
    Set-StrictMode -Version 3

    $SecureString = $Password | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureString
    # The "Pluralsight Labs Production" tenant...
    Connect-AzAccount -Credential $Credential -TenantId $TenantId
    if ($null -ne $ResourceGroup) {
        Set-AzDefault -ResourceGroupName $ResourceGroup
    }

    $ServicePrincipal = New-AzADServicePrincipal -DisplayName 'WindowsPowerShellLab' -Role 'Contributor'
    $Subscription = Get-AzSubscription

    $env:ARM_CLIENT_ID = $ServicePrincipal.AppId
    $env:ARM_SUBSCRIPTION_ID = $Subscription.Id
    $env:ARM_TENANT_ID = $Subscription.TenantId
    $env:ARM_CLIENT_SECRET = $ServicePrincipal.PasswordCredentials.SecretText

    Write-Host -ForegroundColor Green "Once the Lab finished you can call the 'Disconnect-AzAccount' cmdlet" 
}