
param (
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
    [parameter(Mandatory=$true)]
    [string]
    $RemoteBackupsDir,
    [parameter(Mandatory=$true)]
    [string]
    $LocalBackupsDir,
    [parameter(Mandatory=$true)]
    [string]
    $DbFileBasePath,
    [parameter(Mandatory=$true)]
    [string]
    $SourceDbBaseFileName
)

# Set variables
#$SQLDatabase = "CI_DeployPresentation" 
#$BackupsDir = "E:\Backups"
#$DbFileBasePath = 'E:\MSSQL10_50.MSSQLSERVER\MSSQL\DATA'
#$SourceDbBaseFileName = 'DeployPresentation'

$ErrorActionPreference = "Stop"

try{
    $Latest = Get-ChildItem -Path $RemoteBackupsDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $RestoreFile = $Latest.Name

    $FullPath = $LocalBackupsDir + "\" + $RestoreFile

    $BackupText = "ALTER DATABASE $Database             
	     SET SINGLE_USER WITH ROLLBACK IMMEDIATE;                  
      
	     RESTORE DATABASE $Database                        
	     FROM DISK = '$FullPath'                        
	     WITH REPLACE,
        MOVE '$SourceDbBaseFileName' TO '$DbFileBasePath\$Database.mdf',
        MOVE '$($SourceDbBaseFileName)_log' TO '$DbFileBasePath\$($Database)_log.ldf';
        
        ALTER DATABASE $Database SET MULTI_USER;"


    # Import SQL powershell
    # - sqlps has some 'unapproved' prefixes, so we disable name checking so we don't get wanrings every time
    # - we also push and pop the current file location because it changes us to a DB location when we import it
    Push-Location
    Import-Module sqlps -DisableNameChecking
    Pop-Location

    # Execute with console output to TeamCity
    Write-Host "##teamcity[blockOpened name='Executing Restore']"
    Write-Host "Executing:
        $BackupText"
    Invoke-SqlCmd -Query "$BackupText" -ServerInstance "$Server" -Username "$AdminUserName" -Password "$AdminPassword" -Database "master" -Verbose -ErrorAction Stop
    Write-Host "##teamcity[blockClosed name='Executing Restore']"

}
catch [System.Exception]{
    Write-Host "##teamcity[buildStatus status='FAILURE' text='Database Restore Failed with $($_.Exception.GetType().Name)']"
    Write-Error "$($_.Exception.ToString())"
}