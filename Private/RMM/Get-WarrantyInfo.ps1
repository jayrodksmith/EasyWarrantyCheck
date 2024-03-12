function  Get-Warrantyinfo {
    [CmdletBinding()]
    Param(
        [string]$serialnumber,
        [String]$client,
        [String]$DateFormat = 'dd-MM-yyyy',
        [String]$vendor
    )
    if ($LogActions) { add-content -path $LogFile -Value "Starting lookup for $($DeviceSerial),$($Client)" -force }
    if ($vendor) {
        switch -Wildcard ($vendor) {
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
    }
    else {
        switch ($DeviceSerial.Length) {
            7 { get-DellWarranty -SourceDevice $DeviceSerial -client $Client }
            8 { get-LenovoWarranty -SourceDevice $DeviceSerial -client $Client }
            9 { get-ToshibaWarranty -SourceDevice $DeviceSerial -client $line.client }
            10 { get-HPWarranty  -SourceDevice $DeviceSerial -client $Client }
            12 {
                if ($DeviceSerial -match "^\d+$") {
                    Get-MSWarranty  -SourceDevice $DeviceSerial -client $Client 
                }
                else {
                    Get-AppleWarranty -SourceDevice $DeviceSerial -client $Client
                } 
            }
            default {
                [PSCustomObject]@{
                    'Serial'                = $DeviceSerial
                    'Warranty Product name' = 'Could not get warranty information.'
                    'StartDate'             = $null
                    'EndDate'               = $null
                    'Warranty Status'       = 'Could not get warranty information'
                    'Client'                = $Client
                }
            }
        }
    }
    if ($LogActions) { add-content -path $LogFile -Value "Ended lookup for $($DeviceSerial),$($Client)" }
    return $Warobj
}