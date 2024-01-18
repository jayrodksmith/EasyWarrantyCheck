function Get-Warranty {
    <#
        .SYNOPSIS
        Function to Get warranty info
    
        .DESCRIPTION
        This function will get warranty info of the machine it is called from
    
        .EXAMPLE
        Get-Warranty
        Get-Warranty -Serial "SerialNumber" -Manufacturer "HP" -RMM 'None'
    
        .PARAMETER Serial
        Manually set serial
    
        .PARAMETER Manufacture
        Manually set Manufacturer
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            # RMM Mode
            [Parameter(Mandatory = $false)]
            [ValidateSet('NinjaRMM', 'None')]
            [String]$RMM = 'NinjaRMM',
            #Enable Registry Storing
            [Parameter(Mandatory = $false)]
            [bool]$EnableRegistry = $true,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath = 'HKLM:\SOFTWARE\RMMCustomInfo\',
            # Force Update RMM with details
            [Parameter(Mandatory = $false)]
            [bool]$ForceUpdate = $false,
            # Custom Machine Details
            [Parameter(Mandatory = $false)]
            [String]$Serial = 'Automatic',
            [Parameter(Mandatory = $false)]
            [String]$Manufacturer = 'Automatic',
            # Set Date formats
            [Parameter(Mandatory = $false)]
            [String]$DateFormat = 'dd-MM-yyyy',
            #NinjaRMM Custom Field Names
            [Parameter(Mandatory = $false)]
            [String]$ninjawarrantystart = 'warrantyStart',
            [Parameter(Mandatory = $false)]
            [String]$ninjawarrantyexpiry= 'warrantyExpiry',
            [Parameter(Mandatory = $false)]
            [String]$ninjawarrantystatus = 'warrantystatus',
            [Parameter(Mandatory = $false)]
            [String]$ninjainvoicenumber = 'invoicenumber'

        )
        # Set Global Variables
        if($RMM -eq 'NinjaRMM'){
        Set-Variable ninjawarrantystart -Value $ninjawarrantystart -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantyexpiry -Value $ninjawarrantyexpiry -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantystatus -Value $ninjawarrantystatus -Scope Global -option ReadOnly -Force
        Set-Variable ninjainvoicenumber -Value $ninjainvoicenumber -Scope Global -option ReadOnly -Force
        }
        if($ForceUpdate -eq $true){
        Set-Variable ForceUpdate -Value $ForceUpdate -Scope Global -option ReadOnly -Force
        }
        $machineinfo = Get-MachineInfo
        if($serial -eq 'Automatic'){
            $serialnumber = $machineinfo.serialnumber
        } else {
            $serialnumber = $serial
        }
        if($Manufacturer -eq 'Automatic'){
            $mfg = $machineinfo.Manufacturer
        } else {
            $mfg = $Manufacturer
        }
        
        $Notsupported = $false
        switch -Wildcard ($mfg){
            "EDSYS"{
                $Warobj = Get-WarrantyEdsys -Serial $serialnumber -DateFormat $DateFormat
            }
            "ASUS"{
                $Warobj = Get-WarrantyAsus -Serial $serialnumber -DateFormat $DateFormat
            }
            "LENOVO"{
                $Warobj = Get-WarrantyLenovo -Serial $serialnumber -DateFormat $DateFormat
            }
            "DELL"{
                $Warobj = Get-WarrantyDell -Serial $serialnumber -DateFormat $DateFormat
            }
            "HP"{
                $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat
            }
            "MICROSOFT"{
                if($($machineinfo.Model) -like 'SurfaceNotSupportedYet'){
                    $Warobj = Get-WarrantyMicrosoft -Serial $serialnumber -DateFormat $DateFormat
                } else{
                    $Notsupported = $true
                    Write-Host "Microsoft Model not Supported"
                    Write-Host "Manufacturer  :  $mfg"
                    Write-Host "Model         :  $($machineinfo.Model)"
                }
                
            }
            "TOSHIBA"{
                $Warobj = Get-WarrantyToshiba -Serial $serialnumber -DateFormat $DateFormat
            }
            default{
                $Notsupported = $true
                Write-Host "Manufacturer or Model not Supported"
                Write-Host "Manufacturer  :  $mfg"
                Write-Host "Model         :  $($machineinfo.Model)"
            }
        }
    if($RMM -eq 'NinjaRMM' -and ($Notsupported -eq $false)){
        Write-WarrantyNinjaRMM -DateFormat $DateFormat -Warrantystart $($WarObj.'StartDate') -WarrantyExpiry $($WarObj.'EndDate') -WarrantyStatus $($WarObj.'Warranty Status') -Invoicenumber $($WarObj.'Invoice')
    }
    if($EnableRegistry -and ($Notsupported -eq $false)){
        Write-WarrantyRegistry -RegistryPath $RegistryPath -Warrantystart $($WarObj.'StartDate') -WarrantyExpiry $($WarObj.'EndDate') -WarrantyStatus $($WarObj.'Warranty Status') -Invoicenumber $($WarObj.'Invoice')
    }
