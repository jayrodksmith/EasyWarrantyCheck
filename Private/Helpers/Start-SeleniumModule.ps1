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
        Import-Module -Name RunAsUser -Verbose:$false
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
        Write-Verbose "Driver Invoked : $invokeasuser"
        $process =  "msedgedriver.exe"
        $commandLine = Get-CimInstance Win32_Process -Filter "name = '$process'" | select CommandLine
        Write-Verbose "msedgedriver.exe process : $commandLine"
        # Regular expression pattern to match port number
        $portPattern = '--port=(\d+)'
        if ($commandLine -match $portPattern) {
            $driverportnumber = $matches[1]
            Write-Verbose "Driver Port Number : $driverportnumber"
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