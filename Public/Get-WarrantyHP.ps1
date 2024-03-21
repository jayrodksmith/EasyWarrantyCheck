function Get-WarrantyHP {
    <#
        .SYNOPSIS
        Function to get HP Warranty
    
        .DESCRIPTION
        This function will get HP Warranty
    
        .EXAMPLE
        Get-WarrantyHP -Serial "SerialNumber"
    
        .PARAMETER Serial
        Set Serial

        .PARAMETER DateFormat
        Set DateFormat
    
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Serial,
        [Parameter(Mandatory = $false)]
        [String]$DateFormat = 'dd-MM-yyyy',
        [Parameter(Mandatory = $false)]
        [String]$SystemSKU
    )

        if ($browsersupport -eq $false){
            Write-Host "Estimating Details from Registry"
            try {
                $regPath = "HKLM:\SOFTWARE\WOW6432Node\HP\HPActiveSupport\HPSF\Warranty"
                $wsd = Get-ItemProperty -Path $regPath -Name "WSD" -ErrorAction Stop | Select-Object -ExpandProperty "WSD"
                # Convert string to date format
                $wsd = [DateTime]::ParseExact($wsd, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture)
                $wsd = Get-Date $wsd -Format $DateFormat
                Write-Host "Warranty Start: $wsd"
                $WarObj = [PSCustomObject]@{
                    'Serial'                = $Serial
                    'Warranty Product name' = $null
                    'StartDate'             = $wsd
                    'EndDate'               = $null
                    'Warranty Status'       = 'Could not get warranty information'
                    'Client'                = $null
                    'Product Image'         = $null
                    'Warranty URL'          = $null
                }
                Remove-Module Selenium -Verbose:$false
                return $warObj
            }
            catch {
                Write-Host "No details in registry"
                $WarObj = [PSCustomObject]@{
                    'Serial'                = $Serial
                    'Warranty Product name' = $null
                    'StartDate'             = $null
                    'EndDate'               = $null
                    'Warranty Status'       = 'Could not get warranty information'
                    'Client'                = $null
                    'Product Image'         = $null
                    'Warranty URL'          = $null
                }
                Remove-Module Selenium -Verbose:$false
                return $warObj
            }
        }
        # Start a new browser session with headless mode
        try{
            Get-WebDriver -WebDriver $DriverMode
            Get-SeleniumModule
            Write-Verbose "Starting SeleniumModule with drivemode = $DriverMode"
            $driver = Start-SeleniumModule -WebDriver $DriverMode -Headless $true
        }catch{
            Write-Verbose $_.Exception.Message
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = 'Could not get warranty information'
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
            }
            Remove-Module Selenium -Verbose:$false
            return $warObj
        }
        function Set-Iframe {
            # Try Click Iframe if exist
            try{
                $driver.FindElementById("kampyleForm32059")
                $iframe = $driver.FindElementById("kampyleForm32059")
                $driver.SwitchTo().Frame($iframe) | Out-Null
                $driver.FindElementByTagName("body").SendKeys([OpenQA.Selenium.Keys]::Escape)
                $driver.SwitchTo().DefaultContent() | Out-Null
            } catch {
        
            }
        }
        function Set-Privacy {
            # Try Click Iframe if exist
            try{
                $driver.FindElementById("onetrust-accept-btn-handler")
                $privacyButton.Click()
            } catch {
        
            }
        }
    # Navigate to the warranty check URL
    Write-Host "Checking HP website for serial : $Serial"
    $driver.Navigate().GoToUrl("https://support.hp.com/au-en/check-warranty")
    # Locate and input the serial number into the form
    Write-Verbose "Waiting for any popups"
    Start-Sleep -Seconds 15
    Write-Verbose "Tyring to get rid of popups"
    Set-Privacy
    Set-Iframe
    Write-Verbose "Inputting serial info"
    $serialnumber = $Serial
    $inputField = $driver.FindElementById("inputtextpfinder")
    $inputField.SendKeys($serialnumber)
    $submitButton = $driver.FindElementById("FindMyProduct")
    $submitButton.Click()
    # Wait for the page to load (you might need to adjust the sleep time)
    Write-Host "Waiting for results......."
    Start-Sleep -Seconds 15
    # Check if the error message exists
    try {
        $errorMsgElement = $driver.FindElementByClassName("errorTxt")
    }
    catch {
        Write-Verbose "No Product Model required"
    }

    if ($null -ne $errorMsgElement -and $null -ne $SystemSKU) {
        # Error message found
        Write-Host "Using SystemSKU input"
        Write-Verbose "Need Product ID"
        $productField = $driver.FindElementById("product-number inputtextPN")
        $productField.SendKeys($SystemSKU)
        $submitButton = $driver.FindElementById("FindMyProductNumber")
        $submitButton.Click()
        Write-Host "Waiting for results......."
        Start-Sleep -Seconds 15
    }
    elseif ($null -ne $errorMsgElement -and $null -ne $SystemSKU -and $global:ServerMode -eq $true) {
        Write-Host "SystemSKU not provided"
    }
    elseif ($null -ne $errorMsgElement -and $global:ServerMode -ne $true) {
        # Error message found
        Write-Host "Searching for additional SystemSKU......."
        Write-Verbose "Need Product ID"
        # Define the registry path
        $regPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
        # Get the value of "SystemSKU" if it exists
        try {
            $systemSKU = Get-ItemProperty -Path $regPath -Name "SystemSKU" -ErrorAction Stop | Select-Object -ExpandProperty "SystemSKU"
            Write-Host "SystemSKU value: $systemSKU"
            $productField = $driver.FindElementById("product-number inputtextPN")
            $productField.SendKeys($systemSKU)
            $submitButton = $driver.FindElementById("FindMyProductNumber")
            $submitButton.Click()
            Write-Host "Waiting for results......."
            Start-Sleep -Seconds 15
        }
        catch {
            Write-Host "SystemSKU key does not exist in the specified registry path."
            Exit 0
        }
    }

    else {
        # Continue   
    }
    # Find the element containing the 'Start date' text
    try {
        $startDateElement = $driver.FindElementByXPath("//div[contains(@class,'info-item')]//div[contains(@class,'label') and contains(text(), 'Start date')]/following-sibling::div[contains(@class,'text')]")
    }
    catch {
        $startDateElement = $null
        Write-Host "Could not find warranty Start date"
    }

    if ($startDateElement) {
        # Get the text of the 'Start date' element
        $startDateText = $startDateElement.Text
        $startDateText = Get-Date $startDateText -Format $dateformat
    }     
    try {
        # Find the element containing the 'End date' text
        $endDateElement = $driver.FindElementByXPath("//div[contains(@class,'info-item')]//div[contains(@class,'label') and contains(text(), 'End date')]/following-sibling::div[contains(@class,'text')]")

    }
    catch {
        $endDateElement = $null
        Write-Host "Could not find warranty End date"
    }

    if ($endDateElement) {
        # Get the text of the 'End date' element
        $endDateText = $endDateElement.Text
        $endDateText = Get-Date $endDateText -Format $dateformat
    }     
    try {
        # Find the element containing the 'Warranty Status' or 'Time Remaining' text
        $warrantyStatusElement = $driver.FindElementByXPath("//div[contains(@class,'info-item')]//div[contains(@class,'label') and contains(text(), 'Time Remaining')]/following-sibling::div[contains(@class,'text')]")
    }
    catch {
        $warrantyStatusElement = $null
        Write-Host "Could not find warranty Status"
    }

    if ($warrantyStatusElement) {
        $warrantyStatusText = $warrantyStatusElement.Text
        if ($warrantyStatusText -match "Expired") {
            $warrantyStatusText = "Expired"
        }
    }     
    try {
        # Find the element containing the 'Product' information
        $h2Element = $driver.FindElementByXPath("//main//h2")
    }
    catch {
        $h2Element = $null
        Write-Host "Could not find Product Name"
    }
    
    if ($h2Element) {
        $product = $h2Element.Text
    }
    # Close the browser
    Stop-SeleniumModule -WebDriver $DriverMode

    if ($endDateText) {
        $warfirst = $startDateText
        $warlatest = $endDateText
        $WarObj = [PSCustomObject]@{
            'Serial'                = $serialnumber
            'Warranty Product name' = $product
            'StartDate'             = $warfirst
            'EndDate'               = $warlatest
            'Warranty Status'       = $warrantyStatusText
            'Client'                = $null
            'Product Image'         = $null
            'Warranty URL'          = $null
        }
    }
    else {
        $WarObj = [PSCustomObject]@{
            'Serial'                = $serialnumber
            'Warranty Product name' = $null
            'StartDate'             = $null
            'EndDate'               = $null
            'Warranty Status'       = 'Could not get warranty information'
            'Client'                = $null
            'Product Image'         = $null
            'Warranty URL'          = $null
        }
    } 
    return $WarObj
}