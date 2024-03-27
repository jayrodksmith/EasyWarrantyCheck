function Get-WarrantyDell {
    <#
        .SYNOPSIS
        Function to get Dell Warranty
    
        .DESCRIPTION
        This function will get Dell Warranty
    
        .EXAMPLE
        Get-WarrantyDell -Serial "SerialNumber"
    
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
            [String]$DateFormat = $DateFormatGlobal,
            [Parameter(Mandatory = $false)]
            [String]$NinjaOrg
        )

        if ($browsersupport -eq $false){
            $WarObj = [PSCustomObject]@{
                'Serial'                = $Serial
                'Warranty Product name' = $null
                'StartDate'             = $null
                'EndDate'               = $null
                'Warranty Status'       = 'Could not get warranty information'
                'Manufacturer'          = 'Dell'
                'Client'                = $null
                'Product Image'         = $null
                'Warranty URL'          = $null
            }
            Remove-Module Selenium -Verbose:$false
            return $warObj
        }
        # Start a new browser session with headless mode
        try{
            Get-WebDriver -WebDriver $DriverMode
            Get-SeleniumModule
            $driver = Start-SeleniumModule -WebDriver $DriverMode -Headless $true
        }catch{
            Write-Verbose $_.Exception.Message
            $WarObj = [PSCustomObject]@{
                'Serial'                = $Serial
                'Warranty Product name' = $null
                'StartDate'             = $null
                'EndDate'               = $null
                'Warranty Status'       = 'Could not get warranty information'
                'Manufacturer'          = 'Dell'
                'Client'                = $null
                'Product Image'         = $null
                'Warranty URL'          = $null
            }
            Remove-Module Selenium -Verbose:$false
            return $warObj
        }
        # Navigate to the warranty check URL
        Write-Host "Checking Dell website for serial : $Serial"
        $URL = "https://www.dell.com/support/productsmfe/en-us/productdetails?selection=$serial&assettype=svctag&appname=warranty&inccomponents=false&isolated=false"
        $driver.Navigate().GoToUrl("$URL")
        Write-Host "Waiting for results......."
        Start-Sleep -Seconds 25
        
        # Find all elements on the page
        $AllElements = $driver.FindElementsByTagName("body")
        
        # Get inner text of the page
        $PageText = $AllElements[0].Text
        
        # Regular expression pattern to match "Expired" or "Expires" followed by a date
        $DateRegex = [regex]::Matches($PageText, '(Expired|Expires)\s(\d{1,2}\s[A-Z]{3}\s\d{4})')
        
        if ($DateRegex.Success) {
            # Extract the matched date
            $MatchedText        = $DateRegex.Value
            $StatusDate         = ($MatchedText -split " ")[1..3] -join " "
        
            # Convert date format (from "dd MMM yyyy" to "dd-MM-yyyy")
            $WarrantyEndDate    = [datetime]::ParseExact($StatusDate, "dd MMM yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
            $FormattedDate      = $WarrantyEndDate.ToString($dateformat)
        
            # Check if it's expired or not
            if ($MatchedText -like "*Expired*") {
                $warEndDate     = $FormattedDate
                $warrantystatus = "Expired"
            } else {
                $warEndDate     = $FormattedDate
                $warrantystatus = "In Warranty"
            }
            # Try for Start Date
            try {
                $checkDeviceDetails = $driver.FindElementByClassName("dds__button--secondary")
                $checkDeviceDetails.Click()
                Start-Sleep -Seconds 10
                $ManageServicesButton = $driver.FindElementByClassName("viewDetailsWarranty")
                $ManageServicesButton.Click()
                Start-Sleep -Seconds 10
                $PurchaseDateElement = $driver.FindElementById("dsk-purchaseDt")
                $PurchaseDate = $PurchaseDateElement.Text
                $WarrantystartDate = [datetime]::ParseExact($PurchaseDate, "dd MMM yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
                $warStartDate = $WarrantystartDate.ToString($dateformat)
            } catch {
                Write-Host "The purchase date field could not be found."
                $warStartDate = $null
            }
            
        } else {
            Write-Host "No matching text found for warranty end date "
        }
        # Close the browser
        Stop-SeleniumModule -WebDriver $DriverMode

        if ($warrantystatus) {
            $WarObj = [PSCustomObject]@{
                'Serial'                = $serial
                'Warranty Product name' = $null
                'StartDate'             = $warStartDate
                'EndDate'               = $warEndDate
                'Warranty Status'       = $warrantystatus
                'Manufacturer'          = 'Dell'
                'Client'                = $null
                'Product Image'         = $null
                'Warranty URL'          = $null
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial'                = $serial
                'Warranty Product name' = $null
                'StartDate'             = $null
                'EndDate'               = $null
                'Warranty Status'       = 'Could not get warranty information'
                'Manufacturer'          = 'Dell'
                'Client'                = $null
                'Product Image'         = $null
                'Warranty URL'          = $null
            }
        } 
    return $WarObj
}