CREATE TABLE dbo.MaintenanceMode(
	Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	IsOffline bit NOT NULL,
	Notes varchar(100) NULL,
	[Timestamp] Datetime2 NOT NULL
);

INSERT INTO dbo.MaintenanceMode(IsOffline, Notes, [Timestamp])
SELECT 0, 'Initial Entry', GetUtcDate()	;
