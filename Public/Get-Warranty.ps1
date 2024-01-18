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
        [CmdletBinding(SupportsShouldProcess)]
        param(
            # RMM Mode
            [Parameter(Mandatory = $false)]
            [ValidateSet('NinjaRMM', 'None')]
            [String]$RMM = 'NinjaRMM',
            #Enable Registry Storing
            [Parameter(Mandatory = $false)]
            [bool]$EnableRegistry = $true,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath = 'HKLM:\SOFTWARE\RMMCustomInfo\',
            # Force Update RMM with details
            [Parameter(Mandatory = $false)]
            [bool]$ForceUpdate = $false,
            # Custom Machine Details
            [Parameter(Mandatory = $false)]
            [String]$Serial = 'Automatic',
            [Parameter(Mandatory = $false)]
            [String]$Manufacturer = 'Automatic',
            # Set Date formats
            [Parameter(Mandatory = $false)]
            [String]$DateFormat = 'dd-MM-yyyy',
            #NinjaRMM Custom Field Names
            [Parameter(Mandatory = $false)]
            [String]$ninjawarrantystart = 'warrantyStart',
            [Parameter(Mandatory = $false)]
            [String]$ninjawarrantyexpiry= 'warrantyExpiry',
            [Parameter(Mandatory = $false)]
            [String]$ninjawarrantystatus = 'warrantystatus',
            [Parameter(Mandatory = $false)]
            [String]$ninjainvoicenumber = 'invoicenumber'

        )
        # Set Global Variables
        if($RMM -eq 'NinjaRMM'){
        Set-Variable ninjawarrantystart -Value $ninjawarrantystart -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantyexpiry -Value $ninjawarrantyexpiry -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantystatus -Value $ninjawarrantystatus -Scope Global -option ReadOnly -Force
        Set-Variable ninjainvoicenumber -Value $ninjainvoicenumber -Scope Global -option ReadOnly -Force
        }
        if($ForceUpdate -eq $true){
        Set-Variable ForceUpdate -Value $ForceUpdate -Scope Global -option ReadOnly -Force
        }
        $machineinfo = Get-MachineInfo
        if($serial -eq 'Automatic'){
            $serialnumber = $machineinfo.serialnumber
        } else {
            $serialnumber = $serial
        }
        if($Manufacturer -eq 'Automatic'){
            $mfg = $machineinfo.Manufacturer
        } else {
            $mfg = $Manufacturer
        }
        
        $Notsupported = $false
        switch -Wildcard ($mfg){
            "EDSYS"{
                $Warobj = Get-WarrantyEdsys -Serial $serialnumber -DateFormat $DateFormat
            }
            "ASUS"{
                $Warobj = Get-WarrantyAsus -Serial $serialnumber -DateFormat $DateFormat
            }
            "LENOVO"{
                $Warobj = Get-WarrantyLenovo -Serial $serialnumber -DateFormat $DateFormat
            }
            "DELL"{
                $Warobj = Get-WarrantyDell -Serial $serialnumber -DateFormat $DateFormat
            }
            "HP"{
                $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat
            }
            "MICROSOFT"{
                if($($machineinfo.Model) -like 'SurfaceNotSupportedYet'){
                    $Warobj = Get-WarrantyMicrosoft -Serial $serialnumber -DateFormat $DateFormat
                } else{
                    $Notsupported = $true
                    Write-Host "Microsoft Model not Supported"
                    Write-Host "Manufacturer  :  $mfg"
                    Write-Host "Model         :  $($machineinfo.Model)"
                }
                
            }
            "TOSHIBA"{
                $Warobj = Get-WarrantyToshiba -Serial $serialnumber -DateFormat $DateFormat
            }
            default{
                $Notsupported = $true
                Write-Host "Manufacturer or Model not Supported"
                Write-Host "Manufacturer  :  $mfg"
                Write-Host "Model         :  $($machineinfo.Model)"
            }
        }
    if($RMM -eq 'NinjaRMM' -and ($Notsupported -eq $false)){
        Write-WarrantyNinjaRMM -DateFormat $DateFormat -Warrantystart $($WarObj.'StartDate') -WarrantyExpiry $($WarObj.'EndDate') -WarrantyStatus $($WarObj.'Warranty Status') -Invoicenumber $($WarObj.'Invoice')
    }
    if($EnableRegistry -and ($Notsupported -eq $false)){
        Write-WarrantyRegistry -RegistryPath $RegistryPath -Warrantystart $($WarObj.'StartDate') -WarrantyExpiry $($WarObj.'EndDate') -WarrantyStatus $($WarObj.'Warranty Status') -Invoicenumber $($WarObj.'Invoice')
    }
return $Warobj
}