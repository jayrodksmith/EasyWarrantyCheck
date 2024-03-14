function Test-BrowserSupport {
    <#
        .SYNOPSIS
        Function to check browser support
    
        .DESCRIPTION
        This function will check what browser we can use in the main script
    
        .EXAMPLE
        Test-BrowserSupport -Browser "Chrome"
        Test-BrowserSupport -Browser "Edge"

        .PARAMETER Browser
        What browser to check if we can run
    
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
		[Parameter(Mandatory = $false)]
		[String]$Browser= $Seleniumdrivermode
	)
    # Check if running in system context
    function Test-SystemContext {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $currentUserSid = $currentUser.User.Value
    
        # The SID for the SYSTEM account
        $systemSid = "S-1-5-18"
    
        if ($currentUserSid -eq $systemSid) {
            Write-Verbose "Running in SYSTEM context."
            return $true
        } else {
            Write-Verbose "Not running in SYSTEM context."
            return $false
        }
    }

    # Check if Edge and Chrome Installed
        $chrome = Test-SoftwareInstalled -SoftwareName "Google Chrome"
        $edge = Test-SoftwareInstalled -SoftwareName "Microsoft Edge"
        $loggedInUsers = Get-LoggedInUser
        $systemcontext = Test-SystemContext

        # Check if Edge can be used
        if($edge.installed -eq $true) {
            if (($loggedInUsers = Get-LoggedInUser) -eq $false) {
                Write-Verbose "No user logged in cannot run Edge without user logged in"
                $edgesupport = $false
            } else{
                if($systemcontext -eq $true) {
                    $edgesupport = $true
                } else {
                    Write-Verbose "Script not running system context cannot run Edge without system context"
                    $edgesupport = $false
                }
                
            }
        } else {
            $edgesupport = $false
        }

    if ($Browser -eq "Edge") {
        if($edgesupport -eq $true){
            return $true
        } else {
            if($systemcontext -eq $false) {Write-Host "Script not running system context cannot run Edge without system context"}
            if($edge.installed -eq $false) {Write-Host "Microsoft Edge not installed"}
            Write-Host "Microsoft Edge not supported, trying Chrome support"
            if($chrome.installed -eq $true) {
                Write-Host "Defaulting to Chrome support"
                Set-Variable Seleniumdrivermode -Value "Chrome" -Scope Global -Force
                return $true
            } else {
                Write-Host "Google Chrome not installed"
                return $false
            }
        }
    }

    if ($Browser -eq "Chrome"){
        if($chrome.installed -eq $true) {
            return $true
        } else {
            Write-Host "Google Chrome not installed trying Edge support"
            if($edgesupport -eq $true){
                Set-Variable Seleniumdrivermode -Value "Edge" -Scope Global -Force
                return $true
            } else {
                if (($loggedInUsers = Get-LoggedInUser) -eq $false) {
                    Write-Host "No user logged in cannot run Edge without user logged in"
                    return $false
            } else {
                Write-Host "Microsoft Edge not installed"
            }
        }
    }
}
}