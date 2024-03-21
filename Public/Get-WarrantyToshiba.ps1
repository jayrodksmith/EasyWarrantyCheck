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
            [String]$DateFormat = $DateFormatGlobal
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