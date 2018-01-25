--Recently failed Jobs
DECLARE @DateAsInt INT 
SET @DateAsInt = CONVERT(VARCHAR, CURRENT_TIMESTAMP - 3, 112)
SELECT j.name, h.message, h.run_date, h.run_time, h.run_duration, h.server
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h
	ON j.job_id = h.job_id 
WHERE h.step_id = 0
AND h.run_date >= @DateAsInt
AND h.run_status <> 1
AND j.name LIKE 'DBA%'
--AND j.name LIKE 'collection[_]set[_]%'
GO

--Databases that haven't had a full backup in over a week.
SELECT d.state_desc, b.*
FROM DbaData.dba.LastBackups b
LEFT JOIN master.sys.databases d
	ON d.name = b.DbName
WHERE b.DateCompletedFull < CURRENT_TIMESTAMP - 7
AND d.state_desc IN ('ONLINE');
GO

--Databases with broken log chain.
SELECT d.name, s.last_log_backup_lsn, d.recovery_model_desc
FROM master.sys.database_recovery_status s
JOIN master.sys.databases d
	ON d.database_id = s.database_id
WHERE d.recovery_model_desc <> 'SIMPLE'
AND s.last_log_backup_lsn IS NULL
AND d.state_desc = 'ONLINE'
AND d.name NOT IN ('model')
GO

--SQL Agent "DBA" jobs that are disabled
SELECT j.name, j.description, j.enabled
FROM msdb.dbo.sysjobs j
WHERE j.name LIKE 'DBA-%'
AND j.enabled = 0
GO

--SQL Server Agents that are not running.
SELECT @@ServerName
WHERE NOT EXISTS (
	SELECT *
	FROM master.sys.sysprocesses 
	WHERE program_name = 'SQLAgent - Generic Refresher'
)
AND CAST(SERVERPROPERTY('Edition') AS VARCHAR(MAX)) NOT LIKE '%Express%'
GO

--Alerts history
SELECT a.name, a.event_source, a.severity, a.occurrence_count, 
	a.last_occurrence_date, a.last_occurrence_time, a.notification_message, a.has_notification
FROM msdb..sysalerts a
WHERE occurrence_count > 0
GO

--Unsent mail.
SELECT m.recipients, m.subject, m.body, m.send_request_date, m.send_request_user, m.sent_status
FROM msdb.dbo.sysmail_allitems m
WHERE m.send_request_date > CURRENT_TIMESTAMP - 3
AND m.sent_status <> 'sent'
ORDER BY m.send_request_date DESC
GO

--Databases that are not BROKER ENABLED
SELECT d.name, d.is_broker_enabled
FROM master.sys.databases d
WHERE d.is_broker_enabled = 0
AND d.name IN ('msdb', 'DbaData')
GO

--Service Broker Queues that are not enabled on [DbaData].
SELECT q.*, 'ALTER QUEUE [' + s.name + '].[' + q.name + '] WITH STATUS = ON;'
FROM DbaData.sys.service_queues q
JOIN DbaData.sys.schemas s
	ON s.schema_id = q.schema_id
WHERE q.is_ms_shipped = 0
AND (q.is_receive_enabled = 0 OR q.is_enqueue_enabled = 0);
GO

--Information on corrupt pages.  https://msdn.microsoft.com/en-us/library/ms174425.aspx
SELECT *
FROM msdb.dbo.suspect_pages
GO

--Databases below the highest compatibility level supported by the instance.
/*
	References:
		Version List: http://sqlserverbuilds.blogspot.com/
		Compatibility Levels: https://msdn.microsoft.com/en-us/library/bb510680.aspx
		SERVERPROPERTY: https://msdn.microsoft.com/en-us/library/ms174396.aspx
*/
SELECT name, owner_sid, compatibility_level,
	PARSENAME( CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) * 10 AS MajVer,
	'ALTER DATABASE [' + d.name + '] SET COMPATIBILITY_LEVEL = ' +
		CAST(PARSENAME( CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) * 10 AS VARCHAR) + ';'
FROM master.sys.databases d
WHERE compatibility_level <> PARSENAME( CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) * 10
GO

