function Stop-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Stop Selenium Module
    
        .DESCRIPTION
        This function will Stop Selenium Module
    
        .EXAMPLE
        Stop-SeleniumModule -Driver "Chrome"
        Stop-SeleniumModule -Driver "Edge"

    #>
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Chrome', 'Edge')]
        [String]$WebDriver = "Chrome",

        [Parameter(Mandatory = $false)]
        [bool]$Headless = $true,

        [Parameter(Mandatory = $false)]
        [String]$WebDriverPath = "C:\temp\EasyWarrantyCheck\WebDrivers"
    )
    if($WebDriver  -eq "Edge"){
        # Get the processes of Microsoft Edge
        $edgeProcesses = Get-CimInstance Win32_Process -Filter "name = 'msedge.exe'"

        # Filter processes with --headless
        $headlessEdgeProcesses = $edgeProcesses | Where-Object { $_.CommandLine -match '--headless' }

        # Terminate each edge process
        foreach ($process in $headlessEdgeProcesses) {
            $processID = $process.ProcessId
            if ($processID -ne $null) {
                Stop-Process -Id $processID -Force
                Write-Host "Terminated headless Microsoft Edge process with ID $processID"
            } else {
                Write-Host "Failed to retrieve process ID for a headless Microsoft Edge process."
            }
        }

        # Get the processes of msedgedriver
        $driverProcesses = Get-CimInstance Win32_Process -Filter "name = 'msedgedriver.exe'"

        # Terminate each driver process
        foreach ($process in $driverProcesses) {
            $processID = $process.ProcessId
            if ($processID -ne $null) {
                Stop-Process -Id $processID -Force
                Write-Host "Terminated msedgedriver process with ID $processID"
            } else {
                Write-Host "Failed to retrieve process ID for a msedgedriver process."
            }
        }
        Remove-Module Selenium
    } 
    if($WebDriver -eq "Chrome"){
        $driver.quit()
        Remove-Module Selenium
    }
}