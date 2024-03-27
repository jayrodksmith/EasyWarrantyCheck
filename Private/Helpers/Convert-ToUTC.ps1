function Convert-ToUTC {
    <#
        .SYNOPSIS
        Function to convert to UTC
    
        .DESCRIPTION
        This function will convert to UTC

        .EXAMPLE
        Convert-ToUTC -Date "01/12/2020"
    
    #>
    param(
        [Parameter(Mandatory = $false)]
        [String]$Date
    )
    try {
        Get-Date $Date -Format "yyyy-MM-dd"
    }catch{
        Write-Error "Failed to convert date to UTC"
        Write-Error "$_"
    }
}