--Databases with invalid setting for auto shrink, auto create stats, auto update stats.
SELECT name, owner_sid, compatibility_level, is_auto_shrink_on, recovery_model_desc, is_auto_create_stats_on, is_auto_update_stats_on, is_auto_update_stats_async_on
FROM master.sys.databases 
WHERE state <> 6	--OFFLINE
AND (is_auto_shrink_on = 1
OR is_auto_create_stats_on <> 1
OR is_auto_update_stats_on <> 1)
ORDER BY name
GO

--Databases with invalid recovery model or invalid page verify option.
SELECT name, owner_sid, compatibility_level, is_auto_shrink_on, recovery_model_desc, page_verify_option_desc, is_auto_create_stats_on, is_auto_update_stats_on, is_auto_update_stats_async_on
FROM master.sys.databases 
WHERE  state <> 6	--OFFLINE
AND 
(
	(recovery_model_desc <> 'FULL' AND name NOT IN ('master', 'msdb', 'tempdb', 'model', 'DbaData') AND name NOT LIKE 'ReportServer%TempDB')
	OR (page_verify_option_desc <> 'CHECKSUM' AND PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) >= 10)	--SQL 2008 or later
	OR (page_verify_option_desc <> 'CHECKSUM' AND PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) <= 9 AND name NOT IN ('tempdb')) --SQL 2005 or earlier
)
ORDER BY name
GO

--Database files with "non-standard" auto-growth settings.
SELECT d.name DatabaseName, f.name FileName, f.growth, f.physical_name, f.state_desc, f.type_desc
FROM master.sys.master_files f
JOIN master.sys.databases d
	ON d.database_id = f.database_id
WHERE f.is_percent_growth = 1
OR f.growth = 0	--indicates fixed file size
OR f.growth < 1280	--# of 8k pages
GO

--[tempdb] files with "non-standard" auto-growth settings.
SELECT name, type_desc, size, growth, is_percent_growth, growth * 8 / 1024 Growth_MB
FROM tempdb.sys.database_files f
WHERE f.is_percent_growth = 1
OR f.growth = 0	--indicates fixed file size
OR f.growth < 1280	--# of 8k pages
GO

--Read everything from the current error log (excluding repetitive benign stuff).
CREATE TABLE #ErrLog (
	ErrLogId INT IDENTITY PRIMARY KEY NONCLUSTERED,
	LogDate DATETIME,
	ProcessInfo VARCHAR(256),
	[Text] VARCHAR(MAX)
)

INSERT INTO #ErrLog
EXEC sp_readerrorlog 
	0,	--0 = current, 1 = Archive #1, 2 = Archive #2, etc...
	1;	--1 (or NULL) = error log, 2 = SQL Agent log
INSERT INTO #ErrLog
EXEC sp_readerrorlog 
	1,	--0 = current, 1 = Archive #1, 2 = Archive #2, etc...
	1;	--1 (or NULL) = error log, 2 = SQL Agent log

DELETE FROM #ErrLog WHERE [Text] LIKE 'Server process ID is %';
DELETE FROM #ErrLog WHERE [Text] LIKE 'System Manufacturer: %';
DELETE FROM #ErrLog WHERE [Text] LIKE 'Authentication mode is%';
DELETE FROM #ErrLog WHERE [Text] LIKE 'Logging SQL Server messages in file %';
DELETE FROM #ErrLog WHERE [Text] LIKE 'The service account is %';
DELETE FROM #ErrLog WHERE [Text] LIKE 'Default collation: %';
DELETE FROM #ErrLog WHERE [Text] LIKE 'The error log has been reinitialized%';
DELETE FROM #ErrLog WHERE [Text] LIKE 'Microsoft SQL Server %';
DELETE FROM #ErrLog WHERE [Text] LIKE 'UTC adjustment: %';
DELETE FROM #ErrLog WHERE [Text] LIKE '(c) Microsoft Corporation%';
DELETE FROM #ErrLog WHERE [Text] LIKE 'All rights reserved%';
DELETE FROM #ErrLog WHERE [Text] LIKE 'Setting database option RECOVERY to%';
DELETE FROM #ErrLog WHERE [Text] LIKE '%This is an informational message only%no user action is required%';
DELETE FROM #ErrLog WHERE [Text] LIKE 'Starting up database%';
DELETE FROM #ErrLog WHERE [Text] LIKE '%No User action is required%';
DELETE FROM #ErrLog WHERE [Text] LIKE '%Server is listening on%';
DELETE FROM #ErrLog WHERE [Text] LIKE '%Clearing tempdb database%';
DELETE FROM #ErrLog WHERE [Text] LIKE '%The SQL Server Network Interface library successfully registered the Service Principal Name%';
DELETE FROM #ErrLog WHERE [Text] LIKE '%SQL Trace ID 1 was started by login "sa"%';

