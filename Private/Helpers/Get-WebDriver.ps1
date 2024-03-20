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
        $chromeDriverWebsite = "https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build-with-downloads.json",
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
            Write-Verbose "Directory created successfully."
        } else {
            Write-Verbose "Directory already exists."
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
        $browserMajorVersion = $chromeVersion.Substring(0,10)
        $jsonString = $jsonString.builds
        $versionLink = $jsonString.$browserMajorVersion.downloads.chromedriver | Where-Object { $_.platform -eq "win64" } | Select-Object -ExpandProperty url
        $downloadLink = $versionLink
        try {
            Invoke-WebRequest $downloadLink -OutFile "$webDriversPath\chromeNewDriver.zip"
        }catch{
            Write-Verbose $_.Exception.Message
        }
        # Expand archive and replace the old file
        Expand-Archive "$webDriversPath\chromeNewDriver.zip" -DestinationPath "$webDriversPath\tempchrome" -Force
        Remove-Item "$($webDriversPath)\chromedriver.exe" -Force | Out-Null
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
            Write-Verbose $_.Exception.Message
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
                Write-Verbose $_.Exception.Message
            }
        
            # epand archive and replace the old file
            Expand-Archive "$webDriversPath\edgeNewDriver.zip" -DestinationPath "$webDriversPath\tempedge" -Force
            Remove-Item "$($webDriversPath)\msedgedriver.exe" -Force | Out-Null
            Move-Item      "$webDriversPath\tempedge\msedgedriver.exe" -Destination "$($webDriversPath)\msedgedriver.exe" -Force
        
            # clean-up
            Remove-Item "$webDriversPath\edgeNewDriver.zip" -Force | Out-Null
            Remove-Item "$webDriversPath\tempedge" -Recurse -Force | Out-Null
        }                           
    } 
    }