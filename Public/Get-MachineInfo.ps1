function Get-MachineInfo {
<#
    .SYNOPSIS
    Function to get information of machine

    .DESCRIPTION
    This function will get serial number and mfg of system

    .EXAMPLE
    Get-MachineInfo
    Get-MachineInfo -Serial "12345678" -Manufacturer "HP" // (Forces Serial and Make)

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
        [ValidateSet('Automatic', 'Dell', 'HP', 'Edsys', 'Asus', 'Lenovo')]
		[String]$Manufacture= 'Automatic'
	)
    $SerialNumber = if ($Serial -eq 'Automatic') {
        (Get-CimInstance win32_bios).SerialNumber
    } else {
        $Serial
    }

    $Mfg = if ($Manufacture -eq 'Automatic') {
        $mfg = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        $model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        switch ($Mfg) {
            "IBM" { $Mfg = "LENOVO" }
            "Hewlett-Packard" { $Mfg = "HP" }
            {$_ -match "Asus"} { $Mfg = "ASUS" }
            {$_ -match "Dell"} { $Mfg = "DELL" }
            {$_ -match "HP"} { $Mfg = "HP" }
            {$_ -match "Edsys"} { $Mfg = "EDSYS" }
            {$_ -match "Lenovo"} { $Mfg = "LENOVO" }
            {$_ -match "Microsoft"} { $Mfg = "MICROSOFT" }
            default { $Mfg = $Mfg }
        }
        $Mfg
    } else {
        $Manufacture
    }
    $MachineInfo = [PSCustomObject]@{
        SerialNumber = $SerialNumber
        Manufacturer = $Mfg
        Model = $model
    }
    return $MachineInfo
}