function Write-WarrantyNinjaRMM {
    <#
        .SYNOPSIS
        Function to write details to NinjaRMM
    
        .DESCRIPTION
        This function will write details to NinjaRMM
    
        .EXAMPLE
        Write-WarrantyNinjaRMM -Warrantystart 'value' -WarrantyExpiry 'value' -WarrantyStatus 'value' -Invoicenumber 'value'
    
        .PARAMETER Serial
        Manually set serial
    
        .PARAMETER Manufacture
        Manually set Manufacture
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [String]$Warrantystart= '',
            [Parameter(Mandatory = $false)]
            [String]$WarrantyExpiry= '',
            [Parameter(Mandatory = $false)]
            [String]$WarrantyStatus = '',
            [Parameter(Mandatory = $false)]
            [String]$Invoicenumber= '',
            [Parameter(Mandatory = $false)]
            [String]$dateformat= 'dd-MM-yyyy'
        )
        if (-not (Get-Command -Name "Ninja-Property-Set" -ErrorAction SilentlyContinue)) {
            $errorMessage = "Error: NinjaRMM module not found, not writing to NinjaRMM."
            return $errorMessage
        }
        $WarrantyNinjaRMM = Get-WarrantyNinjaRMM
        if($WarrantyNinjaRMM -eq $true -and ($ForceUpdate -eq $false)){
            # Set Age of device if start date exists
            if($ninjadeviceage){
                $calculatedageofdevice = Get-AgeOfDevice
                if ($calculatedageofdevice -ne $false){
                    $Currentdeviceage = Ninja-Property-Get $ninjadeviceage
                    if($Currentdeviceage -ne $calculatedageofdevice){
                        Ninja-Property-Set $ninjadeviceage $calculatedageofdevice
                    }
                }
            }
            return "Warranty details already in NinjaRMM"
        } else {
                if($Warrantystart){
                    if ($Warrantystart -match "\d{2}-\d{2}-\d{4}"){
                        #$Warrantystart = $Warrantystart.ToString("dd-MM-yyyy")
                    } else {
                        $Warrantystart = [DateTime]::ParseExact($Warrantystart, $dateformat, $null)
                        $Warrantystart = $Warrantystart.ToString("dd-MM-yyyy")
                    }
                    $Warrantystartutc = Get-Date $Warrantystart -Format "yyyy-MM-dd"
                }
                if($WarrantyExpiry){
                    if ($WarrantyExpiry -match "\d{2}-\d{2}-\d{4}"){
                        #$WarrantyExpiry = $WarrantyExpiry.ToString("dd-MM-yyyy")
                    } else {
                        $WarrantyExpiry = [DateTime]::ParseExact($WarrantyExpiry, $dateformat, $null)
                        $WarrantyExpiry = $WarrantyExpiry.ToString("dd-MM-yyyy")
                    }
                    $WarrantyExpiryutc = Get-Date $WarrantyExpiry -Format "yyyy-MM-dd"
                }
            if($Warrantystartutc){Ninja-Property-Set $ninjawarrantystart $Warrantystartutc}
            if($WarrantyExpiryutc){Ninja-Property-Set $ninjawarrantyexpiry $WarrantyExpiryutc}
            if($WarrantyStatus){Ninja-Property-Set $ninjawarrantystatus $WarrantyStatus}
            if($Invoicenumber){Ninja-Property-Set $ninjainvoicenumber $Invoicenumber}

            # Set Age of device if start date exists
            if($ninjadeviceage){
                $calculatedageofdevice = Get-AgeOfDevice
                if ($calculatedageofdevice -ne $false){
                    $Currentdeviceage = Ninja-Property-Get $ninjadeviceage
                    if($Currentdeviceage -ne $calculatedageofdevice){
                        Ninja-Property-Set $ninjadeviceage $calculatedageofdevice
                    }
                }
            }
            return "Warranty details saved to NinjaRMM"
        }
}