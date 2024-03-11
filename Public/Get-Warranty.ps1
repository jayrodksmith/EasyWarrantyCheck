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
        [ValidateSet('NinjaRMM', 'None')]
        [String]$RMM = 'NinjaRMM',
        
        # Web Driver mode, Edge or Chrome ( Edge Beta Support )
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
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
        [bool]$ForceUpdate = $false,
    
        # Custom Machine Details, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$Serial = 'Automatic',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$Manufacturer = 'Automatic',
    
        # Set Date formats, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$DateFormat = 'dd-MM-yyyy',
    
        # NinjaRMM Custom Field Names, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjawarrantystart = 'warrantyStart',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjawarrantyexpiry = 'warrantyExpiry',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjawarrantystatus = 'warrantystatus',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjainvoicenumber = 'invoicenumber',

        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$HpSystemSKU
            
    )
    # Set Global Variables
    if ($RMM -eq 'NinjaRMM') {
        Set-Variable ninjawarrantystart -Value $ninjawarrantystart -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantyexpiry -Value $ninjawarrantyexpiry -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantystatus -Value $ninjawarrantystatus -Scope Global -option ReadOnly -Force
        Set-Variable ninjainvoicenumber -Value $ninjainvoicenumber -Scope Global -option ReadOnly -Force
    }
    if ($ForceUpdate -eq $true) {
        Set-Variable ForceUpdate -Value $ForceUpdate -Scope Global -option ReadOnly -Force
    }
    if ($Seleniumdrivermode) {
        Set-Variable Seleniumdrivermode -Value $Seleniumdrivermode -Scope Global -option ReadOnly -Force
    }
    if ($PSCmdlet.ParameterSetName -eq 'Default') {
        $machineinfo = Get-MachineInfo
        if ($serial -eq 'Automatic') {
            $serialnumber = $machineinfo.serialnumber
        }
        else {
            $serialnumber = $serial
        }
        if ($Manufacturer -eq 'Automatic') {
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
        
    $Notsupported = $false
    switch -Wildcard ($mfg) {
        "EDSYS" {
            $Warobj = Get-WarrantyEdsys -Serial $serialnumber -DateFormat $DateFormat
        }
        "ASUS" {
            $Warobj = Get-WarrantyAsus -Serial $serialnumber -DateFormat $DateFormat
        }
        "LENOVO" {
            $Warobj = Get-WarrantyLenovo -Serial $serialnumber -DateFormat $DateFormat
        }
        "DELL" {
            $Warobj = Get-WarrantyDell -Serial $serialnumber -DateFormat $DateFormat
        }
        "HP" {
            if ($HpSystemSKU) {
                $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat -SystemSKU $HpSystemSKU
            }
            else {
                $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat
            }
        }
        "MICROSOFT" {
            if ($($machineinfo.Model) -like 'SurfaceNotSupportedYet') {
                $Warobj = Get-WarrantyMicrosoft -Serial $serialnumber -DateFormat $DateFormat
            }
            else {
                $Notsupported = $true
                Write-Host "Microsoft Model not Supported"
                Write-Host "Manufacturer  :  $mfg"
                Write-Host "Model         :  $($machineinfo.Model)"
            }
                
        }
        "TOSHIBA" {
            $Warobj = Get-WarrantyToshiba -Serial $serialnumber -DateFormat $DateFormat
        }
        default {
            $Notsupported = $true
            Write-Host "Manufacturer or Model not Supported"
            Write-Host "Manufacturer  :  $mfg"
            Write-Host "Model         :  $($machineinfo.Model)"
        }
    }
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
    if ($EnableRegistry -and ($Notsupported -eq $false) -and !$ServerMode.IsPresent) {
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
        Write-WarrantyRegistry -RegistryPath $RegistryPath @Params
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