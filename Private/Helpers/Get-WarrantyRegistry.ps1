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
            [Switch]$ServerLastCheck,
            [Parameter(Mandatory = $false)]
            [Switch]$ServerBrowserSupport,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath= 'HKLM:\SOFTWARE\RMM\EasyWarrantyCheck'
        )
        if($ServerBrowserSupport){
            $registryValue = Get-ItemProperty -Path $RegistryPath -Name 'ServerBrowserSupport' -ErrorAction SilentlyContinue
            return $registryValue.ServerBrowserSupport
        }
        if($ServerLastCheck){
            $registryValue = Get-ItemProperty -Path $RegistryPath -Name 'ServerLastCheck' -ErrorAction SilentlyContinue
            return $registryValue.ServerLastCheck
        } else {
            $registryValue = Get-ItemProperty -Path $RegistryPath -Name 'WarrantyStatus' -ErrorAction SilentlyContinue
            return ($null -ne $registryValue -and $null -ne $registryValue.WarrantyStatus)
        }
    }