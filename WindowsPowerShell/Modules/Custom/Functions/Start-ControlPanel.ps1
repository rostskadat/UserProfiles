function Start-ControlPanel {
    ##############################################################################
    ##
    ## Start-DeviceManager
    ##
    ##############################################################################
    
    <#
    
    .SYNOPSIS
    
    A wrapper around the Device Manager in admin mode
    
    .EXAMPLE
    
    PS > Start-ControlPanel
    Start the Device Manager in admin mode
    
    #>
    Param(
        ## The class to search for
        [ValidateSet('AuthorizationManager', 'MachineCertificateManager', 'UserCertificateManager', 
            'ComponentManager', 'ComputerManager', 'DeviceManager', 'DiskManager', 'EventViewer',
            'SharedFolderManager', 'PolicyManager', 'LocalUserManager', 'PerformanceMonitor',
            'PrinterManager', 'SecurityPolicyManager', 'Services', 'TaskScheduler', 'TPMManager', 
            'FirewallManager', 'WMIManager')] 
        [String]
        $ControlPanel = 'DeviceManager'
    )
    Set-StrictMode -Version 3

    $PANELS = @{
        'AuthorizationManager'      = 'azman.msc'
        'MachineCertificateManager' = 'certlm.msc'
        'UserCertificateManager'    = 'certmgr.msc'
        'ComponentManager'          = 'comexp.msc'
        'ComputerManager'           = 'compmgmt.msc'
        'DeviceManager'             = 'devmgmt.msc'        
        'DiskManager'               = 'diskmgmt.msc'
        'EventViewer'               = 'eventvwr.msc'
        'SharedFolderManager'       = 'fsmgmt.msc'
        'PolicyManager'             = 'gpedit.msc'
        'LocalUserManager'          = 'lusrmgr.msc'
        'PerformanceMonitor'        = 'perfmon.msc'
        'PrinterManager'            = 'printmanagement.msc'
        'SecurityPolicyManager'     = 'secpol.msc'
        'Services'                  = 'services.msc'
        'TaskScheduler'             = 'taskschd.msc'
        'TPMManager'                = 'tpm.msc'        
        'FirewallManager'           = 'WF.msc'
        'WMIManager'                = 'WmiMgmt.msc'
    }
    
    if (Test-Administrator) {
        mmc.exe $PANELS[$ControlPanel]
    }
    else {
        Start-Process mmc.exe -Verb RunAs -ArgumentList $PANELS[$ControlPanel]
    }
}


