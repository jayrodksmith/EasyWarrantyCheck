function Get-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Get SeleniumModule
    
        .DESCRIPTION
        This function will get SeleniumModule and install if not installed

        .EXAMPLE
        Get-SelniumModule
    
    #>
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet -Verbose:$false
    $seleniumModule = Get-Module -Name Selenium -ListAvailable | Where-Object { $_.Version -eq '3.0.1' }
    if (-not $seleniumModule) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap -Verbose:$false | Out-Null
        Install-Module Selenium -Force -RequiredVersion '3.0.1' -Verbose:$false
    }
    Import-Module Selenium -Force -Version '3.0.1' -Verbose:$false
}