#-----------------------------------------------------------------------------
#
# MODULES 
#
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
#$Packages = "PowerShellCookbook", "AWS.Tools.Installer"
#Foreach ($Package in $Packages) {
#    if (-not (Get-Module -ListAvailable $Package)) { 
#        Write-Host "Installing $Package ..."
#        Install-Module -Name $Package -Scope CurrentUser -AllowClobber -Force
#    }
#}

# The Custom module with some usefull functions
Import-Module -Name Custom

#-----------------------------------------------------------------------------
#
# ALIASES 
#
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name more -Value Format-Page
Set-Alias -Name less -Value Format-Page
Set-Alias -Name gh -Value Get-Help

New-DynamicVariable GLOBAL:WindowTitle `
-Getter { $host.UI.RawUI.WindowTitle } `
-Setter { $host.UI.RawUI.WindowTitle = $args[0] }

#-----------------------------------------------------------------------------
#
# Misc 
#
# The output of the last output is always available in $__ 
$PSDefaultParameterValues["Out-Default:OutVariable"] = "__"

# Loading Oh-My-Posh theme
$Env:POSH_THEMES_PATH = "$Env:USERPROFILE\.poshthemes"
oh-my-posh init pwsh --config "$Env:POSH_THEMES_PATH\default.omp.yaml" | Invoke-Expression

