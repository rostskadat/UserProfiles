
# Declare assemblies 
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null
        
# Create object for the systray 
$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$NotifyIcon.Text = 'Register Breaks'
$NotifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Windows\System32\mmc.exe')
$NotifyIcon.Visible = $true
         
# First menu displayed in the Context menu
$BreakMenu = New-Object System.Windows.Forms.MenuItem
$BreakMenu.Text = 'Break ...'
         
# Fourth menu displayed in the Context menu - This will close the systray tool
$MenuExit = New-Object System.Windows.Forms.MenuItem
$MenuExit.Text = 'Exit'
         
# Create the context menu for all menus above
$NotifyIcon.ContextMenu = New-Object System.Windows.Forms.ContextMenu
$NotifyIcon.contextMenu.MenuItems.AddRange($BreakMenu)
$NotifyIcon.contextMenu.MenuItems.AddRange($MenuExit)
         
# Create submenu for the menu 1
$WriteTodaysBreaks = $BreakMenu.MenuItems.Add('Write today''s break to file')
$WriteTodaysBreaks.Add_Click({ 
        [System.Windows.Forms.MessageBox]::Show('Menu 1 - Submenu 1')
    })

# When Exit is clicked, close everything and kill the PowerShell process
$MenuExit.add_Click({
        $NotifyIcon.Visible = $false
        $window.Close()

        $Global:Timer_Status = $timer.Enabled
        If ($Timer_Status -eq $true) {
            $timer.Stop() 
        } 
        Stop-Process $pid
    })

$FunctionDefinition = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$MemberDefinition = Add-Type -MemberDefinition $FunctionDefinition -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$null = $MemberDefinition::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
             
# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()

$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)