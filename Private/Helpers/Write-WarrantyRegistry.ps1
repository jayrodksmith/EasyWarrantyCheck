function Write-WarrantyRegistry{
    <#
        .SYNOPSIS
        Function to write details to Registry
    
        .DESCRIPTION
        This function will write details to Registry
    
        .EXAMPLE
        Write-WarrantyRegistry -Warrantystart 'value' -WarrantyExpiry 'value' -WarrantyStatus 'value' -Invoicenumber 'value'
    
        .PARAMETER Serial
        Manually set serial
    
        .PARAMETER Manufacture
        Manually set Manufacture
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [String]$Warrantystart,
            [Parameter(Mandatory = $false)]
            [String]$WarrantyExpiry,
            [Parameter(Mandatory = $false)]
            [String]$WarrantyStatus,
            [Parameter(Mandatory = $false)]
            [String]$Invoicenumber,
            [Parameter(Mandatory = $false)]
            [Switch]$ServerLastCheck,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath= 'HKLM:\SOFTWARE\RMM\EasyWarrantyCheck'
        )
        # Cleanup Old Registry 
        $RegistryPathOld= 'HKLM:\SOFTWARE\RMMCustomInfo'
        if (Test-Path $RegistryPathOld){
            Remove-Item $RegistryPathOld -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Verbose "Removing old registry key"
        }
        # Create Registry if not exist
        if (-not (Test-Path $RegistryPath)){
            New-Item -Path $RegistryPath -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Verbose "Registry key created successfully."
        } else {
            Write-Verbose "Registry key already exists."
        }
        if($ServerLastCheck){
            $todaysdate = Get-Date -format $DateFormatGlobal
            New-ItemProperty -Path $RegistryPath -Name "ServerLastCheck" -PropertyType String -Value $todaysdate -Force -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty -Path $RegistryPath -Name "ServerBrowserSupport" -PropertyType String -Value $DriverMode -Force -ErrorAction SilentlyContinue | Out-Null
            return "Server Checked"
        }
        $registryvalue = Get-WarrantyRegistry $RegistryPath
        if($registryvalue -eq $true -and ($ForceUpdate -eq $false)){
            return "Warranty details already in Registry"
        } else {
                if($Warrantystart){
                    New-ItemProperty -Path $RegistryPath -Name "WarrantyStart" -PropertyType String -Value $Warrantystart -Force -ErrorAction SilentlyContinue | Out-Null
                }
                if($WarrantyExpiry){
                    New-ItemProperty -Path $RegistryPath -Name "WarrantyExpiry" -PropertyType String -Value $WarrantyExpiry -Force -ErrorAction SilentlyContinue | Out-Null
                }
                if($WarrantyStatus){
                    New-ItemProperty -Path $RegistryPath -Name "WarrantyStatus" -PropertyType String -Value $WarrantyStatus -Force -ErrorAction SilentlyContinue | Out-Null
                }
                if($Invoicenumber){
                    New-ItemProperty -Path $RegistryPath -Name "Invoicenumber" -PropertyType String -Value $Invoicenumber -Force -ErrorAction SilentlyContinue | Out-Null
                }
                return "Warranty details saved to Registry $RegistryPath"
                }
    }