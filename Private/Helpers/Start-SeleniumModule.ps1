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
        $EdgeService = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService($WebDriverPath, 'msedgedriver.exe')
        $EdgeService.HideCommandPromptWindow = $true
        $EdgeService.UseVerboseLogging = $true
        $edgeOptions = [OpenQA.Selenium.Edge.EdgeOptions]::new()
        $edgeOptions = New-Object OpenQA.Selenium.Edge.EdgeOptions
        if($Headless -eq $true){
            $edgeOptions.AddAdditionalCapability("ms:edgeOptions", @{args = @(
                "--inprivate"
                "--user-data-dir=C:\\temp\\chrome-dev-profile"
                "--no-sandbox"
                "--headless"
                ) })
        }
        return $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver($EdgeService, $edgeOptions)
        
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