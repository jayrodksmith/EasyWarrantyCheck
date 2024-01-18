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
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
        [Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
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