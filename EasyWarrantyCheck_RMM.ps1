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

    .PARAMETER Manufacture
    Manually set Manufacture

#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
		[Parameter(Mandatory = $false)]
		[String]$Serial= 'Automatic',
        [Parameter(Mandatory = $false)]
        [ValidateSet('Automatic', 'Dell', 'HP', 'Edsys', 'Asus', 'Lenovo')]
		[String]$Manufacture= 'Automatic'
	)
    $SerialNumber = if ($Serial -eq 'Automatic') {
        (Get-CimInstance win32_bios).SerialNumber
    } else {
        $Serial
    }

    $Mfg = if ($Manufacture -eq 'Automatic') {
        $mfg = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        switch ($Mfg) {
            "IBM" { $Mfg = "LENOVO" }
            "Hewlett-Packard" { $Mfg = "HP" }
            {$_ -match "Asus"} { $Mfg = "ASUS" }
            {$_ -match "Dell"} { $Mfg = "DELL" }
            {$_ -match "HP"} { $Mfg = "HP" }
            {$_ -match "Edsys"} { $Mfg = "EDSYS" }
            {$_ -match "Lenovo"} { $Mfg = "LENOVO" }
            default { $Mfg = $Mfg }
        }
        $Mfg
    } else {
        $Manufacture
    }
    $MachineInfo = [PSCustomObject]@{
        SerialNumber = $SerialNumber
        Manufacturer = $Mfg
    }
    return $MachineInfo
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
    Set-ExecutionPolicy Bypass -scope Process -Force
    Import-Module PowerShellGet
    $seleniumModule = Get-Module -Name Selenium -ListAvailable
    if (-not $seleniumModule) {
        Install-Module Selenium -Force
    }
    Import-Module Selenium -Force
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
        if(Get-WarrantyNinjaRMM -eq $true -and ($ForceUpdate -eq $false)){
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
        Write-WarrantyRegistry-Warrantystart 'value' -WarrantyExpiry 'value' -WarrantyStatus 'value' -Invoicenumber 'value'
    
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
