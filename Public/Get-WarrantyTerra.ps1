function Get-WarrantyTerra {
    <#
        .SYNOPSIS
        Function to get Terra Warranty
    
        .DESCRIPTION
        This function will get Terra Warranty
    
        .EXAMPLE
        Get-WarrantyTerra -Serial "SerialNumber"
    
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
        Get-WebDriver -WebDriver $Seleniumdrivermode
        Get-SeleniumModule
        if ($Seleniumdrivermode -eq "Chrome" ){
            $browserinstalled = Test-SoftwareInstalled -SoftwareName "Google Chrome"
        }
        if ($Seleniumdrivermode -eq "Edge" ){
            $browserinstalled = Test-SoftwareInstalled -SoftwareName "Microsoft Edge"
        }
        if ($browserinstalled.Installed -eq $false){
            Write-Host "###########################"
            Write-Host "WARNING"
            Write-Host "$($browserinstalled.software) not detected"
            Write-Host "This manufacturer currently requires $($browserinstalled.software) installed to check expiry"
            Write-Host "###########################"
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
        # Start a new browser session with headless mode
        try{
            $driver = Start-SeleniumModule -WebDriver $Seleniumdrivermode -Headless $false
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
        # Navigate to the warranty check URL
        Write-Host "Checking Terra website for serial : $Serial"
        $driver.Navigate().GoToUrl("https://www.wortmann.de/en-gb/profile/snsearch.aspx")
        # Locate and input the serial number into the form
        $serialnumber = $Serial
        $inputField = $driver.FindElementById("ctl00_ctl00_ctl00_SiteContent_SiteContent_SiteContent_textSerialNo")
        $inputField.SendKeys($serialnumber)
        # Find and click the submit button
        $submitButton = $driver.FindElementById("ctl00_ctl00_ctl00_SiteContent_SiteContent_SiteContent_LinkButtonSearch")
        $submitButton.Click()
        Write-Host "Waiting for results......."
        start-sleep -Seconds 10
        # Find the rows in the table
        # Find the table element by its ID
        $table = $driver.FindElementById("ctl00_ctl00_ctl00_SiteContent_SiteContent_SiteContent_DetailsViewProductInfo")

        # Get all rows from the table
        $rows = $table.FindElements([OpenQA.Selenium.By]::TagName("tr"))

        # Create an empty hashtable to store the field-value pairs
        $table1 = @{}

        # Iterate over each row in the table
        foreach ($row in $rows) {
            # Get the cells from the row
            $cells = $row.FindElements([OpenQA.Selenium.By]::TagName("td"))
            
            # Extract the field name and value
            $fieldName = $cells[0].Text
            $fieldValue = $cells[1].Text
            
            # Add the field and value to the hashtable
            $table1[$fieldName] = $fieldValue
        }

        # Close the browser
        Stop-SeleniumModule -WebDriver $Seleniumdrivermode
        $warEndDate = $($table1.'Warranty ending date')
        $warEndDate = [DateTime]::ParseExact($warEndDate, "dd/MM/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
        $warEndDate = $warEndDate.ToString($dateformat)

        $warstartDate = $($table1.'Warranty starting date')
        $warstartDate= [DateTime]::ParseExact($warstartDate, "dd/MM/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
        $warstartDate = $warstartDate.ToString($dateformat)

        $warrantyStatus = $null
        if ($warStartDate -gt (Get-Date)) {
            $warrantyStatus = "Within Warranty"
        } else {
            $warrantyStatus = "Expired"
        }
        
        if ($($table.'Warranty Status')) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $serialnumber
                'Warranty Product name' = $($table1.'Description')
                'StartDate' = $warstartDate
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