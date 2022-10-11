Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

#------------------------------------------------------------------------------
#
# As Administrator: execute the following command
#

#$Packages = "PowerShellCookbook", "Az"
#Foreach ($Package in $Packages) {
#    if (-not (Get-Module -ListAvailable $Package)) { 
#        Write-Host "Installing $Package ..."
#        Install-Module -Name $Package -Scope AllUsers -AllowClobber -Force
#    }
#}

Import-Module -Name Custom

Set-Alias -Name c -Value Clear-Host
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name more -Value Format-Page
Set-Alias -Name less -Value Format-Page
Set-Alias -Name gh -Value Get-Help
Set-Alias -Name ssc -Value Suspend-Computer

New-DynamicVariable GLOBAL:WindowTitle `
-Getter { $host.UI.RawUI.WindowTitle } `
-Setter { $host.UI.RawUI.WindowTitle = $args[0] }

# The output of the last output is always available in $__ 
$PSDefaultParameterValues["Out-Default:OutVariable"] = "__"

# Avoid sending telemetry from .NET and AZ Function App toolkit
$Env:FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT = 1

# Setting up the Oh-my-posh theme
$Env:POSH_THEMES_PATH = "$Env:USERPROFILE\.poshthemes"
oh-my-posh init pwsh --config "$Env:POSH_THEMES_PATH\default.omp.yaml" | Invoke-Expression