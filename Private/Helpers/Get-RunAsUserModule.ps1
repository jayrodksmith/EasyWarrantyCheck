function Get-RunAsUserModule {
    <#
        .SYNOPSIS
        Function to Get RunAsUser
    
        .DESCRIPTION
        This function will get RunAsUser and install if not installed

        .EXAMPLE
        Get-RunAsUser
    
    #>
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet
    $RunAsUser = Get-Module -Name RunAsUser -ListAvailable
    if (-not $RunAsUser) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap | Out-Null
        Install-Module RunAsUser -Force
    }
    Import-Module RunAsUser -Force
}