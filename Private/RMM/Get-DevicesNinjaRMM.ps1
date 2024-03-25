function  Get-DevicesNinjaRMM {
    [CmdletBinding()]
    Param(
        [string]$NinjaURL = "https://oc.ninjarmm.com", # Adjust to correct url
        [String]$Secretkey = "test", # Add keys here
        [String]$AccessKey = "test", # Add keys here
        [boolean]$SyncWithSource,
        [boolean]$OverwriteWarranty,
        [string]$NinjaFieldName = 'warrantyExpiry',
        [string]$filterorg = "58"
    )
    $AuthBody = @{
        'grant_type'    = 'client_credentials'
        'client_id'     = $AccessKey
        'client_secret' = $Secretkey
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
        
        if($filterorg){
            $Devices = $Devices | Where-Object {$_.organizationId -eq $filterorg}
        }
        $Devices
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
            $Mfg = $($device.system.manufacturer)
            $Mfg = if ($Mfg) {
                switch ($Mfg) {
                    "IBM" { $Mfg = "LENOVO" }
                    "Hewlett-Packard" { $Mfg = "HP" }
                    {$_ -match "Asus"} { $Mfg = "ASUS" }
                    {$_ -match "Wortmann"} { $Mfg = "TERRA" }
                    {$_ -match "Terra"} { $Mfg = "TERRA" }
                    {$_ -match "Dell"} { $Mfg = "DELL" }
                    {$_ -match "HP"} { $Mfg = "HP" }
                    {$_ -match "Edsys"} { $Mfg = "EDSYS" }
                    {$_ -match "Lenovo"} { $Mfg = "LENOVO" }
                    {$_ -match "Microsoft"} { $Mfg = "MICROSOFT" }
                    {$_ -match "TOSHIBA"} { $Mfg = "TOSHIBA" }
                    {$_ -match "Intel Corporation"} { 
                        $pattern = "^B\d{6}$"
                        if ($SerialNumber -match $pattern){
                            $Mfg = "EDSYS"
                        }
                    }
                    default { $Mfg = $Mfg }
                }
                $Mfg
            } else {
                $Mfg 
            }
            $WarState = Get-Warranty -RMM 'NinjaRMMAPI' -Serial "$($device.system.biosSerialNumber)" -Manufacturer $Mfg -NinjaOrg $DeviceOrg
        } catch {
            Write-Error "Failed to fetch warranty data for device: $($Device.systemName) $_"
        }
            $DeviceObject = [PSCustomObject]@{
            id = $device.id
            organizationId = $device.organizationId
            organizationName = $DeviceOrg
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
                            $Result = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($Device.id)/custom-fields" -Method PATCH -Headers $AuthHeader -body $UpdateBody -contenttype 'application/json' -ea stop
                        } catch {
                            Write-Error "Failed to update device: $($Device.systemName) $_"
                        }
                    }
                    $false {
                        $DeviceFields = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($Device.id)/custom-fields" -Method GET -Headers $AuthHeader
                        $WarrantyDate = ($DeviceFields.content | convertfrom-json)."$($NinjaFieldName)"

                        if ($null -eq $WarrantyDate -and $null -ne $warstate.EndDate) { 
                            try {
                                $Result = Invoke-WebRequest -uri "$($NinjaURL)/v2/device/$($Device.id)/custom-fields" -Method PATCH -Headers $AuthHeader -body $UpdateBody -contenttype 'application/json' -ea stop
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