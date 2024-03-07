function Get-WebDriverEdge {
    <#
        .SYNOPSIS
        Function to Get Edge Web Driver
    
        .DESCRIPTION
        This function will get Edge Web Driver
    
        .EXAMPLE
        Get-WebDriverEdge
    
    #>
    # https://itconstructors.com/automate-update-of-selenium-web-driver-powershell/
    $webdriverurl = "https://msedgedriver.azureedge.net/122.0.2365.66/edgedriver_win64.zip"
    $WebDrivertemp = "C:\temp"
    $WebDriverPath = "C:\temp\edgedriver-win64"
    $driverExists = Test-Path (Join-Path $WebDriverPath "msedgedriver.exe")
    if (-not $driverExists) {
        try {
            mkdir C:\Temp -Force | Out-Null
            mkdir $WebDriverPath -Force | Out-Null
            $tempFile = [System.IO.Path]::GetTempFileName() + ".zip"
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($webdriverurl, $tempFile)

            # Extract the zip file
            Expand-Archive -Path $tempFile -DestinationPath $WebDriverPath -Force

            # Clean up: Remove temporary file
            # Remove-Item $tempFile
        } catch {
            Write-Host "An error occurred: $_.Exception.Message"
        }
    } else {
    }
    }