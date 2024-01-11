function Get-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Get SelniumModule
    
        .DESCRIPTION
        This function will get SelniumModule and install if not installed

        .EXAMPLE
        Get-SelniumModule
    
    #>
    Set-ExecutionPolicy Bypass -scope Process -Force
    Import-Module PowerShellGet
    $seleniumModule = Get-Module -Name Selenium -ListAvailable
    if (-not $seleniumModule) {
        Install-Module Selenium -Force
    }
    Import-Module Selenium -Force
}