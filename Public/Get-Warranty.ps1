function Get-Warranty {
    <#
        .SYNOPSIS
        Function to Get warranty info
    
        .DESCRIPTION
        This function will get warranty info of the machine it is called from
    
        .EXAMPLE
        Get-Warranty
        Get-Warranty -Serial "SerialNumber" -Manufacturer "HP" -RMM 'None'
    
        .PARAMETER Serial
        Manually set serial
    
        .PARAMETER Manufacture
        Manually set Manufacturer
    
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
    Param(
        # RMM Mode, available in both Default and CentralNinja sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [ValidateSet('NinjaRMM', 'NinjaRMMAPI', 'None')]
        [String]$RMM = 'NinjaRMM',
        
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [ValidateSet('eu', 'oc', 'us')]
        [String]$NinjaInstance = 'oc',

        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$ninjaorgid,

        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$NinjaSecretkey,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$NinjaAccesskey,

        # Web Driver mode, Edge or Chrome ( Edge Beta Support )
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [ValidateSet('Chrome', 'Edge')]
        [String]$Seleniumdrivermode = 'Chrome',

        # ServerMode, exclusive to CentralNinja but included in Default for consistency
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Switch]$ServerMode,
    
        # Enable Registry Storing
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [bool]$EnableRegistry = $true,

        # Registry Path
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [String]$RegistryPath = 'HKLM:\SOFTWARE\RMMCustomInfo\',
    
        # Force Update RMM with details
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [bool]$ForceUpdate = $false,
    
        # Custom Machine Details, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$Serial = 'Automatic',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$Manufacturer = 'Automatic',
    
        # Set Date formats, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$DateFormat = 'dd-MM-yyyy',
    
        # NinjaRMM Custom Field Names, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$ninjawarrantystart = 'warrantyStart',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$ninjawarrantyexpiry = 'warrantyExpiry',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$ninjawarrantystatus = 'warrantystatus',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$ninjainvoicenumber = 'invoicenumber',

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NinjaAPI')]
        [String]$ninjadeviceage = 'deviceage',

        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$HpSystemSKU
            
    )
    # Print Current Version
    if($RMM -ne 'NinjaRMMAPI'){
        Write-Host "EasyWarrantyCheck Version : 1.1.0"
    }
    # Set localization
    $DateFormat = (Get-Culture).DateTimeFormat.ShortDatePattern
    $DateFormatGlobal = (Get-Culture).DateTimeFormat.ShortDatePattern
    Set-Variable DateFormatGlobal -Value $DateFormatGlobal -Scope Global -option ReadOnly -Force
    # Set Global Variables
    if ($RMM -eq 'NinjaRMM') {
        Set-Variable ninjawarrantystart -Value $ninjawarrantystart -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantyexpiry -Value $ninjawarrantyexpiry -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantystatus -Value $ninjawarrantystatus -Scope Global -option ReadOnly -Force
        Set-Variable ninjainvoicenumber -Value $ninjainvoicenumber -Scope Global -option ReadOnly -Force
        Set-Variable ninjadeviceage -Value $ninjadeviceage -Scope Global -option ReadOnly -Force
    }
    if ($ForceUpdate -eq $true) {
        Set-Variable ForceUpdate -Value $ForceUpdate -Scope Global -option ReadOnly -Force
    }
    if ($Seleniumdrivermode) {
        if($RMM -eq 'NinjaRMMAPI'){
            # Only check Browser support once a day for NinaRMMAPI mode
            if ((Get-date (Get-WarrantyRegistry -ServerLastCheck) -format $DateFormatGlobal) -lt (Get-date -format $DateFormatGlobal)){
                $browsersupport = Test-BrowserSupport -Browser $Seleniumdrivermode
                if ($browsersupport -eq $false) {
                    Set-Variable Browsersupport -Value $false -Scope Global -option ReadOnly -Force
                } 
                Write-WarrantyRegistry -ServerLastCheck
            } else {
                if((Get-WarrantyRegistry -ServerBrowserSupport) -eq 'Chrome'){
                    Set-Variable DriverMode -Value "Chrome" -Scope Global -option ReadOnly -Force
                } elseif ((Get-WarrantyRegistry -ServerBrowserSupport) -eq 'Edge'){
                    Set-Variable DriverMode -Value "Edge" -Scope Global -option ReadOnly -Force
                }
            }
        } else {
            $browsersupport = Test-BrowserSupport -Browser $Seleniumdrivermode
            if ($browsersupport -eq $false) {
                Set-Variable Browsersupport -Value $false -Scope Global -option ReadOnly -Force
            } 
        }
    }
    if ($PSCmdlet.ParameterSetName -eq 'Default') {
        if ($serial -eq 'Automatic') {
            $machineinfo = Get-MachineInfo
            $serialnumber = $machineinfo.serialnumber
        }
        else {
            $serialnumber = $serial
        }
        if ($Manufacturer -eq 'Automatic') {
            $machineinfo = Get-MachineInfo
            $mfg = $machineinfo.Manufacturer
        }
        else {
            $mfg = $Manufacturer
        }
    } else {
        $serialnumber = $serial
        $mfg = $Manufacturer
        $global:ServerMode = $true
    }
    Function Get-WarrantySwitch {
        $Notsupported = $false
        switch -Wildcard ($mfg) {
            "TERRA" {
                $Warobj = Get-WarrantyTerra -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
            }
            "EDSYS" {
                $Warobj = Get-WarrantyEdsys -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
            }
            "ASUS" {
                $Warobj = Get-WarrantyAsus -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
            }
            "LENOVO" {
                $Warobj = Get-WarrantyLenovo -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
            }
            "DELL" {
                $Warobj = Get-WarrantyDell -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
            }
            "HP" {
                if ($HpSystemSKU) {
                    $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat -SystemSKU $HpSystemSKU -NinjaOrg $DeviceOrg
                }
                else {
                    $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
                }
            }
            "MICROSOFT" {
                if ($($machineinfo.Model) -like 'SurfaceNotSupportedYet') {
                    $Warobj = Get-WarrantyMicrosoft -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
                }
                else {
                    if($RMM -eq 'NinjaRMMAPI'){
                        $Notsupported = $true
                        $WarObj = [PSCustomObject]@{
                            'Serial'                = $Serial
                            'Warranty Product name' = $null
                            'StartDate'             = $null
                            'EndDate'               = $null
                            'Warranty Status'       = "Manufacturer not supported"
                            'Manufacturer'          = $mfg
                            'Client'                = $NinjaOrg
                            'Product Image'         = $null
                            'Warranty URL'          = $null
                        }
                    } else {
                        $Notsupported = $true
                        Write-Host "Microsoft Model not Supported"
                        Write-Host "Manufacturer  :  $mfg"
                        Write-Host "Model         :  $($machineinfo.Model)"
                    }
                }        
            }
            "TOSHIBA" {
                $Warobj = Get-WarrantyToshiba -Serial $serialnumber -DateFormat $DateFormat -NinjaOrg $DeviceOrg
            }
            default {
                if($RMM -eq 'NinjaRMMAPI'){
                    $Notsupported = $true
                    $WarObj = [PSCustomObject]@{
                        'Serial'                = $Serial
                        'Warranty Product name' = $null
                        'StartDate'             = $null
                        'EndDate'               = $null
                        'Warranty Status'       = "Manufacturer not supported"
                        'Manufacturer'          = $mfg
                        'Client'                = $NinjaOrg
                        'Product Image'         = $null
                        'Warranty URL'          = $null
                    }
                } else {
                    $Notsupported = $true
                    Write-Host "Manufacturer or Model not Supported"
                    Write-Host "Manufacturer  :  $mfg"
                    Write-Host "Model         :  $($machineinfo.Model)"
                }
            }
        }
    }
    # NinjaOne API Connection
    if($RMM -eq 'NinjaRMMAPI'){
        Get-NinjaOneModule
        $ConnectNinjaOneParams = @{
            UseClientAuth = $True
            Instance = $NinjaInstance
            ClientID = $NinjaAccesskey
            ClientSecret = $NinjaSecretkey
            Scopes = @('monitoring', 'management')
            RedirectURL = 'http://localhost:8080'
            Port = 8080
            #ShowTokens = $True
        }
        try{
            Connect-NinjaOne @ConnectNinjaOneParams
        } catch{
            Write-Output "Error Connecting to NinjaOne API"
            Write-Output "$_"
            exit 1
        }
        if($ninjaorgid){
            $ninjaorgs      = Get-NinjaOneOrganisations -organisationId $ninjaorgid
            $ninjdevices    = Get-NinjaOneDevices -organisationId $ninjaorgid | where-object {$_.nodeClass -eq 'WINDOWS_WORKSTATION'}
        }else {
            $ninjaorgs      = Get-NinjaOneOrganisations
            $ninjdevices    = Get-NinjaOneDevices -deviceFilter | where-object {$_.nodeClass -eq 'WINDOWS_WORKSTATION'}
        }
        $i = 0
        $warrantyObject = foreach ($ninjdevice in $ninjdevices) {
            $Warobj = ""
            $i++
            $progressPercentage = [math]::Round(($i / $ninjdevices.Count * 100), 2)
            $ninjdevice = Get-NinjaOneDevices -deviceid $($ninjdevice.id)
            Write-Progress -Activity "Grabbing Warranty information" -status "Processing $($ninjdevice.system.biosSerialNumber). Device $i of $($ninjdevices.Count)" -percentComplete $progressPercentage
            $DeviceOrg = ($NinjaOrgs | Where-Object { $_.id -eq $ninjdevice.organizationId }).name
            try {
                $Mfg = $($ninjdevice.system.manufacturer)
                $serialnumber = $($ninjdevice.system.SerialNumber)
                $Mfg = Get-MachineInfo -Manufacturer $Mfg -Serial $serialnumber -NinjaRMMAPI
                Get-WarrantySwitch
            } catch {
                Write-Error "Failed to fetch warranty data for device: $($ninjdevice.systemName) $_"
            }
                $DeviceObject = [PSCustomObject]@{
                id = $ninjdevice.id
                organizationId = $ninjdevice.organizationId
                organizationName = $DeviceOrg
                systemname = $ninjdevice.systemname
                biosSerialNumber = $ninjdevice.system.biosSerialNumber
                SerialNumber = $ninjdevice.system.SerialNumber
                manufacturer = $ninjdevice.system.manufacturer
                model = $ninjdevice.system.model
            }
            # Convert the current device object to JSON and append it to the file
            $Null = $DeviceObject | ConvertTo-Json -Depth 5 | Add-Content 'Devices.json'
            # Sleep for a short duration to simulate processing time (optional)
            Start-Sleep -Milliseconds 100
            if ($progressPercentage -eq 100) {
                Write-Progress -Activity "Grabbing Warranty information" -status "Processing Complete" -percentComplete 100
                Start-Sleep -Milliseconds 500
                Write-Progress -Activity "Grabbing Warranty information" -Completed
            }
    
            if ($Warobj.EndDate) {
                $Seconds = [int]([math]::Truncate((New-TimeSpan -Start $date1 -End $Warobj.EndDate).TotalSeconds))
                $UpdateBody = @{
                    "$ninjawarrantyexpiry" = $($Warobj.EndDate)
                } | convertto-json
                
                if ($SyncWithSource -eq $true) {
                    switch ($OverwriteWarranty) {
                        $true {
                            
                            try {
                                $Result = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($ninjdevice.id)/custom-fields" -Method PATCH -Headers $AuthHeader -body $UpdateBody -contenttype 'application/json' -ea stop
                            } catch {
                                Write-Error "Failed to update device: $($ninjdevice.systemName) $_"
                            }
                        }
                        $false {
                            $DeviceFields = Get-NinjaOneDeviceCustomFields -deviceId $($ninjdevice.id)
                            $WarrantyDate = $DeviceFields."$($ninjawarrantyexpiry)"
    
                            if ($null -eq $WarrantyDate -and $null -ne $Warobj.EndDate) { 
                                try {
                                    $Result = Set-NinjaOneDeviceCustomFields -deviceid $($ninjdevice.id) -customfields $UpdateBody
                                } catch {
                                    Write-Error "Failed to update device: $($ninjdevice.systemName) $_"
                                }        
                            } 
                        }
                    }
                }
            }
            $Warobj
        }
        Remove-item 'devices.json' -Force -ErrorAction SilentlyContinue
        return $warrantyObject
    }

    Get-WarrantySwitch

    if ($RMM -eq 'NinjaRMM' -and ($Notsupported -eq $false) -and !$ServerMode.IsPresent) {
        $ParamsNinjaRMM = @{
            DateFormat = $DateFormat
        }
        if ($WarObj.'StartDate') {
            $ParamsNinjaRMM['Warrantystart'] = $WarObj.'StartDate'
        }
        if ($WarObj.'EndDate') {
            $ParamsNinjaRMM['WarrantyExpiry'] = $WarObj.'EndDate'
        }
        if ($WarObj.'Warranty Status') {
            $ParamsNinjaRMM['WarrantyStatus'] = $WarObj.'Warranty Status'
        }
        if ($WarObj.'Invoice') {
            $ParamsNinjaRMM['Invoicenumber'] = $WarObj.'Invoice'
        }
        Write-WarrantyNinjaRMM @ParamsNinjaRMM
    }
    if ($EnableRegistry -and ($Notsupported -eq $false) -and !$ServerMode.IsPresent -and $RMM -ne 'NinjaRMMAPI') {
        $Params = @{}
        if ($WarObj.'StartDate') {
            $Params['Warrantystart'] = $WarObj.'StartDate'
        }
        if ($WarObj.'EndDate') {
            $Params['WarrantyExpiry'] = $WarObj.'EndDate'
        }
        if ($WarObj.'Warranty Status') {
            $Params['WarrantyStatus'] = $WarObj.'Warranty Status'
        }
        if ($WarObj.'Invoice') {
            $Params['Invoicenumber'] = $WarObj.'Invoice'
        }
        Write-WarrantyRegistry @Params
    }
    if($null -eq $($Warobj.'EndDate') -and $ServerMode.IsPresent) {
        return $null
    }
    elseif($null -eq $($Warobj.'EndDate')) {
    Write-Output "No Warranty End Date Found"
    $Warobj
    Start-Sleep -Seconds 5
    exit 1
} else {
    return $warobj
}
}