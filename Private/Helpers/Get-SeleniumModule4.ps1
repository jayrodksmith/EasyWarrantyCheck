function Get-SeleniumModule4 {
    <#
        .SYNOPSIS
        Function to Get SeleniumModule4
    
        .DESCRIPTION
        This function will get SeleniumModule4 and install if not installed

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
        Install-Module -Name Selenium -AllowPrerelease
    }
    Import-Module Selenium -Force
}