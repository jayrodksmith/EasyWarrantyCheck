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
        # Import Ninja Powershell Module
        Write-Verbose "Importing Ninja Powershell module"
        Import-Module NJCliPSh -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
        # Test if fields exist, if not mark them false to prevent trying to store into Ninja
        $testninjawarrantystart = Ninja-Property-Get $ninjawarrantystart 2>&1
        if ($testninjawarrantystart -match "Unable to find the specified field" ){
            Write-Host "Unable to access $ninjawarrantystart field in ninja"
            Write-Host "Check permissions of field and that it exists"
            Set-Variable ninjawarrantystart -Value $false -Scope Global -option ReadOnly -Force
        }
        $testninjawarrantystatus = Ninja-Property-Get $ninjawarrantystatus 2>&1
        if ($testninjawarrantystatus -match "Unable to find the specified field" ){
            Write-Host "Unable to access $ninjawarrantystatus field in ninja"
            Write-Host "Check permissions of field and that it exists"
            Set-Variable ninjawarrantystatus -Value $false -Scope Global -option ReadOnly -Force
        }
        $testninjawarrantyexpiry = Ninja-Property-Get $ninjawarrantyexpiry 2>&1
        if ($testninjawarrantyexpiry -match "Unable to find the specified field" ){
            Write-Host "Unable to access $ninjawarrantyexpiry field in ninja"
            Write-Host "Check permissions of field and that it exists"
            Set-Variable ninjawarrantyexpiry -Value $false -Scope Global -option ReadOnly -Force
        }
        $testninjainvoicenumber  = Ninja-Property-Get $ninjainvoicenumber 2>&1
        if ($testninjainvoicenumber  -match "Unable to find the specified field" ){
            Write-Host "Unable to access $ninjainvoicenumber field in ninja"
            Write-Host "Check permissions of field and that it exists"
            Set-Variable ninjainvoicenumber -Value $false -Scope Global -option ReadOnly -Force
        }
        $testninjadeviceage  = Ninja-Property-Get $ninjadeviceage 2>&1
        if ($testninjadeviceage  -match "Unable to find the specified field" ){
            Write-Host "Unable to access $ninjadeviceage field in ninja"
            Write-Host "Check permissions of field and that it exists"
            Set-Variable ninjadeviceage -Value $false -Scope Global -option ReadOnly -Force
        }
        $ninjawarrantystatusvalue = Ninja-Property-Get $ninjawarrantystatus
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