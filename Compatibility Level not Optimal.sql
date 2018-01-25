/*
	Databases below the highest compatibility level supported by the instance.
	References:
		Version List: http://sqlserverbuilds.blogspot.com/
		Compatibility Levels: https://msdn.microsoft.com/en-us/library/bb510680.aspx
		SERVERPROPERTY: https://msdn.microsoft.com/en-us/library/ms174396.aspx
*/
SELECT name, owner_sid, compatibility_level,
	PARSENAME( CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) * 10 AS MajVer
FROM master.sys.databases 
WHERE compatibility_level <> PARSENAME( CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR), 4) * 10

