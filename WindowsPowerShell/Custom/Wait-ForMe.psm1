<#
 .Synopsis
  Periodically move the mouse to avoid the computer to go idle.

 .Description
  The function will periodically move the mouse (every 'Every' seconds) in order to avoid the computer to go to sleep. This is usefull for instance, when you are connected to a remote system that monitors whether the connection is idle or not.

 .Parameter Every
  The number of seconds to wait before moving the mouse.

 .Example
   # Move the mouse every 5 seconds.
   Wait-ForMe
#>
function Wait-ForMe {
    Param(
        [ValidateRange(1,60)]
        [int16] 
        $Every = 5
    )
    Process {
        Add-Type -AssemblyName System.Windows.Forms
        while ($true) {
            $Position = [System.Windows.Forms.Cursor]::Position
            $x = ($Position.X) + 10
            $y = ($Position.Y) + 10
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
            [System.Windows.Forms.Cursor]::Position = $Position
            Start-Sleep -Seconds $Every
        }
    }
}
Export-ModuleMember -Function Wait-ForMe
