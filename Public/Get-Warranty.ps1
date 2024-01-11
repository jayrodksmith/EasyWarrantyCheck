function Get-Warranty {
    <#
        .SYNOPSIS
        Function to Get warranty info
    
        .DESCRIPTION
        This function will get warranty info of the machine it is called from
    
        .EXAMPLE
        Get-Warranty
        Get-Warranty -Serial "12345678" -Manufacture "HP"
    
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
            # Force Update RMM with details
            [Parameter(Mandatory = $false)]
		    [bool]$RMMForceUpdate = $false,
            # Custom Machine Details
            [Parameter(Mandatory = $false)]
            [String]$Serial = 'Automatic',
            [Parameter(Mandatory = $false)]
            [String]$Manufacture = 'Automatic',
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
        if($RMMForceUpdate -eq $true){
        Set-Variable ForceUpdate -Value $RMMForceUpdate -Scope Global -option ReadOnly -Force
        }

        $machineinfo = Get-MachineInfo
        $mfg = $machineinfo.Manufacturer
        $serialnumber = $machineinfo.serialnumber
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
                Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat
            }
            default{
                $Notsupported = $true
                Write-Output "Manufacturer not Supported :  $mfg"
            }
        }
    if($RMM -eq 'NinjaRMM' -and ($Notsupported -eq $false)){
        Write-WarrantyNinjaRMM -DateFormat $DateFormat -Warrantystart $($WarObj.'StartDate') -WarrantyExpiry $($WarObj.'EndDate') -WarrantyStatus $($WarObj.'Warranty Status') -Invoicenumber $($WarObj.'Invoice')
    }
return $Warobj
}