function Get-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Get SelniumModule
    
        .DESCRIPTION
        This function will get SelniumModule and install if not installed

        .EXAMPLE
        Get-SelniumModule
    
    #>
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet
    $seleniumModule = Get-Module -Name Selenium -ListAvailable
    if (-not $seleniumModule) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap | Out-Null
        Install-Module Selenium -Force
    }
    Import-Module Selenium -Force
}