return $Warobj
}

function Get-MachineInfo {
<#
    .SYNOPSIS
    Function to get information of machine

    .DESCRIPTION
    This function will get serial number and mfg of system

    .EXAMPLE
    Get-MachineInfo
    Get-MachineInfo -Serial "12345678" -Manufacturer "HP" // (Forces Serial and Make)

    .PARAMETER Serial
    Manually set serial

    .PARAMETER Manufacturer
    Manually set Manufacturer

#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
		[Parameter(Mandatory = $false)]
		[String]$Serial= 'Automatic',
        [Parameter(Mandatory = $false)]
        [ValidateSet('Automatic', 'Dell', 'HP', 'Edsys', 'Asus', 'Lenovo', 'TOSHIBA', 'Intel Corporation')]
		[String]$Manufacturer= 'Automatic'
	)
    $SerialNumber = if ($Serial -eq 'Automatic') {
        (Get-CimInstance win32_bios).SerialNumber
    } else {
        $Serial
    }
    
    $Mfg = if ($Manufacturer -eq 'Automatic') {
        $mfg = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        $model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        switch ($Mfg) {
            "IBM" { $Mfg = "LENOVO" }
            "Hewlett-Packard" { $Mfg = "HP" }
            {$_ -match "Asus"} { $Mfg = "ASUS" }
            {$_ -match "Dell"} { $Mfg = "DELL" }
            {$_ -match "HP"} { $Mfg = "HP" }
            {$_ -match "Edsys"} { $Mfg = "EDSYS" }
            {$_ -match "Lenovo"} { $Mfg = "LENOVO" }
            {$_ -match "Microsoft"} { $Mfg = "MICROSOFT" }
            {$_ -match "TOSHIBA"} { $Mfg = "TOSHIBA" }
            {$_ -match "Intel Corporation"} { 
                $pattern = "^B\d{6}$"
                if ($SerialNumber -match $pattern){
                    $Mfg = "EDSYS"
                }
            }
            default { $Mfg = $Mfg }
        }
        $Mfg
    } else {
        $Manufacturer
    }
    $MachineInfo = [PSCustomObject]@{
        SerialNumber = $SerialNumber
        Manufacturer = $Mfg
        Model = $model
    }
    return $MachineInfo
}

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
            [String]$DateFormat = 'dd-MM-yyyy'
        )
        Get-WebDriver
        Get-SeleniumModule
        $URL = "https://www.dell.com/support/productsmfe/en-us/productdetails?selection=$serial&assettype=svctag&appname=warranty&inccomponents=false&isolated=false"
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
        Write-Host "Checking Dell website for serial : $Serial"
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
            $MatchedText = $DateRegex.Value
            $StatusDate = ($MatchedText -split " ")[1..3] -join " "
        
            # Convert date format (from "dd MMM yyyy" to "dd-MM-yyyy")
            $WarrantyEndDate = [datetime]::ParseExact($StatusDate, "dd MMM yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
            $FormattedDate = $WarrantyEndDate.ToString($dateformat)
        
            # Check if it's expired or not
            if ($MatchedText -like "*Expired*") {
                $warEndDate = $FormattedDate
                $warrantystatus = "Expired"
            } else {
                $warEndDate = $FormattedDate
                $warrantystatus = "In Warranty"
            }
        } else {
            Write-Host "No matching text found for warranty status"
        }
        # Close the browser
        $driver.Quit()
        Remove-Module Selenium

        if ($warrantystatus) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $serial
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $warEndDate
                'Warranty Status' = $warrantystatus
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial' = $serial
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = 'Could not get warranty information'
                'Client' = $null
                'Product Image' = ""
                'Warranty URL' = ""
            }
        } 
    return $WarObj
}

