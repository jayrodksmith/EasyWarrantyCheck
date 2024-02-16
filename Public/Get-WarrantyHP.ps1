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
    Get-WebDriver
    Get-SeleniumModule
    $WebDriverPath = "C:\temp\chromedriver-win64"
    # Set Chrome options to run in headless mode
    $ChromeService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($WebDriverPath, 'chromedriver.exe')
    $ChromeService.HideCommandPromptWindow = $true
    $chromeOptions = [OpenQA.Selenium.Chrome.ChromeOptions]::new()
    $chromeOptions.AddArgument("headless")
    $chromeOptions.AddArgument("--log-level=3")
    # Start a new browser session with headless mode
    try {
        $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeService, $chromeOptions)
    }
    catch {
        if ($PSCmdlet.ParameterSetName -eq 'Default') {
            Write-Host "###########################"
            Write-Host "WARNING"
            Write-Host "Google Chrome not detected"
            Write-Host "This manufacturer currently requires Google Chrome installed to check expiry"
            Write-Host "###########################"
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
                Remove-Module Selenium
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
                Remove-Module Selenium
                return $warObj
            }
        } else {
            Write-Error "Google Chrome not detected"
        }
    }
    # Navigate to the warranty check URL
    Write-Host "Checking HP website for serial : $Serial"
    $driver.Navigate().GoToUrl("https://support.hp.com/au-en/check-warranty")
    # Locate and input the serial number into the form
    $serialnumber = $Serial
    $inputField = $driver.FindElementById("inputtextpfinder")
    $inputField.SendKeys($serialnumber)
    # Find and click the submit button
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
        Write-Debug "No Product Model required"
    }
    if ($null -ne $errorMsgElement) {
        # Error message found
        Write-Host "Searching for additional SystemSKU......."
        Write-Debug "Need Product ID"
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
    } elseif ($null -ne $errorMsgElement -and $null -ne $SystemSKU) {
        # Error message found
        Write-Host "Using SystemSKU input"
        Write-Debug "Need Product ID"
        $productField = $driver.FindElementById("product-number inputtextPN")
        $productField.SendKeys($SystemSKU)
        $submitButton = $driver.FindElementById("FindMyProductNumber")
        $submitButton.Click()
        Write-Host "Waiting for results......."
        Start-Sleep -Seconds 15
    } elseif ($null -ne $errorMsgElement -and $null -eq $SystemSKU) {
        Write-Host "SystemSKU not provided"
    } 
    else {
        # Continue   
    }
    # Find the element containing the 'Start date' text
    try {
        $startDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c70-0 ng-star-inserted']//div[@class='label ng-tns-c70-0' and contains(text(), 'Start date')]/following-sibling::div[@class='text ng-tns-c70-0']")
    }
    catch {
        $startDateElement = $null
    }
    if (-not $startDateElement) {
        try {
            $startDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c72-0 ng-star-inserted']//div[@class='label ng-tns-c72-0' and contains(text(), 'Start date')]/following-sibling::div[@class='text ng-tns-c72-0']")
        }
        catch {
            Write-Host "Could not find warranty Start date"
        }
    }
    if ($startDateElement) {
        # Get the text of the 'Start date' element
        $startDateText = $startDateElement.Text
        $startDateText = Get-Date $startDateText -Format $dateformat
    }     
    try {
        # Find the element containing the 'End date' text
        $endDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c70-0 ng-star-inserted']//div[@class='label ng-tns-c70-0' and contains(text(), 'End date')]/following-sibling::div[@class='text ng-tns-c70-0']")
    }
    catch {
        $endDateElement = $null
    }
    if (-not $endDateElement) {
        try {
            $endDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c72-0 ng-star-inserted']//div[@class='label ng-tns-c72-0' and contains(text(), 'End date')]/following-sibling::div[@class='text ng-tns-c72-0']")
        }
        catch {
            Write-Host "Could not find warranty End date"
        }
    }
    if ($endDateElement) {
        # Get the text of the 'End date' element
        $endDateText = $endDateElement.Text
        $endDateText = Get-Date $endDateText -Format $dateformat
    }     
    try {
        # Find the element containing the 'Warranty Status' or 'Time Remaining' text
        $warrantyStatusElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c70-0 ng-star-inserted']//div[@class='label ng-tns-c70-0' and contains(text(), 'Time Remaining')]/following-sibling::div[@class='text ng-tns-c70-0']")       
    }
    catch {
        $warrantyStatusElement = $null
    }
    if (-not $warrantyStatusElement) {
        try {
            $warrantyStatusElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c72-0 ng-star-inserted']//div[@class='label ng-tns-c72-0' and contains(text(), 'Time Remaining')]/following-sibling::div[@class='text ng-tns-c72-0']")       
        }
        catch {
            Write-Host "Could not find warranty Status"
        } 
    }
    if ($warrantyStatusElement) {
        $warrantyStatusText = $warrantyStatusElement.Text
        if ($warrantyStatusText -match "Expired") {
            $warrantyStatusText = "Expired"
        }
    }     
    try {
        # Find the element containing the 'Product' information
        $h2Element = $driver.FindElementByCssSelector(".product-info-text.ng-tns-c70-0 > h2")
    }
    catch {
        $h2Element = $null
    }
    if (-not $h2Element) {
        try {
            # Find the element containing the 'Product' information
            $h2Element = $driver.FindElementByCssSelector(".product-info-text.ng-tns-c72-0 > h2")
        }
        catch {
            $h2Element = $null
        }
    }
    if ($h2Element) {
        $product = $h2Element.Text
    }
    # Close the browser
    $driver.Quit()
    Remove-Module Selenium

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