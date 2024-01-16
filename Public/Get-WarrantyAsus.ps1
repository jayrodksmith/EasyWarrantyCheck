function Get-WarrantyAsus {
    <#
        .SYNOPSIS
        Function to get Asus Warranty
    
        .DESCRIPTION
        This function will get Asus Warranty
    
        .EXAMPLE
        Get-WarrantyAsus -Serial "SerialNumber"
    
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
            [String]$DateFormat = 'dd-MM-yyyy'
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
        try{
            $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeService, $chromeOptions)
        }catch{
            Write-Host "Chrome Not Installed or old version"
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
            Remove-Module Selenium
            return $warObj
        }
        # Navigate to the warranty check URL
        Write-Host "Checking Asus website for serial : $Serial"
        $driver.Navigate().GoToUrl("https://www.asus.com/support/warranty-status-inquiry")
        # Locate and input the serial number into the form
        $serialnumber = $Serial
        $inputField = $driver.FindElementById("warrantyNumber")
        $inputField.SendKeys($serialnumber)
        #Accept Checkbox
        $checkPrivacyButton = $driver.FindElementById("checkPrivacy")
        $checkPrivacyButton.Click()
        # Find and click the submit button
        $submitButton = $driver.FindElementByXPath("//button[@class='submit-button blue' and @aria-label='Submit']")
        $submitButton.Click()
        Write-Host "Waiting for results......."
        start-sleep -Seconds 10
        # Find the rows in the table
        $rows = $driver.FindElementsByXPath("//div[@role='rowgroup' and @class='result-item']//li[@role='cell']")
        # Define arrays to store column headers and data
        $columns = @("Product Series", "Model Name", "Product Serial Number", "Warranty Status", "Warranty Expiry" )
        $data = @()
        
        # Extract data rows
        foreach ($row in $rows) {
            $rowData = $row.FindElementByTagName("span").Text.Trim()
            $data += $rowData
        }
        # Create a PowerShell custom object representing the table
        $table = New-Object PSObject
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $table | Add-Member -MemberType NoteProperty -Name $columns[$i] -Value $data[$i]
        }
        
        # Check if the "Within Warranty" text exists
        if ($($table.'Warranty Status') -eq "Within Warranty" -or $($table.'Warranty Status') -eq 'Under Warranty(Active)') {
            # "Within Warranty" text found
            $warrantystatus = "Within Warranty"
            # Additional actions if needed
        } else {
            # Write-Host "Expired"
            $warrantystatus = "Expired"
        }
        
        # Close the browser
        $driver.Quit()
        Remove-Module Selenium
        $datestring = $($table.'Warranty Expiry')
        $warEndDate = [DateTime]::ParseExact($dateString, "yyyy/MM/dd", [System.Globalization.CultureInfo]::InvariantCulture)
        $warEndDate = $warEndDate.ToString($dateformat)
        
        if ($($table.'Warranty Status')) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $serialnumber
                'Warranty Product name' = $($table.'Model Name')
                'StartDate' = $null
                'EndDate' = $warEndDate
                'Warranty Status' = $warrantystatus
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
            }
        } else {
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
        } 
    return $WarObj
}