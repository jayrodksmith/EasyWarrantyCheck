function Get-WarrantyEdsys {
    <#
        .SYNOPSIS
        Function to get Edsys Warranty
    
        .DESCRIPTION
        This function will get Edsys Warranty
    
        .EXAMPLE
        Get-WarrantyEdsys -Serial "B123456"
    
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
        Write-Host "Checking Edsys website for serial : $Serial"
        Write-Host "Waiting for results......."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
        [Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
        $url = "https://edsys.com.au/check-warranty-status/"

        # Define the payload as a query string
        $payload = @{
            serial_number = "$Serial"
            submit = "Search"
        }

        # Make the POST request
        $response = Invoke-WebRequest -Uri $url -Method Post -Body $payload -ContentType "application/x-www-form-urlencoded" -UseBasicParsing

        # Output the response
        $responseContent = $response.Content

        # Load the HTML content using a HTML parser
        $HTMLDocument = New-Object -ComObject "HTMLFile"
        try {
            # This works in PowerShell with Office installed
            $HTMLDocument.IHTMLDocument2_write($responseContent)
        } catch {
            # This works when Office is not installed    
            $src = [System.Text.Encoding]::Unicode.GetBytes($responseContent)
            $HTMLDocument.write($src)
        }

        # Find the table within the specific div
        $table = $HTMLDocument.getElementById("warranty_check_result").getElementsByTagName("table") | Select-Object -First 1

        # Convert the table HTML to PowerShell objects
        $objects = New-Object System.Collections.ArrayList
        $headers = @($table.getElementsByTagName("th") | ForEach-Object { $_.innerText.Trim() })

        $tableRows = $table.getElementsByTagName("tr") | Select-Object -Skip 1
        foreach ($row in $tableRows) {
            if ($row -ne $null) {
                $rowData = @($row.getElementsByTagName("td") | ForEach-Object { 
                    if ($_ -ne $null -and $_.innerText -ne $null) {
                        $_.innerText.Trim()
                    } else {
                        ""
                    }
                })
                $obj = [ordered]@{}
                for ($j = 0; $j -lt $headers.Count; $j++) {
                    $obj[$headers[$j]] = $rowData[$j]
                }
                $objects.Add((New-Object -TypeName PSObject -Property $obj)) | Out-Null
            }
            else {
                Write-Host "Warning: Null row encountered."
            }
        }

        # Output the PowerShell objects table
        $table = $objects
        if ($($table.'Title') -eq 'No Results found') {
            Write-Host "No Results found on Edsys Website"
        } else {
            # Check if the "Within Warranty" text exists
            if ($($table.'Warranty Status') -eq "In Warranty" -or $($table.'Warranty Status') -eq 'Under Warranty(Active)') {
                # "Within Warranty" text found
                $warrantystatus = "Within Warranty"
                # Additional actions if needed
            } else {
                # Write-Host "Expired"
                $warrantystatus = "Expired"
            }
            # Date Convert
            $dateString = $($table.'Build Date')
                if ($dateString -match '^\d{4}-\d{2}-\d{2}$') {
                $inputFormat = "yyyy-MM-dd"
                } elseif ($dateString -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') {
                    $inputFormat = "yyyy-MM-dd HH:mm:ss"
                } elseif ($dateString -match '^\d{4}-\d{2}-\d$') {
                    $dateString = $dateString -replace '(\d{4}-\d{2})-(\d)$', '${1}-0${2}' # Add leading zero
                    $inputFormat = "yyyy-MM-dd"
                } else {
                    Write-Host "Date format not recognized"
                }
                $date = [DateTime]::ParseExact($dateString, $inputFormat, [System.Globalization.CultureInfo]::InvariantCulture)
                $warfirst = $date.ToString($dateformat)
            # Add warranty type to Converted Date
            $warrantyYears = $($table.'Warranty Type') -replace 'Years', '' -replace '\s', ''
            $warrantyYears = $warrantyYears -replace 'RTD', ''
            $warrantyYears = $warrantyYears -replace 'ONE', ''
            $date = [DateTime]::ParseExact($dateString, $inputFormat, [System.Globalization.CultureInfo]::InvariantCulture)
            $warEndDate = $date.AddYears($warrantyYears)
            $warEndDate = $warEndDate.ToString($dateformat)
        }
        
        if ($($table.'Warranty Status')) {
            $WarObj = [PSCustomObject]@{
                'Serial' = $Serial
                'Invoice' = $($table.'Invoice')
                'Warranty Product name' = $($table.'Product Name')
                'StartDate' = $warfirst
                'EndDate' = $warEndDate
                'Warranty Status' = $warrantystatus
                'Client' = $null
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
                'Client' = $Client
                'Product Image' = ""
                'Warranty URL' = ""
            }
        }
    return $WarObj
}