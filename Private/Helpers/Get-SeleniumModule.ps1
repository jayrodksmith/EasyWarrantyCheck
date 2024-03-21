function Get-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Get SeleniumModule
    
        .DESCRIPTION
        This function will get SeleniumModule and install if not installed

        .EXAMPLE
        Get-SelniumModule
    
    #>
    # Temporarily set verbose preference to 'SilentlyContinue'
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
    $seleniumModule = Get-Module -Name Selenium -ListAvailable | Where-Object { $_.Version -eq '3.0.1' }
    if (-not $seleniumModule) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
        Install-Module Selenium -Force -RequiredVersion '3.0.1' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
    }
    Import-Module Selenium -Force -Version '3.0.1' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
}