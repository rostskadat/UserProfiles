Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

if ('Status' -as [type]) {} else {
    Add-Type -TypeDefinition 'public enum Status { Working, Idle }'
}

function Get-IdleTime {
    ##############################################################################
    ##
    ## Get-IdleTime
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Get the number of second since last input
    
    .EXAMPLE
    
    PS > Get-IdleTime
    60
    
    #>
    [CmdletBinding()]
    Param()
    Set-StrictMode -Version 3
    return [PInvoke.Win32.UserInput]::IdleTime
}

function Get-IdleStatus {
    ##############################################################################
    ##
    ## Get-IdleStatus
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    Return whether the current computer is idle or not. It is considered idle
    if nothing has happened for more than one minute.
    
    .EXAMPLE
    
    PS > Get-IdleStatus
    False
    
    #>
    Set-StrictMode -Version 3
    $NewIdleTime = [Math]::Floor([Decimal] (Get-IdleTime).TotalMinutes)
    if ($NewIdleTime -eq 0) {
        return [Status]::Working
    } 
    return [Status]::Idle
    
}