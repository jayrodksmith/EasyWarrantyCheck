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
        [String]$WebDriver = "Chrome"
    )
    if($WebDriver -eq "Chrome"){
        Get-WebDriverChrome
    } 
    if($WebDriver -eq "Edge"){
        Get-WebDriverEdge
    } 
    }