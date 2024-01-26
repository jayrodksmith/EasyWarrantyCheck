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
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
        [Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
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
                $warrantystatus = "In Warranty"
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