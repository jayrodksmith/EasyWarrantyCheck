function Get-WarrantyRegistry {
    <#
        .SYNOPSIS
        Function to get details from Registry
    
        .DESCRIPTION
        This function will get details from Registry
    
        .EXAMPLE
        Get-WarrantyRegistry
    
        .PARAMETER Display
        Output Warranty Result
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [Switch]$Display,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath= 'HKLM:\SOFTWARE\RMMCustomInfo'
        )
        $registryValue = Get-ItemProperty -Path $RegistryPath -Name 'WarrantyStatus' -ErrorAction SilentlyContinue
        return ($null -ne $registryValue -and $null -ne $registryValue.WarrantyStatus)
    }