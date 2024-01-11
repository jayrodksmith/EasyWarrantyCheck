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
        Manually set Manufacture
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [String]$Serial= 'Automatic',
            [Parameter(Mandatory = $false)]
            [String]$Manufacture= 'Automatic',
            [Parameter(Mandatory = $false)]
            [String]$DateFormat = 'dd-MM-yyyy'
        )
        $machineinfo = Get-MachineInfo
        $mfg = $machineinfo.Manufacturer
        $serialnumber = $machineinfo.Manufacturer
        switch -Wildcard ($mfg){
            "EDSYS"{
                $Warobj = Get-WarrantyEdsys -Serial $serialnumber -DateFormat $DateFormat
            }
            "ASUS"{

            }
            "LENOVO"{

            }
            "DELL"{

            }
            "HP"{

            }
            default{
                Write-Output "Manufacturer not Supported : $mfg"
            }
        }
return $Warobj
}