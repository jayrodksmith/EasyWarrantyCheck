function Get-LoggedInUser {
    <#
        .SYNOPSIS
        Function to get current logged in user
    
        .DESCRIPTION
        This function will get current logged in user
    
        .EXAMPLE
        Get-LoggedInUser
    
    #>

    try {
        # Get the currently logged in users on the local computer
        $loggedUsers = quser 2>$null

        # Check if there are any logged in users
        if ($loggedUsers) { 

            # Split the output into an array of lines
            $userArray          = $loggedUsers -split '\r?\n' | Select-Object -Skip 1
            
            # Create an array to store user details
            $users = foreach ($userLine in $userArray) {
                $userDetails    = $userLine -split '\s{2,}'
                
                # Extracting specific details: username, sessionname, ID, state, idle time, logon time
                $username       = $userDetails[0].TrimStart('>')
                $sessionname    = $userDetails[1].Trim()
                $id             = $userDetails[2].Trim()
                $state          = $userDetails[3].Trim()
                $idleTime       = $userDetails[4].Trim()
                $logonTime      = $userDetails[5..6] -join ' '

                Write-Verbose "User Currently Logged In : $Username"
                # Create an object with user details
                [PSCustomObject]@{
                    Username        = $username
                    SessionName     = $sessionname
                    ID              = $id
                    State           = $state
                    IdleTime        = $idleTime
                    LogonTime       = $logonTime
                }
            }

            return $users
        } else {
            Write-Verbose "No logged in user"
            return $false
        }
    } catch {
        Write-Verbose "An error occurred while retrieving user information: $_"
        return $false
    }
}