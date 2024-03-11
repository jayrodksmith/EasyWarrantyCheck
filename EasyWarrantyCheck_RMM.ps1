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
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
    Param(
        # RMM Mode, available in both Default and CentralNinja sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [ValidateSet('NinjaRMM', 'None')]
        [String]$RMM = 'NinjaRMM',
        
        # Web Driver mode, Edge or Chrome ( Edge Beta Support )
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [ValidateSet('Chrome', 'Edge')]
        [String]$Seleniumdrivermode = 'Chrome',

        # ServerMode, exclusive to CentralNinja but included in Default for consistency
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [Switch]$ServerMode,
    
        # Enable Registry Storing
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [bool]$EnableRegistry = $true,

        # Registry Path
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [String]$RegistryPath = 'HKLM:\SOFTWARE\RMMCustomInfo\',
    
        # Force Update RMM with details
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [bool]$ForceUpdate = $false,
    
        # Custom Machine Details, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$Serial = 'Automatic',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$Manufacturer = 'Automatic',
    
        # Set Date formats, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$DateFormat = 'dd-MM-yyyy',
    
        # NinjaRMM Custom Field Names, available in both sets
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjawarrantystart = 'warrantyStart',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjawarrantyexpiry = 'warrantyExpiry',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjawarrantystatus = 'warrantystatus',
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$ninjainvoicenumber = 'invoicenumber',

        [Parameter(Mandatory = $false, ParameterSetName = 'CentralNinja')]
        [String]$HpSystemSKU
            
    )
    # Set Global Variables
    if ($RMM -eq 'NinjaRMM') {
        Set-Variable ninjawarrantystart -Value $ninjawarrantystart -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantyexpiry -Value $ninjawarrantyexpiry -Scope Global -option ReadOnly -Force
        Set-Variable ninjawarrantystatus -Value $ninjawarrantystatus -Scope Global -option ReadOnly -Force
        Set-Variable ninjainvoicenumber -Value $ninjainvoicenumber -Scope Global -option ReadOnly -Force
    }
    if ($ForceUpdate -eq $true) {
        Set-Variable ForceUpdate -Value $ForceUpdate -Scope Global -option ReadOnly -Force
    }
    if ($Seleniumdrivermode) {
        Set-Variable Seleniumdrivermode -Value $Seleniumdrivermode -Scope Global -option ReadOnly -Force
    }
    if ($PSCmdlet.ParameterSetName -eq 'Default') {
        $machineinfo = Get-MachineInfo
        if ($serial -eq 'Automatic') {
            $serialnumber = $machineinfo.serialnumber
        }
        else {
            $serialnumber = $serial
        }
        if ($Manufacturer -eq 'Automatic') {
            $mfg = $machineinfo.Manufacturer
        }
        else {
            $mfg = $Manufacturer
        }
    } else {
        $serialnumber = $serial
        $mfg = $Manufacturer
        $global:ServerMode = $true
    }
        
    $Notsupported = $false
    switch -Wildcard ($mfg) {
        "EDSYS" {
            $Warobj = Get-WarrantyEdsys -Serial $serialnumber -DateFormat $DateFormat
        }
        "ASUS" {
            $Warobj = Get-WarrantyAsus -Serial $serialnumber -DateFormat $DateFormat
        }
        "LENOVO" {
            $Warobj = Get-WarrantyLenovo -Serial $serialnumber -DateFormat $DateFormat
        }
        "DELL" {
            $Warobj = Get-WarrantyDell -Serial $serialnumber -DateFormat $DateFormat
        }
        "HP" {
            if ($HpSystemSKU) {
                $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat -SystemSKU $HpSystemSKU
            }
            else {
                $Warobj = Get-WarrantyHP -Serial $serialnumber -DateFormat $DateFormat
            }
        }
        "MICROSOFT" {
            if ($($machineinfo.Model) -like 'SurfaceNotSupportedYet') {
                $Warobj = Get-WarrantyMicrosoft -Serial $serialnumber -DateFormat $DateFormat
            }
            else {
                $Notsupported = $true
                Write-Host "Microsoft Model not Supported"
                Write-Host "Manufacturer  :  $mfg"
                Write-Host "Model         :  $($machineinfo.Model)"
            }
                
        }
        "TOSHIBA" {
            $Warobj = Get-WarrantyToshiba -Serial $serialnumber -DateFormat $DateFormat
        }
        default {
            $Notsupported = $true
            Write-Host "Manufacturer or Model not Supported"
            Write-Host "Manufacturer  :  $mfg"
            Write-Host "Model         :  $($machineinfo.Model)"
        }
    }
    if ($RMM -eq 'NinjaRMM' -and ($Notsupported -eq $false) -and !$ServerMode.IsPresent) {
        $ParamsNinjaRMM = @{
            DateFormat = $DateFormat
        }
        if ($WarObj.'StartDate') {
            $ParamsNinjaRMM['Warrantystart'] = $WarObj.'StartDate'
        }
        if ($WarObj.'EndDate') {
            $ParamsNinjaRMM['WarrantyExpiry'] = $WarObj.'EndDate'
        }
        if ($WarObj.'Warranty Status') {
            $ParamsNinjaRMM['WarrantyStatus'] = $WarObj.'Warranty Status'
        }
        if ($WarObj.'Invoice') {
            $ParamsNinjaRMM['Invoicenumber'] = $WarObj.'Invoice'
        }
        Write-WarrantyNinjaRMM @ParamsNinjaRMM
    }
    if ($EnableRegistry -and ($Notsupported -eq $false) -and !$ServerMode.IsPresent) {
        $Params = @{}
        if ($WarObj.'StartDate') {
            $Params['Warrantystart'] = $WarObj.'StartDate'
        }
        if ($WarObj.'EndDate') {
            $Params['WarrantyExpiry'] = $WarObj.'EndDate'
        }
        if ($WarObj.'Warranty Status') {
            $Params['WarrantyStatus'] = $WarObj.'Warranty Status'
        }
        if ($WarObj.'Invoice') {
            $Params['Invoicenumber'] = $WarObj.'Invoice'
        }
        Write-WarrantyRegistry -RegistryPath $RegistryPath @Params
    }
    if($null -eq $($Warobj.'EndDate') -and $ServerMode.IsPresent) {
        return $null
    }
    elseif($null -eq $($Warobj.'EndDate')) {
    Write-Output "No Warranty End Date Found"
    $Warobj
    Start-Sleep -Seconds 5
    exit 1
} else {
    return $warobj
}
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
            Remove-Module Selenium
            return $warObj
        }
        # Start a new browser session with headless mode
        try{
            $driver = Start-SeleniumModule -WebDriver $Seleniumdrivermode -Headless $true
        }catch{
            Write-Debug $_.Exception.Message
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
        try{
            $submitcheckcookiesButton = $driver.FindElementByXPath("//div[@class='btn-asus btn-ok btn-read-ck' and @aria-label='Accept']")
            $submitcheckcookiesButton.Click()
        } catch{
            Write-Debug $_.Exception.Message
        }
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
        Stop-SeleniumModule -WebDriver $Seleniumdrivermode
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
            Remove-Module Selenium
            return $warObj
        }
        # Start a new browser session with headless mode
        try{
            $driver = Start-SeleniumModule -WebDriver $Seleniumdrivermode -Headless $true
        }catch{
            Write-Debug $_.Exception.Message
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
        Stop-SeleniumModule -WebDriver $Seleniumdrivermode

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
        try {
            $response = Invoke-WebRequest -Uri $url -Method Post -Body $payload -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
        }catch{
            Write-Debug $_.Exception.Message
        }
        if($response){
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
                'Client' = $null
                'Product Image' = $null
                'Warranty URL' = $null
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
        [String]$DateFormat = 'dd-MM-yyyy',
        [Parameter(Mandatory = $false)]
        [String]$SystemSKU
    )
        Get-WebDriver -WebDriver $Seleniumdrivermode
        Get-SeleniumModule
        if ($Seleniumdrivermode -eq "Chrome" ){
            $browserinstalled = Test-SoftwareInstalled -SoftwareName "Google Chrome"
        }
        if ($Seleniumdrivermode -eq "Edge" ){
            $browserinstalled = Test-SoftwareInstalled -SoftwareName "Microsoft Edge"
        }
    # Start a new browser session with headless mode
    try {
        $driver = Start-SeleniumModule -WebDriver $Seleniumdrivermode -Headless $true
    }
    catch {
        if ($PSCmdlet.ParameterSetName -eq 'Default') {
            Write-Debug $_.Exception.Message
            Write-Host "###########################"
            Write-Host "WARNING"
            Write-Host "$($browserinstalled.software) not detected"
            Write-Host "This manufacturer currently requires $($browserinstalled.software) installed to check expiry"
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
        }
        else {
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

    if ($null -ne $errorMsgElement -and $null -ne $SystemSKU) {
        # Error message found
        Write-Host "Using SystemSKU input"
        Write-Debug "Need Product ID"
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
    Stop-SeleniumModule -WebDriver $Seleniumdrivermode

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
        try {
            $WarReq = Invoke-RestMethod -Uri $APIURL -Method get
        }catch{
            Write-Host $($_.Exception.Message)
        }
        if($WarReq.id){
            $APIURL = "https://pcsupport.lenovo.com/us/en/products/$($WarReq.id)/warranty"
            $WarReq = Invoke-RestMethod -Uri $APIURL -Method get
            $search = $WarReq |Select-String -Pattern "var ds_warranties = window.ds_warranties \|\| (.*);[\r\n]*"
            $jsonWarranties = $search.matches.groups[1].value |ConvertFrom-Json
            }

            $checkenddateexists = $jsonWarranties.EntireWarrantyPeriod | Select-Object "End"

        if ( $checkenddateexists.end -ne "0") {
            $warfirst = $jsonWarranties.EntireWarrantyPeriod | Select-Object "Start"
            $warlatest = $jsonWarranties.EntireWarrantyPeriod | Select-Object "End"
            $warRemainingdays = $jsonWarranties.Remainingdays
            if($warRemainingdays -gt 0){
                $warrantystatus = "Active"
            }else{
                $warrantystatus = "Expired"
            }
            $warfirst.Start = Convert-EpochToDateTime -EpochTimestamp $($warfirst.Start)
            $warlatest.End = Convert-EpochToDateTime -EpochTimestamp $($warlatest.End)
            $WarObj = [PSCustomObject]@{
                'Serial' = $jsonWarranties.Serial
                'Warranty Product name' = $jsonWarranties.ProductName
                'StartDate' = $warfirst.Start
                'EndDate' = $warlatest.End
                'Warranty Status' = $warrantystatus
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
        try{
            $response = Invoke-WebRequest -Uri $url
        }catch{
            Write-Host $($_.Exception.Message)
        }
        if($response){
        $responseContent = $response.Content
        $responseJson =  $responseContent | ConvertFrom-Json
        $responsedetails = $responseJson.commonbean
        # Parse the input date
        $startDate = [DateTime]::ParseExact($($responsedetails.warOnsiteDate), "yyyy-MM-dd HH:mm:ss.f", [System.Globalization.CultureInfo]::InvariantCulture)
        $endDate = [DateTime]::ParseExact($($responsedetails.warrantyExpiryDate), "yyyy-MM-dd HH:mm:ss.f", [System.Globalization.CultureInfo]::InvariantCulture)
        # Format the date using the desired format
        $warstartDate = $startDate.ToString($dateformat)
        $warendDate = $endDate.ToString($dateformat)
        if ($($responseJson.warranty) -match 'Warranty Expired!'){
            $warrantystatus = "Expired"
        }else{
            $warrantystatus = "In Warranty"
        }
        }
        if ($warrantystatus) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = "$($responsedetails.ModelFamily) $($responsedetails.ModelName)"
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

function Convert-EpochToDateTime {
    <#
        .SYNOPSIS
        Function to convert Epoch time
    
        .DESCRIPTION
        This function will get convert Epoch time to UTC time

        .EXAMPLE
        Convert-EpochToDateTime -EpochTimestamp "Epochtime"
    
    #>
    param(
        [long]$EpochTimestamp,
        [Parameter(Mandatory = $false)]
        [String]$DateFormat = 'dd-MM-yyyy'
    )

    # Convert to DateTime
    $dateTime = (Get-Date "1970-01-01 00:00:00").AddMilliseconds($EpochTimestamp)

    # Return the readable date
    return $dateTime.ToString($DateFormat)
}

function Get-RunAsUserModule {
    <#
        .SYNOPSIS
        Function to Get RunAsUser
    
        .DESCRIPTION
        This function will get RunAsUser and install if not installed

        .EXAMPLE
        Get-RunAsUser
    
    #>
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {
        
    }
    Import-Module PowerShellGet
    $RunAsUser = Get-Module -Name RunAsUser -ListAvailable | Where-Object { $_.Version -eq '2.4.0' }
    if (-not $RunAsUser) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap | Out-Null
        Install-Module RunAsUser -Force -RequiredVersion '2.4.0'
    }
    Import-Module RunAsUser -Force -Version '2.4.0'
}


function Get-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Get SeleniumModule
    
        .DESCRIPTION
        This function will get SeleniumModule and install if not installed

        .EXAMPLE
        Get-SelniumModule
    
    #>
    try {
        Set-ExecutionPolicy Bypass -scope Process -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{
        
    }
    Import-Module PowerShellGet
    $seleniumModule = Get-Module -Name Selenium -ListAvailable | Where-Object { $_.Version -eq '3.0.1' }
    if (-not $seleniumModule) {
        Get-PackageProvider -Name "nuGet" -ForceBootstrap | Out-Null
        Install-Module Selenium -Force -RequiredVersion '3.0.1'
    }
    Import-Module Selenium -Force -Version '3.0.1'
}

function Get-SeleniumModule4 {
    <#
        .SYNOPSIS
        Function to Get SeleniumModule4
    
        .DESCRIPTION
        This function will get SeleniumModule4 and install if not installed

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
        Install-Module -Name Selenium -AllowPrerelease
    }
    Import-Module Selenium -Force
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
        Function to Get required WebDriver
    
        .DESCRIPTION
        This function will get Web Driver specified
    
        .EXAMPLE
        Get-WebDriver -WebDriver "Chrome"
        Get-WebDriver -WebDriver "Edge"

    #>
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Chrome', 'Edge')]
        [String]$WebDriver = "Chrome",

        $registryRoot        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths",             # root location in registry to check version of currently installed apps
        $edgeRegistryPath    = "$registryRoot\msedge.exe",                                              # direct registry location for MS Edge (to check version)
        $chromeRegistryPath  = "$registryRoot\chrome.exe",                                              # direct registry location for Chrome (to check version)
        $webDriversPath      = "C:\temp\EasyWarrantyCheck\WebDrivers",                                  # local path for all web drivers (assuming that both are in the same location)
        $edgeDriverPath      = "$($webDriversPath)\msedgedriver.exe",                                   # direct MS Edge driver path
        $chromeDriverPath    = "$($webDriversPath)\chromedriver.exe",                                   # direct Chrome driver path
        $chromeDriverWebsite = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json",                           # Chrome dooesn't allow to query the version from downloads page; instead available pages can be found here
        $edgeDriverWebsite   = "https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/"  # URL to find and download relevant MS Edge Driver version
    )

    function Get-LocalDriverVersion{
        param(
            $pathToDriver                                               # direct path to the driver
        )
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo   # need to pass the switch & catch the output, hence ProcessStartInfo is used
    
        $processInfo.FileName               = $pathToDriver
        $processInfo.RedirectStandardOutput = $true                     # need to catch the output - the version
        $processInfo.Arguments              = "-v"
        $processInfo.UseShellExecute        = $false                    # hide execution
    
        $process = New-Object System.Diagnostics.Process
    
        $process.StartInfo  = $processInfo
        try {
            $process.Start()    | Out-Null
            $process.WaitForExit()                                      # run synchronously, we need to wait for result
            $processStOutput    = $process.StandardOutput.ReadToEnd()
        }catch{
            $version = "1.0.0.0"
        }                             
    
        if ($version -eq "1.0.0.0") {
            return $version
        }
        elseif ($pathToDriver.Contains("msedgedriver")) {
            return ($processStOutput -split " ")[3]                     # MS Edge returns version on 4th place in the output (be careful, in old versions it was on 1st as well)... 
        }
        else {
            return ($processStOutput -split " ")[1]                     # ... while Chrome on 2nd place
        }        
    }
    
    function Confirm-NeedForUpdate{
        param(
            $v1,                                                                                 # version 1 to compare
            $v2                                                                                  # version 2 to compare
        )
        return $v1.Substring(0, $v1.LastIndexOf(".")) -ne $v2.Substring(0, $v2.LastIndexOf(".")) # return true if update is needed, otherwise false. Ignore last minor version - it's not so important and can be skipped
    }
    # Create WebDrivers Location if not exist
    try {
        if (-not (Test-Path -Path $webDriversPath -PathType Container)) {
            # Directory doesn't exist, create it
            New-Item -Path $webDriversPath -ItemType Directory -Force | Out-Null
            Write-Debug "Directory created successfully."
        } else {
            Write-Debug "Directory already exists."
        }
    } catch {
        Write-Host "An error occurred: $_"
    }

    if($WebDriver -eq "Chrome"){
        # Check which browser versions are installed (from registry)
        try {
            $chromeVersion = (Get-Item (Get-ItemProperty $chromeRegistryPath).'(Default)').VersionInfo.ProductVersion
        } catch {

        }
        # check which driver versions are installed
        $chromeDriverVersion = Get-LocalDriverVersion -pathToDriver $chromeDriverPath
        if (Confirm-NeedForUpdate $chromeVersion $chromeDriverVersion){
        $jsonString = Invoke-RestMethod -Uri $chromeDriverWebsite
        # Find the URL for chromedriver for win64 platform in the stable channel
        $webdriverurl = $jsonString.channels.Stable.downloads.chromedriver | Where-Object { $_.platform -eq "win64" } | Select-Object -ExpandProperty url
        $chromeDriverAvailableVersions = $webdriverurl
        $versionLink = $chromeDriverAvailableVersions | where {$_ -like "*$chromeVersion/*"}
        if (!$versionLink){
            $browserMajorVersion = $chromeVersion.Substring(0, $chromeVersion.IndexOf("."))
            $versionLink         = $chromeDriverAvailableVersions | where {$_ -like "*$browserMajorVersion.*"}
        }
            # in case of multiple links, take the first only
        if ($versionLink.Count -gt 1){
            $versionLink = $versionLink[0]
        }
        $downloadLink = $versionLink
        try {
            Invoke-WebRequest $downloadLink -OutFile "$webDriversPath\chromeNewDriver.zip"
        }catch{
            Write-Debug $_.Exception.Message
        }
        # Expand archive and replace the old file
        Expand-Archive "$webDriversPath\chromeNewDriver.zip" -DestinationPath "$webDriversPath\tempchrome" -Force
        Move-Item      "$webDriversPath\tempchrome\chromedriver-win64\chromedriver.exe" -Destination "$($webDriversPath)\chromedriver.exe" -Force

        # clean-up
        Remove-Item "$webDriversPath\chromeNewDriver.zip" -Force | Out-Null
        Remove-Item "$webDriversPath\tempchrome" -Recurse -Force | Out-Null
    }
    } 
    if($WebDriver -eq "Edge"){
        # Check which browser versions are installed (from registry)
        try {
            $edgeVersion   = (Get-Item (Get-ItemProperty $edgeRegistryPath).'(Default)').VersionInfo.ProductVersion
        } catch {
            Write-Debug $_.Exception.Message
        }
        # check which driver versions are installed
        $edgeDriverVersion   = Get-LocalDriverVersion -pathToDriver $edgeDriverPath
        if($edgeDriverVersion -eq $null){
            # Set version to nothing
            $edgeDriverVersion = "1.0.0.0"
        }
        if (Confirm-NeedForUpdate $edgeVersion $edgeDriverVersion){
            # find exact matching version
            $edgeDriverAvailableVersions = (Invoke-RestMethod $edgeDriverWebsite) -split " " | where {$_ -like "*href=*win64*"} | % {$_.replace("href=","").replace('"','')}
            $downloadLink                = $edgeDriverAvailableVersions | where {$_ -like "*/$edgeVersion/*"}
        
            # if cannot find (e.g. it's too new to have a web driver), look for relevant major version
            if (!$downloadLink){
                $browserMajorVersion = $edgeVersion.Substring(0, $edgeVersion.IndexOf("."))
                $downloadLink        = $edgeDriverAvailableVersions | where {$_ -like "*/$browserMajorVersion*"}
            }
        
            # in case of multiple links, take the first only
            if ($downloadLink.Count -gt 1) {
                $downloadLink = $downloadLink[0]
            }
        
            # download the file
            try {
                Invoke-WebRequest $downloadLink -OutFile "$webDriversPath\edgeNewDriver.zip"
            } catch{
                Write-Debug $_.Exception.Message
            }
        
            # epand archive and replace the old file
            Expand-Archive "$webDriversPath\edgeNewDriver.zip" -DestinationPath "$webDriversPath\tempedge" -Force
            Move-Item      "$webDriversPath\tempedge\msedgedriver.exe" -Destination "$($webDriversPath)\msedgedriver.exe" -Force
        
            # clean-up
            Remove-Item "$webDriversPath\edgeNewDriver.zip" -Force | Out-Null
            Remove-Item "$webDriversPath\tempedge" -Recurse -Force | Out-Null
        }                           
    } 
    }

function Start-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Start Selenium Module
    
        .DESCRIPTION
        This function will Start Selenium Module
    
        .EXAMPLE
        Start-SeleniumModule -Driver "Chrome"
        Start-SeleniumModule -Driver "Edge"

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
        Get-RunAsUserModule
        Import-Module -Name RunAsUser
        $scriptblock = {
            Import-Module Selenium
            $WebDriverPath = "C:\temp\EasyWarrantyCheck\WebDrivers"
            $EdgeService = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService($WebDriverPath, 'msedgedriver.exe')
            $EdgeService.HideCommandPromptWindow = $true
            $EdgeService.UseVerboseLogging = $true
            $edgeOptions = [OpenQA.Selenium.Edge.EdgeOptions]::new()
            $edgeOptions = New-Object OpenQA.Selenium.Edge.EdgeOptions
            # Specify the debugging port
            $debugPort = "9222"
            $edgeOptions.AddAdditionalCapability("ms:edgeOptions", @{args = @(
                    "--inprivate"
                    "--no-sandbox"
                    "--headless"
                    "--remote-debugging-port=$debugPort"
                ) })
            $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver($EdgeService, $edgeOptions)
            Start-Sleep -Seconds 3
            return $driver
        }
        $invokeasuser = invoke-ascurrentuser -scriptblock $scriptblock -UseWindowsPowerShell -CaptureOutput
        Write-Debug "Driver Invoked : $invokeasuser"
        $process =  "msedgedriver.exe"
        $commandLine = Get-CimInstance Win32_Process -Filter "name = '$process'" | select CommandLine
        Write-Debug "msedgedriver.exe process : $commandLine"
        # Regular expression pattern to match port number
        $portPattern = '--port=(\d+)'
        if ($commandLine -match $portPattern) {
            $driverportnumber = $matches[1]
            Write-Debug "Driver Port Number : $driverportnumber"
        } else {
            Write-Output "Port number not found."
        }
        $debugPort = "9222"
        # Connect to Edge WebDriver under user context
        # Set the address of the remote WebDriver
        $remoteAddress = "http://127.0.0.1:$driverportnumber"
        $options = New-Object OpenQA.Selenium.Edge.EdgeOptions
        # Set the debugger address
        $debuggerAddress = "127.0.0.1:$debugPort"
        $options.AddAdditionalCapability("ms:edgeOptions", @{
            "debuggerAddress" = $debuggerAddress
        })
        # Connect to the existing Edge session
        
        return $driver = New-Object OpenQA.Selenium.Remote.RemoteWebDriver($remoteAddress, $options)
    } 
    if($WebDriver -eq "Chrome"){
        $ChromeService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($WebDriverPath, 'chromedriver.exe')
        $ChromeService.HideCommandPromptWindow = $true
        $chromeOptions = [OpenQA.Selenium.Chrome.ChromeOptions]::new()
        if($Headless -eq $true){
            $chromeOptions.AddArgument("headless")
        }
        $chromeOptions.AddArgument("--log-level=3")
        return $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeService, $chromeOptions)
    } 
    }

