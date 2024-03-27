function Get-NinjaOneModule {
    <#
        .SYNOPSIS
        Function to Get NinjaOne Module
    
        .DESCRIPTION
        This function will get NinjaOne Module and install if not installed

        .EXAMPLE
        Get-NinjaOneModule
    
    #>
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
    $ninjaonemodule = Get-Module -Name NinjaOne -ListAvailable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Where-Object { $_.Version -CGE '2.0.0' }
    if (-not $ninjaonemodule) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap | Out-Null
        Install-Module -Name NinjaOne -RequiredVersion 2.0.0-Beta7 -AllowPrerelease -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
    }
    Import-Module NinjaOne -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
}

Install-Module -Name NinjaOne -RequiredVersion 2.0.0-Beta7 -AllowPrerelease