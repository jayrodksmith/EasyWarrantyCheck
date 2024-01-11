function Get-WarrantyNinjaRMM {
    <#
        .SYNOPSIS
        Function to get details to NinjaRMM
    
        .DESCRIPTION
        This function will get details to NinjaRMM
    
        .EXAMPLE
        Get-WarrantyNinjaRMM
    
        .PARAMETER Display
        Output Warranty Result
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [Switch]$Display
        )
        
        $ninjawarrantystartvalue = Ninja-Property-Get $ninjawarrantystart
        $ninjawarrantystatusvalue = Ninja-Property-Get $ninjawarrantystatus
        $ninjawarrantyexpiryvalue = Ninja-Property-Get $ninjawarrantyexpiry
        $ninjainvoicenumbervalue = Ninja-Property-Get $ninjainvoicenumber
        if ($null -ne $ninjawarrantystatusvalue){
            if ($Display){
                return $ninjawarrantystatusvalue
            } else {
                return $true
            } 
        } else {
            return $false
        }
    }