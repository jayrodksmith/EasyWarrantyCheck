function Get-AgeOfDevice {
    <#
        .SYNOPSIS
        Function to Get estimated age of the device
    
        .DESCRIPTION
        This function will Get estimated age of the device

        .EXAMPLE
        Get-AgeOfDevice -StartDate ""

        .PARAMETER StartDate
        StartDate, must be unix format
    
    #>
    param(
        [Parameter(Mandatory = $false)]
        $StartDate
    )

# Assuming $startDate contains the UNIX timestamp as previously mentioned
if($startdate -eq $null){
    $startdate = (Ninja-Property-Get $ninjawarrantystart)
}
$startDateUnixTimestamp = $StartDate
    if ($startDateUnixTimestamp) {
        # Convert the UNIX timestamp to a DateTime object
        # PowerShell treats UNIX timestamp in seconds, and it needs to be converted to DateTime from the epoch (1970-01-01)
        $startDate = [DateTimeOffset]::FromUnixTimeSeconds($startDateUnixTimestamp).DateTime

        # Getting today's date
        $endDate = Get-Date

        # Calculating the difference between the two dates
        $timeSpan = $endDate - $startDate

        # Calculating the total number of years as a decimal
        $yearsDecimal = $timeSpan.TotalDays / 365.25 # Including leap years in the calculation

        # Rounding to two decimal places for a more precise years figure
        $yearsRounded = [math]::Round($yearsDecimal, 2)

        # Optionally, you might want to output the years figure to the console for verification
        Write-Verbose "Device Age: $yearsRounded years"
        return $yearsRounded
    } else {
        return $false
    }
}