function Stop-SeleniumModule {
    <#
        .SYNOPSIS
        Function to Stop Selenium Module
    
        .DESCRIPTION
        This function will Stop Selenium Module
    
        .EXAMPLE
        Stop-SeleniumModule -WebDriver "Chrome"
        Stop-SeleniumModule -WebDriver "Edge"

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
                Write-Debug "Stopping : $processID"
                Stop-Process -Id $processID -Force -ErrorAction SilentlyContinue | Out-null
            } else {
            }
        }

        # Get the processes of msedgedriver
        $driverProcesses = Get-CimInstance Win32_Process -Filter "name = 'msedgedriver.exe'"

        # Terminate each driver process
        foreach ($process in $driverProcesses) {
            $processID = $process.ProcessId
            if ($processID -ne $null) {
                Write-Debug "Stopping : $processID"
                Stop-Process -Id $processID -Force -ErrorAction SilentlyContinue | Out-null
            } else {

            }
        }
        Remove-Module Selenium -Force -ErrorAction SilentlyContinue | Out-null 
    } 
    if($WebDriver -eq "Chrome"){
        $driver.quit()
        Remove-Module Selenium -Force -ErrorAction SilentlyContinue | Out-null
    }
}

function Test-SoftwareInstalled {
    <#
        .SYNOPSIS
        Function to check software exists
    
        .DESCRIPTION
        This function will check if software exists
    
        .EXAMPLE
        Test-SoftwareInstalled -SoftwareName "Google Chrome"
        Test-SoftwareInstalled -SoftwareName "Microsoft Edge"
    
    #>
    param(
        [string]$SoftwareName
    )

# Define the registry paths where the software information is stored for 32-bit and 64-bit
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Check if the software registry key exists in either 32-bit or 64-bit location
foreach ($path in $registryPaths) {
    $installed = Get-ItemProperty -Path $path | Where-Object { $_.DisplayName -eq $SoftwareName }
    if ($installed) {
        $version = $installed.DisplayVersion
        Write-Debug "$SoftwareName version $version is installed."
        $result = [PSCustomObject]@{
            Software = $SoftwareName 
            Installed = $true
            Version = $version
        }
        return $result
    }
}
# If the software was not found in any location
Write-Host "###########################"
Write-Host "WARNING"
Write-Host "$SoftwareName not detected"
Write-Host "This manufacturer currently requires $SoftwareName installed to check expiry"
Write-Host "###########################"
Write-Debug "$SoftwareName is not installed."
$result = [PSCustomObject]@{
    Software = $SoftwareName 
    Installed = $false
    Version = $null
}
return $result
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
            [Parameter(Mandatory = $false)]
            [String]$Warrantystart,
            [Parameter(Mandatory = $false)]
            [String]$WarrantyExpiry,
            [Parameter(Mandatory = $false)]
            [String]$WarrantyStatus,
            [Parameter(Mandatory = $false)]
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
                    if ($Warrantystart -match "\d{2}-\d{2}-\d{4}"){
                        #$Warrantystart = $Warrantystart.ToString("dd-MM-yyyy")
                    } else {
                        $Warrantystart = [DateTime]::ParseExact($Warrantystart, $dateformat, $null)
                        $Warrantystart = $Warrantystart.ToString("dd-MM-yyyy")
                    }
                    $Warrantystartutc = Get-Date $Warrantystart -Format "yyyy-MM-dd"
                }
                if($WarrantyExpiry){
                    if ($WarrantyExpiry -match "\d{2}-\d{2}-\d{4}"){
                        #$WarrantyExpiry = $WarrantyExpiry.ToString("dd-MM-yyyy")
                    } else {
                        $WarrantyExpiry = [DateTime]::ParseExact($WarrantyExpiry, $dateformat, $null)
                        $WarrantyExpiry = $WarrantyExpiry.ToString("dd-MM-yyyy")
                    }
                    $WarrantyExpiryutc = Get-Date $WarrantyExpiry -Format "yyyy-MM-dd"
                }
            if($Warrantystartutc){Ninja-Property-Set $ninjawarrantystart $Warrantystartutc}
            if($WarrantyExpiryutc){Ninja-Property-Set $ninjawarrantyexpiry $WarrantyExpiryutc}
            if($WarrantyStatus){Ninja-Property-Set $ninjawarrantystatus $WarrantyStatus}
            if($Invoicenumber){Ninja-Property-Set $ninjainvoicenumber $Invoicenumber}
            return "Warranty details saved to NinjaRMM"
        }
}

Get-Warranty
