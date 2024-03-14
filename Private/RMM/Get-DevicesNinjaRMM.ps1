function  Get-DevicesNinjaRMM {
    [CmdletBinding()]
    Param(
        [string]$NinjaURL = "https://oc.ninjarmm.com", # Adjust to correct url
        [String]$Secretkey = "test", # Add keys here
        [String]$AccessKey = "test", # Add keys here
        [boolean]$SyncWithSource,
        [boolean]$OverwriteWarranty,
        [string]$NinjaFieldName
    )
    $AuthBody = @{
        'grant_type'    = 'client_credentials'
        'client_id'     = $Secretkey
        'client_secret' = $AccessKey
        'scope'         = 'management monitoring' 
    }
    
    $Result = Invoke-WebRequest -uri "$($NinjaURL)/ws/oauth/token" -Method POST -Body $AuthBody -ContentType 'application/x-www-form-urlencoded'
    
    $AuthHeader = @{
        'Authorization' = "Bearer $(($Result.content | convertfrom-json).access_token)"
    }

    $OrgsRaw = Invoke-WebRequest -uri "$($NinjaURL)/v2/organizations" -Method GET -Headers $AuthHeader
    $NinjaOrgs = $OrgsRaw | ConvertFrom-Json
    
    $date1 = Get-Date -Date "01/01/1970"  

    If ($ResumeLast) {
        write-host "Found previous run results. Starting from last object." -foregroundColor green
        $Devices = get-content 'Devices.json' | convertfrom-json
    } else {
        $DevicesRaw = Invoke-WebRequest -uri "$($NinjaURL)/v2/devices-detailed" -Method GET -Headers $AuthHeader
        $Devices = ($DevicesRaw.content | ConvertFrom-Json) | Where-Object { $_.nodeClass -like "WINDOWS*" -and $_.system.model -notmatch "Virtual Machine"}

        $After = 0
        $PageSize = 1000
        $AllDevices = @()

        do {
            $Result = (Invoke-WebRequest -Uri "$($NinjaURL)/v2/devices-detailed?pageSize=$PageSize&after=$After" -Method Get -Headers $AuthHeader -ContentType 'application/json').Content | ConvertFrom-Json -Depth 100 | Where-Object { $_.nodeClass -like "WINDOWS*" -and $_.system.model -notmatch "Virtual Machine"}
        
            $AllDevices += $Result
        
            $ResultCount = $Result.Count
            $After = $Result[-1].id  # Set the value for the next iteration
        
        } while ($ResultCount -eq $PageSize)
        
        # Combine initial devices with paged devices
        $Devices += $AllDevices

    }
    $i = 0
    $warrantyObject = foreach ($device in $Devices) {
        $i++
        $progressPercentage = [math]::Round(($i / $Devices.Count * 100), 2)
        Write-Progress -Activity "Grabbing Warranty information" -status "Processing $($device.system.biosSerialNumber). Device $i of $($Devices.Count)" -percentComplete $progressPercentage
        $DeviceOrg = ($NinjaOrgs | Where-Object { $_.id -eq $Device.organizationId }).name
        try {
            if($device.system.manufacturer -eq "ASUSTeK COMPUTER INC."){$vendor = "ASUS"}
            $WarState = Get-Warrantyinfo -Serialnumber $device.system.biosSerialNumber -client $DeviceOrg -Vendor $vendor
        } catch {
            Write-Error "Failed to fetch warranty data for device: $($Device.systemName) $_"
        }
            $DeviceObject = [PSCustomObject]@{
            id = $device.id
            organizationId = $device.organizationId
            systemname = $device.systemname
            biosSerialNumber = $device.system.biosSerialNumber
            SerialNumber = $device.system.SerialNumber
            manufacturer = $device.system.manufacturer
            model = $device.system.model
        }
        # Convert the current device object to JSON and append it to the file
        $Null = $DeviceObject | ConvertTo-Json -Depth 5 | Add-Content 'Devices.json'
        # Sleep for a short duration to simulate processing time (optional)
        Start-Sleep -Milliseconds 100
        if ($progressPercentage -eq 100) {
            Write-Progress -Activity "Grabbing Warranty information" -status "Processing Complete" -percentComplete 100
            Start-Sleep -Milliseconds 500
            Write-Progress -Activity "Grabbing Warranty information" -Completed
        }

        if ($warstate.EndDate) {
            $Seconds = [int]([math]::Truncate((New-TimeSpan -Start $date1 -End $warstate.EndDate).TotalSeconds))
            $UpdateBody = @{
                "$NinjaFieldName" = $Seconds
            } | convertto-json
            
            if ($SyncWithSource -eq $true) {
                switch ($OverwriteWarranty) {
                    $true {
                        
                        try {
                           # $Result = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($Device.id)/custom-fields" -Method PATCH -Headers $AuthHeader -body $UpdateBody -contenttype 'application/json' -ea stop
                        } catch {
                            Write-Error "Failed to update device: $($Device.systemName) $_"
                        }
                    }
                    $false {
                       # $DeviceFields = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($Device.id)/custom-fields" -Method GET -Headers $AuthHeader
                       # $WarrantyDate = ($DeviceFields.content | convertfrom-json)."$($NinjaFieldName)"

                        if ($null -eq $WarrantyDate -and $null -ne $warstate.EndDate) { 
                            try {
                               # $Result = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($Device.id)/custom-fields" -Method PATCH -Headers $AuthHeader -body $UpdateBody -contenttype 'application/json' -ea stop
                            } catch {
                                Write-Error "Failed to update device: $($Device.systemName) $_"
                            }        
                        } 
                    }
                }
            }
        }
        $WarState
    }
    Remove-item 'devices.json' -Force -ErrorAction SilentlyContinue
    return $warrantyObject

}