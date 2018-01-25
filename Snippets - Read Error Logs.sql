/*
CREATE TABLE #ErrLog (
	ErrLogId INT IDENTITY PRIMARY KEY NONCLUSTERED,
	LogDate DATETIME,
	ProcessInfo VARCHAR(256),
	[Text] VARCHAR(MAX)
)

INSERT INTO #ErrLog
EXEC sp_readerrorlog 0, 1
*/

EXEC [ATLONSCASSAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'failed'

SELECT 'EXEC [' +name + ']...sp_readerrorlog 0, 1, ''Closed event notification conversation endpoint with handle'''
FROM sys.servers
WHERE product = 'SQL Server'
AND name <> @@SERVERNAME 
ORDER BY name


EXEC [ATLACOSQL101.ASPGOV.PRI\ACOM]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCOGBTLG101.ASPCUST.PRI\COGNOS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCOGBYB2101.ASPCUST.PRI\COGNOS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCOGDB101.ASPGOV.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCOGGRVL101.ASPCUST.PRI\COGNOS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCOGHNTG101.ASPCUST.PRI\COGNOS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSADMSQL.ASPGOV.PRI\ADMSQL]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSETASQL.ASPGOV.PRI\ATLCSETASQL]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSHALCYONEXT.ASPGOV.PRI\HALCYON]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSSQL]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSSQL101.ASPGOV.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSSWAPP101.ASPGOV.PRI\ORION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLCSWS109.ASPGOV.PRI\HALCYON]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLDB101.ASPGOV.PRI\CS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLEPRELGRDB101.ASPGOV.PRI\ELGR_EPR]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLEPRKAUADB101.ASPGOV.PRI\EPR]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLEPRSQL1.ASPGOV.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLJMSDB201.ASPGOV.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSATLBAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSATLBDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSCASSAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSCASSDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSCPADB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSELGRAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSELGRDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSELGRDB301.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSFLDAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSFLDDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSHCPBAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSHCPBDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSKOKODB101.ASPCUST.PRI\COGNOS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSKOKODB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSKOKODB201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSLAPOAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSLAPODB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSLONGAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSMERIDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSNHANAP201.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSNHANDB101.ASPCUST.PRI\COGNOS]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLONSNHANDB101.ASPCUST.PRI\ONESOLUTION]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLOSLONGDB1.ASPCUST.PRI\LONGSPS2008]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLOSLONGDB1.ASPCUST.PRI\LONGWINS2008]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLOSLONGREP1.ASPCUST.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLSAASSQL.ASPGOV.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
EXEC [ATLVC101.ASPGOV.PRI]...sp_readerrorlog 0, 1, 'Closed event notification conversation endpoint with handle'
-------------------------------------------------------------
CREATE TABLE #ErrLog(
    LogDate DATETIME NULL,
    ProcessInfo VARCHAR(10) NULL,
    Text VARCHAR(MAX) NULL
)
GO

INSERT INTO #ErrLog
EXEC sp_readerrorlog 0, 1