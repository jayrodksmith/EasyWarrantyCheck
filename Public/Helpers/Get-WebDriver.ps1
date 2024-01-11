function Get-WebDriver {
    <#
        .SYNOPSIS
        Function to Get Chrome Web Driver
    
        .DESCRIPTION
        This function will get Chrome Web Driver
    
        .EXAMPLE
        Get-WebDriver
    
    #>
    $webdriverurl = "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/120.0.6099.109/win64/chromedriver-win64.zip"
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