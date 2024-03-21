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
        Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {
        
    }
    Import-Module PowerShellGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
    $RunAsUser = Get-Module -Name RunAsUser -ListAvailable | Where-Object { $_.Version -eq '2.4.0' }
    if (-not $RunAsUser) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
        Install-Module RunAsUser -Force -RequiredVersion '2.4.0' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
    }
    Import-Module RunAsUser -Force -Version '2.4.0' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -verbose:$false | Out-Null
}
