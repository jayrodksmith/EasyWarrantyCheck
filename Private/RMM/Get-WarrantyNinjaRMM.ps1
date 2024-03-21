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
        # Test if fields exist
        $testninjawarrantystart = Ninja-Property-Get $ninjawarrantystart 2>&1
        if ($testninjawarrantystart -match "Unable to find the specified field" ){
            Write-Host "Unable to access warrantystart field in ninja"
            Write-Host "Check permissions of field and that it exists"
        }
        $testninjawarrantystatus = Ninja-Property-Get $ninjawarrantystatus 2>&1
        if ($testninjawarrantystatus -match "Unable to find the specified field" ){
            Write-Host "Unable to access warrantystatus field in ninja"
            Write-Host "Check permissions of field and that it exists"
        }
        $testninjawarrantyexpiry = Ninja-Property-Get $ninjawarrantyexpiry 2>&1
        if ($testninjawarrantyexpiry -match "Unable to find the specified field" ){
            Write-Host "Unable to access warrantyexpiry field in ninja"
            Write-Host "Check permissions of field and that it exists"
        }
        $testninjainvoicenumber  = Ninja-Property-Get $ninjainvoicenumber 2>&1
        if ($testninjainvoicenumber  -match "Unable to find the specified field" ){
            Write-Host "Unable to access invoicenumber field in ninja"
            Write-Host "Check permissions of field and that it exists"
        }
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