SELECT LogDate, Text
FROM #ErrLog
ORDER BY ErrLogId;

DROP TABLE #ErrLog;
GO

--Memory, Page Life Expectancy, Page Reads/sec
DECLARE @Tsql NVARCHAR(MAX)
DECLARE @MajorVer SMALLINT
DECLARE @HostServerMemory_GB NUMERIC(10, 2)

SET @MajorVer = CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) AS SMALLINT)

IF @MajorVer >= 11	--SQL 2012 or higher
	SET @Tsql = 'SELECT TOP(1) @Mem = CAST(ROUND(i.physical_memory_kb / 1024.0 / 1024 , 2) AS NUMERIC(10, 2))
FROM sys.dm_os_sys_info i'
ELSE	--SQL 2008 R2 or less
	SET @Tsql = 'SELECT TOP(1) @Mem = CAST(ROUND(physical_memory_in_bytes / 1024.0 / 1024 / 1024, 2) AS NUMERIC(10, 2))
FROM sys.dm_os_sys_info'

EXEC sp_executesql @Tsql, N'@Mem NUMERIC(10, 2) OUTPUT', @HostServerMemory_GB output

--Memory, Page Life Expectancy, Page Reads/sec
SELECT c.value [Max SQL Server Memory (MB)], @HostServerMemory_GB HostServerMemory_GB, ple.PageLifeExpectancy,
	CAST(prs.cntr_value / 1.0 / i.SecondsSinceStartup AS NUMERIC(10, 2)) [Page Reads/sec]
FROM sys.configurations c
CROSS APPLY
(
	SELECT TOP(1) 
		DATEDIFF(ss, sqlserver_start_time, CURRENT_TIMESTAMP) AS SecondsSinceStartup
	FROM sys.dm_os_sys_info
) i,
(
	SELECT object_name, counter_name, cntr_value AS PageLifeExpectancy
	FROM sys.dm_os_performance_counters
	WHERE [object_name] LIKE '%Buffer Manager%'
	AND [counter_name] = 'Page life expectancy'
) ple,
(
	SELECT object_name, counter_name, cntr_value
	FROM sys.dm_os_performance_counters 
	WHERE [object_name] LIKE '%Buffer Manager%'
	AND [counter_name] = 'Page reads/sec'
) prs
WHERE c.name like 'Max_server memory%';
GO

--List of dll's loaded in SQL
SELECT * 
FROM master.sys.dm_os_loaded_modules m
WHERE (m.company IS NULL OR m.company NOT LIKE 'Microsoft%')
AND m.name NOT LIKE '%Microsoft SQL Server%'
AND m.name NOT LIKE '%ODBC32.dll'
AND m.name NOT LIKE '%Oledb32.dll'
AND m.name NOT LIKE '%OleAcc.dll'
AND m.name NOT LIKE '%MSDart.dll'
AND m.name NOT LIKE '%MSadce.dll'
AND m.name NOT LIKE '%\IBM\Client Access%'
GO

