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
            [String]$dateformat = $DateFormatGlobal
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
                    Write-Verbose "Warrantystart: $Warrantystart"
                    # Convert to UTC
                    $Warrantystartutc = Get-Date $Warrantystart -Format "yyyy-MM-dd"
                    Write-Verbose "Warrantystart UTC: $Warrantystartutc"
                }
                if($WarrantyExpiry){
                    Write-Verbose "WarrantyExpiry: $WarrantyExpiry"
                    # Convert to UTC
                    $WarrantyExpiryutc = Get-Date $WarrantyExpiry -Format "yyyy-MM-dd"
                    Write-Verbose "WarrantyExpiry UTC: $WarrantyExpiryutc"
                }
            Write-Verbose "Checking for warranty values to write to NinjaRMM" 
            $NinjaWarrantyObj = [PSCustomObject]@{
                'Ninja Warranty Start' = $ninjawarrantystart
                'Ninja Warranty Expiry' = $ninjawarrantyexpiry
                'Ninja Warranty Status' = $ninjawarrantystatus
                'Ninja Invoicenumber' = $ninjainvoicenumber
                'Ninja Device Age' = $ninjadeviceage
            }
            if ($VerbosePreference -eq 'Continue') {
                Write-Verbose "NinjaRMM Custom Field Values" 
                $NinjaWarrantyObj
            }
            
            if($Warrantystartutc){
                Write-Verbose "Will try write Warranty Start Value : $Warrantystartutc"
                Ninja-Property-Set $ninjawarrantystart $Warrantystartutc
            }
            if($WarrantyExpiryutc){
                Write-Verbose "Will try write Warranty Expiry Value : $WarrantyExpiryutc"
                Ninja-Property-Set $ninjawarrantyexpiry $WarrantyExpiryutc
            }
            if($WarrantyStatus){
                Write-Verbose "Will try write Warranty Status Value : $WarrantyStatus"
                Ninja-Property-Set $ninjawarrantystatus $WarrantyStatus
            }
            if($Invoicenumber){
                Write-Verbose "Will try write Warranty Invoice Value : $Invoicenumber"
                Ninja-Property-Set $ninjainvoicenumber $Invoicenumber
            }

            # Set Age of device if start date exists
            Write-Verbose "Checking for Device Age details to write to NinjaRMM" 
            if($ninjadeviceage){
                $calculatedageofdevice = Get-AgeOfDevice
                if ($calculatedageofdevice -ne $false){
                    $Currentdeviceage = Ninja-Property-Get $ninjadeviceage
                    if($Currentdeviceage -ne $calculatedageofdevice){
                        Write-Verbose "Will try write Device Age Value : $calculatedageofdevice" 
                        Ninja-Property-Set $ninjadeviceage $calculatedageofdevice
                    }
                }
            }
            return "Warranty details saved to NinjaRMM"
        }
}