
param (
    [parameter(Mandatory=$true)]
    [string]
    $UpdatesFolder,
    [parameter(Mandatory=$true)]
    [string]
    $UpdatesFile
)

$ErrorActionPreference = "Stop"

try{
    $path = (Get-Location).Path

    #database updates
    $outputPath = "$path\$UpdatesFile"
    $stream = [System.IO.StreamWriter] "$outputPath"
    $fileUpdates = Get-ChildItem "$UpdatesFolder"
    $datestamp = $(get-date -f "yyyy-MM-dd HH:mm")

    $stream.WriteLine("/* SQL Core Updates - Updated $datestamp */")
    $stream.WriteLine("BEGIN TRY")
    $stream.WriteLine("BEGIN TRANSACTION")

    foreach($file in $fileUpdates) 
    { 
        $name = ($file.Name)
        $namewe = ([System.IO.Path]::GetFileNameWithoutExtension($name))

        $stream.WriteLine("")
        $stream.WriteLine("/* File: $name */")
        $stream.WriteLine("IF NOT EXISTS (SELECT 1 FROM UpdateTracking WHERE Name = '$namewe')")
        $stream.WriteLine("BEGIN")

        $stream.WriteLine("`tPrint 'Applying Update: $namewe'")
        $stream.WriteLine("`tEXEC('")
        (Get-Content "$UpdatesFolder\$name") | % {$_ -replace "'", "''"} | % {$stream.WriteLine("`t`t$_")}
        $stream.WriteLine("`t');")

        $stream.WriteLine("`tINSERT INTO UpdateTracking(Name, Applied) SELECT '$namewe', GETUTCDATE();")
        $stream.WriteLine("END")
    }  

    $stream.WriteLine("COMMIT TRANSACTION")
    $stream.WriteLine("END TRY BEGIN CATCH")
    $stream.WriteLine("ROLLBACK TRANSACTION")
    $stream.WriteLine("
    -- copied from http://technet.microsoft.com/en-us/library/ms179296%28v=sql.105%29.aspx
    DECLARE 
        @ErrorMessage    NVARCHAR(4000),
        @ErrorNumber     INT,
        @ErrorSeverity   INT,
        @ErrorState      INT,
        @ErrorLine       INT,
        @ErrorProcedure  NVARCHAR(200);

    -- Assign variables to error-handling functions that 
    -- capture information for RAISERROR.
    SELECT 
        @ErrorNumber = ERROR_NUMBER(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorLine = ERROR_LINE(),
        @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');

    -- Build the message string that will contain original
    -- error information.
    SELECT @ErrorMessage = 
        N'Error %d, Level %d, State %d, Procedure %s, Line %d, ' + 
            'Message: '+ ERROR_MESSAGE();

    -- Print error information. 
    PRINT 'Error ' + CONVERT(varchar(50), ERROR_NUMBER()) +
          ', Severity ' + CONVERT(varchar(5), ERROR_SEVERITY()) +
          ', State ' + CONVERT(varchar(5), ERROR_STATE()) + 
          ', Procedure ' + ISNULL(ERROR_PROCEDURE(), '-') + 
          ', Line ' + CONVERT(varchar(5), ERROR_LINE());
    PRINT 'Error Message: ' + ERROR_MESSAGE();

    -- Raise an error: msg_str parameter of RAISERROR will contain
    -- the original error information.
    RAISERROR 
        (
        @ErrorMessage, 
        @ErrorSeverity, 
        1,               
        @ErrorNumber,    -- parameter: original error number.
        @ErrorSeverity,  -- parameter: original error severity.
        @ErrorState,     -- parameter: original error state.
        @ErrorProcedure, -- parameter: original error procedure name.
        @ErrorLine       -- parameter: original error line number.
        );")
    $stream.WriteLine("")
    $stream.WriteLine("END CATCH")
    $stream.Close()
    Write-Host "Update Script Created: $outputPath"
}
catch [System.Exception]{
    Write-Host "##teamcity[buildStatus status='FAILURE' text='CreateDatabaseUpdates Failed with $($_.Exception.GetType().Name)']"
    Write-Error "$($_.Exception.ToString())"
}