/*
	OS Volume Stats
	Query to show disk drive/volume information of all drives that contain at least one database file.
	Drives/volumes that don't contain any database files are excluded from the result set.

	Note: dynamic management function [sys].[dm_os_volume_stats] requires SQL 2008 R2 SP1 or later.
*/
;WITH DriveLetters AS
(
	SELECT DISTINCT LEFT(f.physical_name, 3) DriveLetter
	FROM sys.master_files AS f
),
ParamIds AS
(
	SELECT dl.DriveLetter,
		( SELECT TOP(1) f.database_id FROM sys.master_files f WHERE LEFT(f.physical_name, 3) = dl.DriveLetter ORDER BY f.database_id, f.file_id ) AS database_id,
		( SELECT TOP(1) f.file_id FROM sys.master_files f WHERE LEFT(f.physical_name, 3) = dl.DriveLetter ORDER BY f.database_id, f.file_id ) AS file_id
	FROM DriveLetters dl
)
SELECT vs.volume_mount_point, 
	CAST(ROUND(vs.total_bytes / 1024.0 / 1024, 0) AS INT) AS Total_MB, 
	CAST(ROUND(vs.available_bytes / 1024.0 / 1024, 0) AS INT) AS Available_MB, 
	ROUND(vs.available_bytes / 1.0 / vs.total_bytes, 2) PctFree
FROM ParamIds p
CROSS APPLY sys.dm_os_volume_stats(p.database_id, p.file_id) vs
GO

--Database sizes on disk.
SELECT db_name(f.database_id), SUM(f.size) / 128 / 1024.0 Size_GB
FROM master.sys.master_files f
WHERE db_name(f.database_id) NOT IN ('tempdb')
GROUP BY db_name(f.database_id)
UNION ALL
SELECT 'tempdb', SUM(f.size) / 128 / 1024.0 Size_GB
FROM tempdb.sys.database_files f
GO

--Last restart.
SELECT sqlserver_start_time FROM sys.dm_os_sys_info
GO

--Log File stats
DECLARE @LogStats TABLE
(
    DBName VARCHAR(150) ,
    LogSize_MB FLOAT ,
    LogSpace_Pct FLOAT ,
    [Status] VARCHAR(100)
)
 
INSERT INTO @LogStats
EXEC ( 'DBCC sqlperf(LOGSPACE) WITH NO_INFOMSGS' )
 
SELECT DBName, 
	CAST(LogSize_MB AS NUMERIC(20, 2)) LogSize_MB, 
	CAST(LogSpace_Pct AS NUMERIC(20, 2)) LogSpace_Pct,
	CAST(LogSize_MB * LogSpace_Pct / 100 AS NUMERIC(20, 2)) UsedLogSpace_MB,
	CAST(LogSize_MB - (LogSize_MB * LogSpace_Pct / 100) AS NUMERIC(10, 2)) FreeLogSpace_MB
FROM @LogStats
--WHERE LogSize_MB > 1024
GO

--Index Fragmentation.
SELECT * --index_id, index_type_desc, alloc_unit_type_desc, avg_fragmentation_in_percent, fragment_count, page_count
FROM sys.dm_db_index_physical_stats(
	DB_ID('production_finance'),		--DB_ID
	NULL,	--Table_ID
	NULL, NULL, NULL)
WHERE index_id != 0
AND avg_fragmentation_in_percent > 0
GO

--Table row counts.
SELECT 
	SCHEMA_NAME(o.schema_id) SchemaName,
	OBJECT_NAME(p.object_id) TableName, 
	SUM(p.row_count) [RowCount]
FROM sys.dm_db_partition_stats p
INNER JOIN sys.objects AS o 
  ON o.object_id = p.object_id
WHERE (index_id < 2)
  AND o.type = 'U'
GROUP BY o.schema_id, p.object_id;
GO

--Missing Indexes
SELECT
	d.[object_id],
	OBJECT_SCHEMA_NAME(d.[object_id]) AS Sch,
	OBJECT_NAME(d.[object_id]) AS Obj,
	d.equality_columns,
	d.inequality_columns,
	d.included_columns,
	s.unique_compiles,
	s.user_seeks, s.last_user_seek,
	s.user_scans, s.last_user_scan
--INTO #SuggestedIndexes
FROM sys.dm_db_missing_index_details AS d
INNER JOIN sys.dm_db_missing_index_groups AS g
	ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS s
	ON g.index_group_handle = s.group_handle
WHERE d.database_id = DB_ID()
AND OBJECTPROPERTY(d.[object_id], 'IsMsShipped') = 0;
GO

