function Get-WarrantyMicrosoft {
    <#
        .SYNOPSIS
        Function to get Microsoft Warranty
    
        .DESCRIPTION
        This function will get Microsoft Warranty
    
        .EXAMPLE
        Get-WarrantyMicrosoft -Serial "0123456789"
    
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
            [String]$DateFormat = $DateFormatGlobal,
            [Parameter(Mandatory = $false)]
            [String]$NinjaOrg
        )
        # Define the URL
        Write-Host "Checking Microsoft website for serial : $Serial"
        Write-Host "Waiting for results......."
        $url = "https://surface.managementservices.microsoft.com/api/warranty"
        $referer = "https://surface.managementservices.microsoft.com"

        # Define the payload as a query string
        $payload = @{
            CurrentLanguage = "en-US"
            SelectedCountry = "AUS"
            InputSerialNumber = "023959701357"
            'ValidateCaptchaRequest.CaptchaRequestInput.InputSolution' = 'G5pYd4'
            'ValidateCaptchaRequest.CaptchaRequestInput.ChallengeId'= 'adbe704a-71b6-4ad1-abd3-61bed015185c'
            'ValidateCaptchaRequest.ChallengeType'= 'visual'
            'ValidateCaptchaRequest.CaptchaRequestHeader.ClientRequestId'= '41985dcf-404d-404a-8031-dcae02a9601a'
            'ValidateCaptchaRequest.CaptchaRequestHeader.CorrelationId'= '47cdd5b2-5d21-4b30-8ef0-7ddad5288875'
            'ValidateCaptchaRequest.CaptchaRequestHeader.MSRequestId'= 'f9de331c-62a7-44a7-8f06-fff02cd3cd36'
            '__RequestVerificationToken' = 'CfDJ8Bs2gZRbq61Fh3kwFwaLFZMbObGv4Z0-1hId2kVulzA7ZcraSW-tfVNiIFq0lQUL6PQOXZV6C7ttYVYoWqDsyfgW1-O-SkLxysDK7-2BzuejSIK7YEdbANVS4qbXYKcQZ90xdZwxqqiMDUwjyxHuzlA'
        }
        
        $headers = @{
            Referer = $referer
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }

        $response = Invoke-WebRequest -Uri $url -Method Post -Body $payload -ContentType "application/json" -UseBasicParsing -Headers $headers

        if ($($table.'Warranty Status')) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = $null
                'Manufacturer'          = 'Microsoft'
                'Client' = $NinjaOrg
                'Product Image' = $null
                'Warranty URL' = $null
            }
        } else {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $null
                'Warranty Product name' = $null
                'StartDate' = $null
                'EndDate' = $null
                'Warranty Status' = 'Could not get warranty information'
                'Manufacturer'          = 'Microsoft'
                'Client' = $NinjaOrg
                'Product Image' = ""
                'Warranty URL' = ""
            }
        }
    return $WarObj
}