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
        [Parameter()]
        [string]
        $Username,
        [Parameter()]
        [string]
        $Password,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Location = 'East US',
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $TenantId = '47da9ac4-f585-4753-bf40-7c7c8fe635cf', # The "Pluralsight Labs Production" tenant...
        [Parameter()]
        $ResourceGroup
    )
    Set-StrictMode -Version 3

    try {
        if ($Username -and $Password) {
            Write-Debug "Connecting as $Username / $TenantId ..."
            $SecureString = $Password | ConvertTo-SecureString -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureString
            Connect-AzAccount -Credential $Credential -TenantId $TenantId
        }
        else {
            Write-Debug 'Connecting interactively ...'
            Connect-AzAccount
        }
        if ($null -ne $ResourceGroup) {
            Set-AzDefault -ResourceGroupName $ResourceGroup
        }
        $ServicePrincipal = Get-AzADApplication -DisplayName 'WindowsPowerShellLab' | Select-Object -First 1
        if (-not $ServicePrincipal) {
            Write-Debug "Creating ServicePrincipal for Lab session as 'Contributor' ..."
            $ServicePrincipal = New-AzADServicePrincipal -DisplayName 'WindowsPowerShellLab' -Role 'Contributor'
            $env:ARM_CLIENT_ID = $ServicePrincipal.AppId
            $env:ARM_CLIENT_SECRET = $ServicePrincipal.PasswordCredentials.SecretText
        }
        else {
            Write-Debug "Reusing existing ServicePrincipal $($ServicePrincipal.Id) ..."
            # Creating a new credential for that session...
            $StartDate = Get-Date
            $EndDate = $startDate.AddYears(1)
            $AppCredential = New-AzADAppCredential -ObjectId $ServicePrincipal.Id -StartDate $StartDate -EndDate $EndDate
            $env:ARM_CLIENT_ID = $ServicePrincipal.AppId
            $env:ARM_CLIENT_SECRET = $AppCredential.SecretText
        }

        $Subscription = Get-AzSubscription
        $env:ARM_SUBSCRIPTION_ID = $Subscription.Id
        $env:ARM_TENANT_ID = $Subscription.TenantId
        Write-Host -ForegroundColor Green "Once the Lab finished you can call the 'Disconnect-AzAccount' cmdlet" 
    }
    catch {
        Write-Warning $_
    }

    # Ref: https://geeksarray.com/blog/get-azure-subscription-tenant-client-id-client-secret
    # AZURE_CLIENT_ID: the application's client ID
    # AZURE_USERNAME: a username (usually an email address)
    # AZURE_PASSWORD: that user's password
    # AZURE_TENANT_ID: (optional) ID of the service principal's tenant. Also called its 'directory' ID. If not provided, defaults to the 'organizations' tenant, which supports only Azure Active Directory work or school accounts.
    # AZURE_AUTHORITY_HOST: authority of an Azure Active Directory endpoint, for example "login.microsoftonline.com", the authority for Azure Public Cloud, which is the default when no value is given.

}