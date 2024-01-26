function Convert-EpochToDateTime {
    <#
        .SYNOPSIS
        Function to convert Epoch time
    
        .DESCRIPTION
        This function will get convert Epoch time to UTC time

        .EXAMPLE
        Convert-EpochToDateTime -EpochTimestamp "Epochtime"
    
    #>
    param(
        [long]$EpochTimestamp,
        [Parameter(Mandatory = $false)]
        [String]$DateFormat = 'dd-MM-yyyy'
    )

    # Convert to DateTime
    $dateTime = (Get-Date "1970-01-01 00:00:00").AddMilliseconds($EpochTimestamp)

    # Return the readable date
    return $dateTime.ToString($DateFormat)
}