function Get-WarrantyEdsys {
    <#
        .SYNOPSIS
        Function to get Edsys Warranty
    
        .DESCRIPTION
        This function will get Edsys Warranty
    
        .EXAMPLE
        Get-WarrantyEdsys -Serial "B123456"
    
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
        # Define the URL
        Write-Host "Checking Edsys website for serial : $Serial"
        Write-Host "Waiting for results......."
        $url = "https://edsys.com.au/check-warranty-status/"

        # Define the payload as a query string
        $payload = @{
            serial_number = "$Serial"
            submit = "Search"
        }

        # Make the POST request
        $response = Invoke-WebRequest -Uri $url -Method Post -Body $payload -ContentType "application/x-www-form-urlencoded" -UseBasicParsing

        # Output the response
        $responseContent = $response.Content

        # Load the HTML content using a HTML parser
        $HTMLDocument = New-Object -ComObject "HTMLFile"
        try {
            # This works in PowerShell with Office installed
            $HTMLDocument.IHTMLDocument2_write($responseContent)
        } catch {
            # This works when Office is not installed    
            $src = [System.Text.Encoding]::Unicode.GetBytes($responseContent)
            $HTMLDocument.write($src)
        }

        # Find the table within the specific div
        $table = $HTMLDocument.getElementById("warranty_check_result").getElementsByTagName("table") | Select-Object -First 1

        # Convert the table HTML to PowerShell objects
        $objects = New-Object System.Collections.ArrayList
        $headers = @($table.getElementsByTagName("th") | ForEach-Object { $_.innerText.Trim() })

        $tableRows = $table.getElementsByTagName("tr") | Select-Object -Skip 1
        foreach ($row in $tableRows) {
            if ($row -ne $null) {
                $rowData = @($row.getElementsByTagName("td") | ForEach-Object { 
                    if ($_ -ne $null -and $_.innerText -ne $null) {
                        $_.innerText.Trim()
                    } else {
                        ""
                    }
                })
                $obj = [ordered]@{}
                for ($j = 0; $j -lt $headers.Count; $j++) {
                    $obj[$headers[$j]] = $rowData[$j]
                }
                $objects.Add((New-Object -TypeName PSObject -Property $obj)) | Out-Null
            }
            else {
                Write-Host "Warning: Null row encountered."
            }
        }

        # Output the PowerShell objects table
        $table = $objects
        if ($($table.'Title') -eq 'No Results found') {
            Write-Host "No Results found on Edsys Website"
        } else {
            # Check if the "Within Warranty" text exists
            if ($($table.'Warranty Status') -eq "In Warranty" -or $($table.'Warranty Status') -eq 'Under Warranty(Active)') {
                # "Within Warranty" text found
                $warrantystatus = "Within Warranty"
                # Additional actions if needed
            } else {
                # Write-Host "Expired"
                $warrantystatus = "Expired"
            }
            # Date Convert
            $dateString = $($table.'Build Date')
                if ($dateString -match '^\d{4}-\d{2}-\d{2}$') {
                $inputFormat = "yyyy-MM-dd"
                } elseif ($dateString -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') {
                    $inputFormat = "yyyy-MM-dd HH:mm:ss"
                } elseif ($dateString -match '^\d{4}-\d{2}-\d$') {
                    $dateString = $dateString -replace '(\d{4}-\d{2})-(\d)$', '${1}-0${2}' # Add leading zero
                    $inputFormat = "yyyy-MM-dd"
                } else {
                    Write-Host "Date format not recognized"
                }
                $date = [DateTime]::ParseExact($dateString, $inputFormat, [System.Globalization.CultureInfo]::InvariantCulture)
                $warfirst = $date.ToString($dateformat)
            # Add warranty type to Converted Date
            $warrantyYears = $($table.'Warranty Type') -replace 'Years', '' -replace '\s', ''
            $warrantyYears = $warrantyYears -replace 'RTD', ''
            $warrantyYears = $warrantyYears -replace 'ONE', ''
            $date = [DateTime]::ParseExact($dateString, $inputFormat, [System.Globalization.CultureInfo]::InvariantCulture)
            $warEndDate = $date.AddYears($warrantyYears)
            $warEndDate = $warEndDate.ToString($dateformat)
        }
        
        if ($($table.'Warranty Status')) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $($table.'Invoice')
                'Warranty Product name' = $($table.'Product Name')
                'StartDate' = $warfirst
                'EndDate' = $warEndDate
                'Warranty Status' = $warrantystatus
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = 'Could not get warranty information'
                'Client' = $Client
                'Product Image' = ""
                'Warranty URL' = ""
            }
        }
    return $WarObj
}

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
            Write-Host "Estimating Details from Registry"
            try {
                $regPath = "HKLM:\SOFTWARE\WOW6432Node\HP\HPActiveSupport\HPSF\Warranty"
                $wsd = Get-ItemProperty -Path $regPath -Name "WSD" -ErrorAction Stop | Select-Object -ExpandProperty "WSD"
                # Convert string to date format
                $wsd = [DateTime]::ParseExact($wsd, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture)
                $wsd = Get-Date $wsd -Format $DateFormat
                Write-Host "Warranty Start: $wsd"
                $WarObj = [PSCustomObject]@{
                    'Serial' = $Serial
                    'Warranty Product name' = $null
                    'StartDate' = $wsd
                    'EndDate' = $null
                    'Warranty Status' = 'Could not get warranty information'
                    'Client' = $null
                    'Product Image' = $null
                    'Warranty URL' = $null
                }
                Remove-Module Selenium
                return $warObj
            }catch{
                Write-Host "No details in registry"
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
        try{
            $errorMsgElement = $driver.FindElementByClassName("errorTxt")
        }catch{
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
            } catch {
                Write-Host "SystemSKU key does not exist in the specified registry path."
                Exit 0
            }
        } else {
                # Continue   
        }
        # Find the element containing the 'Start date' text
        try {
            $startDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c70-0 ng-star-inserted']//div[@class='label ng-tns-c70-0' and contains(text(), 'Start date')]/following-sibling::div[@class='text ng-tns-c70-0']")
        } catch{
            $startDateElement = $null
        }
        if (-not $startDateElement) {
            try {
                $startDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c72-0 ng-star-inserted']//div[@class='label ng-tns-c72-0' and contains(text(), 'Start date')]/following-sibling::div[@class='text ng-tns-c72-0']")
            } catch{
                Write-Host "Could not find warranty Start date"
            }
        }
        if($startDateElement){
            # Get the text of the 'Start date' element
            $startDateText = $startDateElement.Text
            $startDateText = Get-Date $startDateText -Format $dateformat
        }     
        try {
        # Find the element containing the 'End date' text
        $endDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c70-0 ng-star-inserted']//div[@class='label ng-tns-c70-0' and contains(text(), 'End date')]/following-sibling::div[@class='text ng-tns-c70-0']")
        }catch{
            $endDateElement = $null
        }
        if (-not $endDateElement) {
            try {
                $endDateElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c72-0 ng-star-inserted']//div[@class='label ng-tns-c72-0' and contains(text(), 'End date')]/following-sibling::div[@class='text ng-tns-c72-0']")
            } catch{
                Write-Host "Could not find warranty End date"
            }
        }
        if($endDateElement){
            # Get the text of the 'End date' element
            $endDateText = $endDateElement.Text
            $endDateText = Get-Date $endDateText -Format $dateformat
        }     
        try{
            # Find the element containing the 'Warranty Status' or 'Time Remaining' text
            $warrantyStatusElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c70-0 ng-star-inserted']//div[@class='label ng-tns-c70-0' and contains(text(), 'Time Remaining')]/following-sibling::div[@class='text ng-tns-c70-0']")       
        }catch{
            $warrantyStatusElement = $null
        }
        if (-not $warrantyStatusElement) {
            try {
                $warrantyStatusElement = $driver.FindElementByXPath("//div[@class='info-item ng-tns-c72-0 ng-star-inserted']//div[@class='label ng-tns-c72-0' and contains(text(), 'Time Remaining')]/following-sibling::div[@class='text ng-tns-c72-0']")       
            } catch{
                Write-Host "Could not find warranty Status"
            } 
        }
        if($warrantyStatusElement){
            $warrantyStatusText = $warrantyStatusElement.Text
            if ($warrantyStatusText -match "Expired") {
                $warrantyStatusText = "Expired"
            }
        }     
        try {
            # Find the element containing the 'Product' information
            $h2Element = $driver.FindElementByCssSelector(".product-info-text.ng-tns-c70-0 > h2")
        }catch {
            $h2Element = $null
        }
        if (-not $h2Element) {
            try {
                # Find the element containing the 'Product' information
                $h2Element = $driver.FindElementByCssSelector(".product-info-text.ng-tns-c72-0 > h2")
            }catch {
                $h2Element = $null
            }
        }
        if ($h2Element){
            $product = $h2Element.Text
        }
        # Close the browser
        $driver.Quit()
        Remove-Module Selenium

        if ($endDateText) {
            $warfirst = $startDateText
            $warlatest = $endDateText
            $WarObj = [PSCustomObject]@{
                'Serial' = $serialnumber
                'Warranty Product name' = $product
                'StartDate' = $warfirst
                'EndDate' = $warlatest
                'Warranty Status' = $warrantyStatusText
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial' = $serialnumber
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

function Get-WarrantyLenovo {
    <#
        .SYNOPSIS
        Function to get Lenovo Warranty
    
        .DESCRIPTION
        This function will get Lenovo Warranty
    
        .EXAMPLE
        Get-WarrantyLenovo -Serial "SerialNumber"
    
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
        Write-Host "Checking Lenovo website for serial : $Serial"
        Write-Host "Waiting for results......."
        $APIURL = "https://pcsupport.lenovo.com/us/en/api/v4/mse/getproducts?productId=$Serial"
        $WarReq = Invoke-RestMethod -Uri $APIURL -Method get
        if($WarReq.id){
            $APIURL = "https://pcsupport.lenovo.com/us/en/products/$($WarReq.id)/warranty"
            $WarReq = Invoke-RestMethod -Uri $APIURL -Method get
            $search = $WarReq |Select-String -Pattern "var ds_warranties = window.ds_warranties \|\| (.*);[\r\n]*"
            $jsonWarranties = $search.matches.groups[1].value |ConvertFrom-Json
            }

        if ($jsonWarranties.BaseWarranties) {
            $warfirst = $jsonWarranties.BaseWarranties |sort-object -property [DateTime]End |select-object -first 1
            $warlatest = $jsonWarranties.BaseWarranties |sort-object -property [DateTime]End |select-object -last 1
            $warfirst.Start = [DateTime]($warfirst.Start)
            $warlatest.End = [DateTime]($warlatest.End)
            $WarObj = [PSCustomObject]@{
                'Serial' = $jsonWarranties.Serial
                'Warranty Product name' = $jsonWarranties.ProductName
                'StartDate' = $warfirst.Start.ToString($dateformat)
                'EndDate' = $warlatest.End.ToString($dateformat)
                'Warranty Status' = $warlatest.StatusV2
                'Client' = $null
                'Product Image' = $jsonWarranties.ProductImage
                'Warranty URL' = $jsonWarranties.WarrantyUpgradeURLInfo.WarrantyURL
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

function Get-WarrantyMicrosoft {
    <#
        .SYNOPSIS
        Function to get Microsoft Warranty
    
        .DESCRIPTION
        This function will get Microsoft Warranty
    
        .EXAMPLE
        Get-WarrantyMicrosoft -Serial "0123456789"
    
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
        # Define the URL
        Write-Host "Checking Microsoft website for serial : $Serial"
        Write-Host "Waiting for results......."
        $url = "https://surface.managementservices.microsoft.com/api/warranty"
        $referer = "https://surface.managementservices.microsoft.com"

        # Define the payload as a query string
        $payload = @{
            CurrentLanguage = "en-US"
            SelectedCountry = "AUS"
            InputSerialNumber = "023959701357"
            'ValidateCaptchaRequest.CaptchaRequestInput.InputSolution' = 'G5pYd4'
            'ValidateCaptchaRequest.CaptchaRequestInput.ChallengeId'= 'adbe704a-71b6-4ad1-abd3-61bed015185c'
            'ValidateCaptchaRequest.ChallengeType'= 'visual'
            'ValidateCaptchaRequest.CaptchaRequestHeader.ClientRequestId'= '41985dcf-404d-404a-8031-dcae02a9601a'
            'ValidateCaptchaRequest.CaptchaRequestHeader.CorrelationId'= '47cdd5b2-5d21-4b30-8ef0-7ddad5288875'
            'ValidateCaptchaRequest.CaptchaRequestHeader.MSRequestId'= 'f9de331c-62a7-44a7-8f06-fff02cd3cd36'
            '__RequestVerificationToken' = 'CfDJ8Bs2gZRbq61Fh3kwFwaLFZMbObGv4Z0-1hId2kVulzA7ZcraSW-tfVNiIFq0lQUL6PQOXZV6C7ttYVYoWqDsyfgW1-O-SkLxysDK7-2BzuejSIK7YEdbANVS4qbXYKcQZ90xdZwxqqiMDUwjyxHuzlA'
        }
        
        $headers = @{
            Referer = $referer
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }

        $response = Invoke-WebRequest -Uri $url -Method Post -Body $payload -ContentType "application/json" -UseBasicParsing -Headers $headers

        if ($($table.'Warranty Status')) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = $null
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = 'Could not get warranty information'
                'Client' = $null
                'Product Image' = ""
                'Warranty URL' = ""
            }
        }
    return $WarObj
}

function Get-WarrantyToshiba {
    <#
        .SYNOPSIS
        Function to get Toshiba Warranty
    
        .DESCRIPTION
        This function will get Toshiba Warranty
    
        .EXAMPLE
        Get-WarrantyToshiba -Serial "123456789"
    
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
        # Define the URL
        Write-Host "Checking Toshiba website for serial : $Serial"
        Write-Host "Waiting for results......."
        $url2 = "https://support.dynabook.com/support/warrantyResults?sno=$serial&mpn=$partnumber"
        $url = "https://support.dynabook.com/support/warrantyResults?sno=$serial"

        $response = Invoke-WebRequest -Uri $url 
        $responseContent = $response.Content
        $responseJson =  $responseContent | ConvertFrom-Json
        $repsonsedetails = $responseJson.commonbean
        # Parse the input date
        $startDate = [DateTime]::ParseExact($($repsonsedetails.warOnsiteDate), "yyyy-MM-dd HH:mm:ss.f", [System.Globalization.CultureInfo]::InvariantCulture)
        $endDate = [DateTime]::ParseExact($($repsonsedetails.warrantyExpiryDate), "yyyy-MM-dd HH:mm:ss.f", [System.Globalization.CultureInfo]::InvariantCulture)
        # Format the date using the desired format
        $warstartDate = $startDate.ToString($dateformat)
        $warendDate = $endDate.ToString($dateformat)
        if ($($responseJson.warranty) -match 'Warranty Expired!'){
            $warrantystatus = "Expired"
        }else{
            $warrantystatus = "In Warranty"
        }

        if ($warrantystatus) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = "$($repsonsedetails.ModelFamily) $($repsonsedetails.ModelName)"
                'StartDate' = $warstartDate
                'EndDate' = $warendDate
                'Warranty Status' = $warrantystatus
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $url
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
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

function Get-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Get SelniumModule
    
        .DESCRIPTION
        This function will get SelniumModule and install if not installed

        .EXAMPLE
        Get-SelniumModule
    
    #>
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet
    $seleniumModule = Get-Module -Name Selenium -ListAvailable
    if (-not $seleniumModule) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap | Out-Null
        Install-Module Selenium -Force
    }
    Import-Module Selenium -Force
}

function Get-WarrantyNinjaRMM {
    <#
        .SYNOPSIS
        Function to get details to NinjaRMM
    
        .DESCRIPTION
        This function will get details to NinjaRMM
    
        .EXAMPLE
        Get-WarrantyNinjaRMM
    
        .PARAMETER Display
        Output Warranty Result
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [Switch]$Display
        )
        
        $ninjawarrantystartvalue = Ninja-Property-Get $ninjawarrantystart
        $ninjawarrantystatusvalue = Ninja-Property-Get $ninjawarrantystatus
        $ninjawarrantyexpiryvalue = Ninja-Property-Get $ninjawarrantyexpiry
        $ninjainvoicenumbervalue = Ninja-Property-Get $ninjainvoicenumber
        if ($null -ne $ninjawarrantystatusvalue){
            if ($Display){
                return $ninjawarrantystatusvalue
            } else {
                return $true
            } 
        } else {
            return $false
        }
    }

function Get-WarrantyRegistry {
    <#
        .SYNOPSIS
        Function to get details from Registry
    
        .DESCRIPTION
        This function will get details from Registry
    
        .EXAMPLE
        Get-WarrantyRegistry
    
        .PARAMETER Display
        Output Warranty Result
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [Switch]$Display,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath= 'HKLM:\SOFTWARE\RMMCustomInfo'
        )
        $registryValue = Get-ItemProperty -Path $RegistryPath -Name 'WarrantyStatus' -ErrorAction SilentlyContinue
        return ($null -ne $registryValue -and $null -ne $registryValue.WarrantyStatus)
    }

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

