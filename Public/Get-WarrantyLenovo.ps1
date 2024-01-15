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
        Write-Output "Checking Lenovo website for serial : $Serial"
        Write-Output "Waiting for results......."
        $APIURL = "https://pcsupport.lenovo.com/us/en/api/v4/mse/getproducts?productId=$Serial"
        $WarReq = Invoke-RestMethod -Uri $APIURL -Method get
        if($WarReq.id){
            $APIURL = "https://pcsupport.lenovo.com/us/en/products/$($WarReq.id)/warranty"
            $WarReq = Invoke-RestMethod -Uri $APIURL -Method get
            $search = $WarReq |Select-String -Pattern "var ds_warranties = window.ds_warranties \|\| (.*);[\r\n]*"
            $jsonWarranties = $search.matches.groups[1].value |ConvertFrom-Json
            }

        if ($jsonWarranties.BaseWarranties) {
            $warfirst = $jsonWarranties.BaseWarranties |sort-object -property [DateTime]End |select-object -first 1
            $warlatest = $jsonWarranties.BaseWarranties |sort-object -property [DateTime]End |select-object -last 1
            $warfirst.Start = [DateTime]($warfirst.Start)
            $warlatest.End = [DateTime]($warlatest.End)
            $WarObj = [PSCustomObject]@{
                'Serial' = $jsonWarranties.Serial
                'Warranty Product name' = $jsonWarranties.ProductName
                'StartDate' = $warfirst.Start.ToString($dateformat)
                'EndDate' = $warlatest.End.ToString($dateformat)
                'Warranty Status' = $warlatest.StatusV2
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