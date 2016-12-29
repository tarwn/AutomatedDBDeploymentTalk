
param (
    [parameter(Mandatory=$true)]
    [string]
    $UpdatesFile,
    [parameter(Mandatory=$true)]
    [string]
    $Server,
    [parameter(Mandatory=$true)]
    [string]
    $Database,
    [string]
    $AdminUserName,
    [string]
    $AdminPassword,
    [switch]
    $Trusted
)

$ErrorActionPreference = "Stop"

try{
    # Import SQL powershell
    # - sqlps has some 'unapproved' prefixes, so we disable name checking so we don't get wanrings every time
    # - we also push and pop the current file location because it changes us to a DB location when we import it
    Push-Location
    Import-Module sqlps -DisableNameChecking
    Pop-Location
        
    #updates tracking
    Write-Host "Creating Update Tracking Table If Not Exists"
    if($Trusted.IsPresent){
        Invoke-Sqlcmd -Query "IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UpdateTracking') CREATE TABLE UpdateTracking (UpdateTrackingKey int IDENTITY(1,1) PRIMARY KEY, Name varchar(255) NOT NULL, Applied DateTime NOT NULL);" -ServerInstance "$Server" -Database "$Database" -ErrorAction Stop
    }
    else{
        Invoke-Sqlcmd -Query "IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UpdateTracking') CREATE TABLE UpdateTracking (UpdateTrackingKey int IDENTITY(1,1) PRIMARY KEY, Name varchar(255) NOT NULL, Applied DateTime NOT NULL);" -ServerInstance "$Server" -Username "$AdminUserName" -Password "$AdminPassword" -Database "$Database" -ErrorAction Stop
    }
    Write-Host "Done"

    #Apply updates
    Write-Host "Running updates..."

    if($Trusted.IsPresent){
        Invoke-SqlCmd -InputFile "$UpdatesFile" -ServerInstance "$Server" -Database "$Database" -Verbose -ErrorAction Stop
    }
    else{
        Invoke-SqlCmd -InputFile "$UpdatesFile" -ServerInstance "$Server" -Username "$AdminUserName" -Password "$AdminPassword" -Database "$Database" -Verbose -ErrorAction Stop
    }

    Write-Host "Applied updates successfully."
}
catch [System.Exception]{
    Write-Host "##teamcity[buildStatus status='FAILURE' text='ApplyDatabaseUpdates Failed with $($_.Exception.GetType().Name)']"
    Write-Error "$($_.Exception.ToString())"
}

