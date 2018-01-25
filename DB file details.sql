--View details of the db files
SELECT 
	Name,
	CAST(size AS FLOAT) * 8 / 1024 AS [File Size (MB)], 
	CAST(size AS FLOAT) * 8 / 1024 / 1024 AS [File Size (GB)],
	Filename,
	FileId,
	GroupId
FROM SysFiles


--Size, free space, used space
--per db
;WITH t AS
(
	Select fileproperty(name, 'SpaceUsed') * 8 / 1024 as Used, name, size * 8 / 1024 AS Size
	FROM sys.database_files f
	--WHERE f.type_desc = 'ROWS'
)
SELECT *, t.size - t.used AS Avail
FROM t