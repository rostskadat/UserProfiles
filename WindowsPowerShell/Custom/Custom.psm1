#$CUSTOM_MODULE_PATH = Split-Path (Get-Module -ListAvailable Custom).path
#$CUSTOM_MODULE_PATH = $PSScriptRoot
$CUSTOM_MODULE_PATH = [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell\Modules\Custom"

Set-StrictMode -Version 3

# $executionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
#     param($CommandName, $CommandLookupEventArgs)
#     ## Stores a hashtable of the commands we use most frequently
#     if(-not (Test-Path variable:\CommandCount)) {
#         $global:CommandCount = @{}
#     }
#     ## If it was launched by us (rather than as an internal helper
#     ## command), record its invocation.
#     if($CommandLookupEventArgs.CommandOrigin -eq "Runspace") {
#         $commandCount[$CommandName] = 1 + $commandCount[$CommandName]
#     }
# }

Import-Module -Force -Global ($CUSTOM_MODULE_PATH + "\CommandNotFoundAction.psm1")
Import-Module -Force -Global ($CUSTOM_MODULE_PATH + "\Wait-ForMe.psm1")
#Import-Module -Force -Global ($CUSTOM_MODULE_PATH + "\Show-LastReboot.psm1")
Import-Module -Force -Global ($CUSTOM_MODULE_PATH + "\Search-Web.psm1")
Import-Module -Force -Global ($CUSTOM_MODULE_PATH + "\Search-Jar.psm1")
Import-Module -Force -Global ($CUSTOM_MODULE_PATH + "\Format-Page.psm1")