function Write-WarrantyNinjaRMM {
    <#
        .SYNOPSIS
        Function to write details to NinjaRMM
    
        .DESCRIPTION
        This function will write details to NinjaRMM
    
        .EXAMPLE
        Write-WarrantyNinjaRMM -Warrantystart 'value' -WarrantyExpiry 'value' -WarrantyStatus 'value' -Invoicenumber 'value'
    
        .PARAMETER Serial
        Manually set serial
    
        .PARAMETER Manufacture
        Manually set Manufacture
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $false)]
            [String]$Warrantystart= '',
            [Parameter(Mandatory = $false)]
            [String]$WarrantyExpiry= '',
            [Parameter(Mandatory = $false)]
            [String]$WarrantyStatus = '',
            [Parameter(Mandatory = $false)]
            [String]$Invoicenumber= '',
            [Parameter(Mandatory = $false)]
            [String]$dateformat= 'dd-MM-yyyy'
        )
        if (-not (Get-Command -Name "Ninja-Property-Set" -ErrorAction SilentlyContinue)) {
            $errorMessage = "Error: NinjaRMM module not found, not writing to NinjaRMM."
            return $errorMessage
        }
        $WarrantyNinjaRMM = Get-WarrantyNinjaRMM
        if($WarrantyNinjaRMM -eq $true -and ($ForceUpdate -eq $false)){
            return "Warranty details already in NinjaRMM"
        } else {
                if($Warrantystart){
                    $Warrantystart = [DateTime]::ParseExact($Warrantystart, $dateformat, $null)
                    $Warrantystartutc = Get-Date $Warrantystart -Format "yyyy-MM-dd"
                }
                if($WarrantyExpiry){
                    $WarrantyExpiry = [DateTime]::ParseExact($WarrantyExpiry, $dateformat, $null)
                    $WarrantyExpiryutc = Get-Date $WarrantyExpiry -Format "yyyy-MM-dd"
                }
                if($Warrantystartutc){Ninja-Property-Set $ninjawarrantystart $Warrantystartutc}
                if($WarrantyExpiryutc){Ninja-Property-Set $ninjawarrantyexpiry $WarrantyExpiryutc}
                if($WarrantyStatus){Ninja-Property-Set $ninjawarrantystatus $WarrantyStatus}
                if($Invoicenumber){Ninja-Property-Set $ninjainvoicenumber $Invoicenumber}
                return "Warranty details saved to NinjaRMM"
                }
    }

