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

    .PARAMETER Manufacturer
    Manually set Manufacturer

#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
		[Parameter(Mandatory = $false)]
		[String]$Serial= 'Automatic',
        [Parameter(Mandatory = $false)]
		[String]$Manufacturer= 'Automatic',
        [Switch]$NinjaRMMAPI
	)

    if($NinjaRMMAPI){
        $Mfg = if ($Mfg) {
            switch ($Mfg) {
                "IBM" { $Mfg = "LENOVO" }
                "Hewlett-Packard" { $Mfg = "HP" }
                {$_ -match "Asus"} { $Mfg = "ASUS" }
                {$_ -match "Wortmann"} { $Mfg = "TERRA" }
                {$_ -match "Terra"} { $Mfg = "TERRA" }
                {$_ -match "Dell"} { $Mfg = "DELL" }
                {$_ -match "HP"} { $Mfg = "HP" }
                {$_ -match "Edsys"} { $Mfg = "EDSYS" }
                {$_ -match "Lenovo"} { $Mfg = "LENOVO" }
                {$_ -match "Microsoft"} { $Mfg = "MICROSOFT" }
                {$_ -match "TOSHIBA"} { $Mfg = "TOSHIBA" }
                {$_ -match "Intel Corporation"} { 
                    $pattern = "^B\d{6}$"
                    if ($SerialNumber -match $pattern){
                        $Mfg = "EDSYS"
                    }
                }
                default { $Mfg = $Mfg }
            }
            $Mfg
        } else {
            $Mfg 
        }
        return $Mfg
    }

    $SerialNumber = if ($Serial -eq 'Automatic') {
        (Get-CimInstance win32_bios -verbose:$false).SerialNumber
    } else {
        $Serial
    }
    
    $Mfg = if ($Manufacturer -eq 'Automatic') {
        $mfg = (Get-CimInstance -ClassName Win32_ComputerSystem -verbose:$false).Manufacturer
        $model = (Get-CimInstance -ClassName Win32_ComputerSystem -verbose:$false).Model
        switch ($Mfg) {
            "IBM" { $Mfg = "LENOVO" }
            "Hewlett-Packard" { $Mfg = "HP" }
            {$_ -match "Asus"} { $Mfg = "ASUS" }
            {$_ -match "Wortmann"} { $Mfg = "TERRA" }
            {$_ -match "Terra"} { $Mfg = "TERRA" }
            {$_ -match "Dell"} { $Mfg = "DELL" }
            {$_ -match "HP"} { $Mfg = "HP" }
            {$_ -match "Edsys"} { $Mfg = "EDSYS" }
            {$_ -match "Lenovo"} { $Mfg = "LENOVO" }
            {$_ -match "Microsoft"} { $Mfg = "MICROSOFT" }
            {$_ -match "TOSHIBA"} { $Mfg = "TOSHIBA" }
            {$_ -match "Intel Corporation"} { 
                $pattern = "^B\d{6}$"
                if ($SerialNumber -match $pattern){
                    $Mfg = "EDSYS"
                }
            }
            default { $Mfg = $Mfg }
        }
        $Mfg
    } else {
        $Manufacturer
    }
    $MachineInfo = [PSCustomObject]@{
        SerialNumber = $SerialNumber
        Manufacturer = $Mfg
        Model = $model
    }
    return $MachineInfo
}