/*
	SELECT name, type_desc, size, growth, is_percent_growth, growth * 8 / 1024 Growth_MB
	FROM tempdb.sys.database_files f
	WHERE f.is_percent_growth = 1
	OR f.growth = 0	--indicates fixed file size
	OR f.growth < 1280	--# of 8k pages
*/

--Script was run in ATL on 4/30/2015 @ 5:10 PM
IF EXISTS(
	SELECT *
	FROM tempdb.sys.database_files f
	WHERE f.is_percent_growth = 0
	AND (
		f.growth = 0	--indicates fixed file size
		OR f.growth < 1280	--# of 8k pages
	)
	AND name = 'tempdev'
)
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', FILEGROWTH = 50MB )
GO

IF EXISTS(
	SELECT *
	FROM tempdb.sys.database_files f
	WHERE f.is_percent_growth = 0
	AND (
		f.growth = 0	--indicates fixed file size
		OR f.growth < 1280	--# of 8k pages
	)
	AND name = 'templog'
)
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', FILEGROWTH = 100MB )
GO