function Write-WarrantyRegistry{
    <#
        .SYNOPSIS
        Function to write details to Registry
    
        .DESCRIPTION
        This function will write details to Registry
    
        .EXAMPLE
        Write-WarrantyRegistry -Warrantystart 'value' -WarrantyExpiry 'value' -WarrantyStatus 'value' -Invoicenumber 'value'
    
        .PARAMETER Serial
        Manually set serial
    
        .PARAMETER Manufacture
        Manually set Manufacture
    
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory = $true)]
            [String]$Warrantystart,
            [Parameter(Mandatory = $true)]
            [String]$WarrantyExpiry,
            [Parameter(Mandatory = $true)]
            [String]$WarrantyStatus,
            [Parameter(Mandatory = $true)]
            [String]$Invoicenumber,
            [Parameter(Mandatory = $false)]
            [String]$RegistryPath= 'HKLM:\SOFTWARE\RMMCustomInfo'
        )
        $registryvalue = Get-WarrantyRegistry $RegistryPath
        if($registryvalue -eq $true -and ($ForceUpdate -eq $false)){
            return "Warranty details already in Registry"
        } else {
                if (-not (Test-Path $RegistryPath)) {
                    # Create the registry key if it doesn't exist
                    New-Item -Path $RegistryPath -Force -ErrorAction SilentlyContinue | Out-Null
                    Write-Debug "Registry key created successfully."
                } else {
                    Write-Debug "Registry key already exists."
                }
                if($Warrantystart){
                    New-ItemProperty -Path $RegistryPath -Name "WarrantyStart" -PropertyType String -Value $Warrantystart -Force -ErrorAction SilentlyContinue | Out-Null
                }
                if($WarrantyExpiry){
                    New-ItemProperty -Path $RegistryPath -Name "WarrantyExpiry" -PropertyType String -Value $WarrantyExpiry -Force -ErrorAction SilentlyContinue | Out-Null
                }
                if($WarrantyStatus){
                    New-ItemProperty -Path $RegistryPath -Name "WarrantyStatus" -PropertyType String -Value $WarrantyStatus -Force -ErrorAction SilentlyContinue | Out-Null
                }
                if($Invoicenumber){
                    New-ItemProperty -Path $RegistryPath -Name "Invoicenumber" -PropertyType String -Value $Invoicenumber -Force -ErrorAction SilentlyContinue | Out-Null
                }
                return "Warranty details saved to Registry $RegistryPath"
                }
    }

Get-Warranty
