
param (
    [parameter(Mandatory=$true)]
    [string]
    $Notes,
    [parameter(Mandatory=$true)]
    [string]
    $Server,
    [parameter(Mandatory=$true)]
    [string]
    $Database,
    [parameter(Mandatory=$true)]
    [string]
    $AdminUserName,
    [parameter(Mandatory=$true)]
    [string]
    $AdminPassword,
    [switch]
    $SetOffline
)

$ErrorActionPreference = "Stop"

try{
    # Import SQL powershell
    # - sqlps has some 'unapproved' prefixes, so we disable name checking so we don't get wanrings every time
    # - we also push and pop the current file location because it changes us to a DB location when we import it
    Push-Location
    Import-Module sqlps -DisableNameChecking
    Pop-Location
        
    $IsOfflineBit = 0
    if($SetOffline.IsPresent){
        $IsOfflineBit = 1
    }

    $CleanNotes = $Notes -Replace "'","''"

    #add maintenance record
    Invoke-Sqlcmd -Query "INSERT INTO dbo.MaintenanceMode(IsOffline, Notes, [Timestamp]) SELECT $IsOfflineBit, '$CleanNotes', GetUtcDate();" -ServerInstance "$Server" -Username "$AdminUserName" -Password "$AdminPassword" -Database "$Database" -ErrorAction Stop
}
catch [System.Exception]{
    Write-Host "##teamcity[buildStatus status='FAILURE' text='SetMaintenanceMode Failed with $($_.Exception.GetType().Name)']"
    Write-Error "$($_.Exception.ToString())"
}