--Version, Edition, BuildNumber
SELECT --@@VERSION,
	REPLACE(LEFT(@@VERSION, PATINDEX('% - %', @@VERSION)), 'Microsoft SQL Server ', '') Version,
	SERVERPROPERTY('ProductLevel') ProductLevel,
	SERVERPROPERTY('ProductUpdateLevel') AS ProductUpdateLevel,
	SERVERPROPERTY('Edition') Edition, 
	SERVERPROPERTY('ProductVersion') BuildNumber
GO

--IP address of sql server.
SELECT (SELECT sqlserver_start_time 
FROM sys.dm_os_sys_info) AS LastRestart,
	CAST(SERVERPROPERTY(N'MachineName') AS VARCHAR) + '.' + LOWER(DEFAULT_DOMAIN()) + '.pri' DnsName,
	dec.local_net_address
FROM sys.dm_exec_connections AS dec
WHERE dec.session_id = @@SPID;
GO

--SQL Server service accounts
BEGIN
	DECLARE       @DBEngineLogin       VARCHAR(100)
	DECLARE       @AgentLogin          VARCHAR(100)
 
	EXECUTE       master.dbo.xp_instance_regread
				  @rootkey      = N'HKEY_LOCAL_MACHINE',
				  @key          = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
				  @value_name   = N'ObjectName',
				  @value        = @DBEngineLogin OUTPUT
 
	EXECUTE       master.dbo.xp_instance_regread
				  @rootkey      = N'HKEY_LOCAL_MACHINE',
				  @key          = N'SYSTEM\CurrentControlSet\Services\SQLServerAgent',
				  @value_name   = N'ObjectName',
				  @value        = @AgentLogin OUTPUT
 
	--IF @DBEngineLogin NOT LIKE '%mssqladmin%' OR @AgentLogin NOT LIKE '%mssqladmin%'
		SELECT [DBEngineLogin] = @DBEngineLogin, [AgentLogin] = @AgentLogin
	--ELSE
	--	SELECT [DBEngineLogin] = CAST(NULL AS VARCHAR(100)), [AgentLogin] = CAST(NULL AS VARCHAR(100))
	--	WHERE 1 = 2
	--END
END
GO

--Current TCP port
SELECT DISTINCT local_tcp_port 
FROM sys.dm_exec_connections 
WHERE local_tcp_port IS NOT NULL;
GO

/****************************************
	Reset/clear alert history as needed.
****************************************/
DECLARE @AlertName SYSNAME
DECLARE curAlerts CURSOR READ_ONLY FAST_FORWARD FOR
	SELECT name
	FROM msdb.dbo.sysalerts 
	--WHERE name = 'WMI-DB File Growth Events'
	WHERE name BETWEEN '17' AND '26'
	OR name LIKE 'Error 82_'
	OR name LIKE 'WMI-DB%'

OPEN curAlerts
FETCH NEXT FROM curAlerts INTO @AlertName

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC msdb.dbo.sp_update_alert 
		@name=@AlertName, 
		@occurrence_count = 0, 
		@count_reset_date = NULL, 
		@count_reset_time = NULL, 
		@last_occurrence_date = 0, 
		@last_occurrence_time = 0, 
		@last_response_date = 0, 
		@last_response_time = 0
	FETCH NEXT FROM curAlerts INTO @AlertName
END

CLOSE curAlerts
DEALLOCATE curAlerts
GO

/*
	Alerting/Monitoring checks.
*/
SELECT t.name, t.create_date, t.modify_date, t.is_disabled
FROM master.sys.server_triggers t
WHERE t.is_disabled = 1
OR t.modify_date > CURRENT_TIMESTAMP - 3;
GO

SELECT * 
FROM DbaData.sys.services s
WHERE s.name LIKE 'svc%'
GO

SELECT q.name, q.create_date, q.modify_date, q.is_receive_enabled, q.is_enqueue_enabled
FROM DbaData.sys.service_queues q
WHERE q.name LIKE 'que%'
AND (
	q.is_receive_enabled = 0 OR 
	q.is_enqueue_enabled = 0 OR
	q.modify_date > CURRENT_TIMESTAMP - 3
);
GO

SELECT en.name, en.create_date, en.modify_date, en.service_name
FROM DbaData.sys.server_event_notifications en;
GO