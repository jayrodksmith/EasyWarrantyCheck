function Get-WebDriver {
    <#
        .SYNOPSIS
        Function to Get Chrome Web Driver
    
        .DESCRIPTION
        This function will get Chrome Web Driver
    
        .EXAMPLE
        Get-WebDriver
    
    #>
    # Retrieve JSON content from the URL
    $jsonUrl = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
    $jsonString = Invoke-RestMethod -Uri $jsonUrl
    # Find the URL for chromedriver for win64 platform in the stable channel
    $webdriverurl = $jsonString.channels.Stable.downloads.chromedriver | Where-Object { $_.platform -eq "win64" } | Select-Object -ExpandProperty url
    $WebDrivertemp = "C:\temp"
    $WebDriverPath = "C:\temp\chromedriver-win64"
    $driverExists = Test-Path (Join-Path $WebDriverPath "chromedriver.exe")
    if (-not $driverExists) {
        try {
            mkdir C:\Temp -Force | Out-Null
            $tempFile = [System.IO.Path]::GetTempFileName() + ".zip"
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($webdriverurl, $tempFile)

            # Extract the zip file
            Expand-Archive -Path $tempFile -DestinationPath $WebDrivertemp -Force

            # Clean up: Remove temporary file
            # Remove-Item $tempFile
        } catch {
            Write-Host "An error occurred: $_.Exception.Message"
        }
    } else {
    }
    }