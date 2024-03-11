function Test-SoftwareInstalled {
    <#
        .SYNOPSIS
        Function to check software exists
    
        .DESCRIPTION
        This function will check if software exists
    
        .EXAMPLE
        Test-SoftwareInstalled -SoftwareName "Google Chrome"
        Test-SoftwareInstalled -SoftwareName "Microsoft Edge"
    
    #>
    param(
        [string]$SoftwareName
    )

# Define the registry paths where the software information is stored for 32-bit and 64-bit
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Check if the software registry key exists in either 32-bit or 64-bit location
foreach ($path in $registryPaths) {
    $installed = Get-ItemProperty -Path $path | Where-Object { $_.DisplayName -eq $SoftwareName }
    if ($installed) {
        $version = $installed.DisplayVersion
        Write-Verbose "$SoftwareName version $version is installed."
        $result = [PSCustomObject]@{
            Software = $SoftwareName 
            Installed = $true
            Version = $version
        }
        return $result
    }
}
# If the software was not found in any location
Write-Host "###########################"
Write-Host "WARNING"
Write-Host "$SoftwareName not detected"
Write-Host "This manufacturer currently requires $SoftwareName installed to check expiry"
Write-Host "###########################"
Write-Verbose "$SoftwareName is not installed."
$result = [PSCustomObject]@{
    Software = $SoftwareName 
    Installed = $false
    Version = $null
}
return $result
}
