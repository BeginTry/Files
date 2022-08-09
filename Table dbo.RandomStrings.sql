USE tempdb
GO

DROP TABLE IF EXISTS dbo.RandomStrings;

CREATE TABLE dbo.RandomStrings (
	ID INT IDENTITY PRIMARY KEY,
	AsciiString VARCHAR(MAX),
	UnicodeString1 NVARCHAR(MAX),
	UnicodeString2 NVARCHAR(MAX),
	UnicodeString3 NVARCHAR(MAX)
)

DECLARE @StringLength INT = 1;

WHILE @StringLength <= 8000
BEGIN
	DECLARE @AsciiString VARCHAR(MAX);
	DECLARE @UnicodeString NVARCHAR(MAX);
	DECLARE @UnicodeString3 NVARCHAR(MAX);

	--Ascii string using char codes from 32 to 255
	SELECT @AsciiString = STRING_AGG(CAST(CHAR(v.number) AS VARCHAR(MAX)), '') 
		WITHIN GROUP(ORDER BY NEWID()) --AS AsciiString
	FROM master..spt_values v
	CROSS JOIN master..spt_values v2
	WHERE v.type = 'P'
	AND v2.type = 'P'
	AND v2.number < (8000 / (255 - 32)) + 1
	AND v.number >= 32
	AND v.number <= 255

	--Unicode string using nchar codes from 32 to 65535
	;WITH AllNcharCodes AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RowNum
		FROM master..spt_values v
		CROSS JOIN master..spt_values v2
	),
	RowNumbers AS
	(
		SELECT TOP(@StringLength) n.RowNum
		FROM AllNcharCodes n
		WHERE n.RowNum <= 65535
		AND n.RowNum >= 32
		ORDER BY NEWID()
	)
	SELECT @UnicodeString =
		STRING_AGG(CAST(NCHAR(r.RowNum) AS NVARCHAR(MAX)), '') 
		WITHIN GROUP(ORDER BY NEWID()) --AS UnicodeString
	FROM RowNumbers r;

	--Unicode string using nchar codes from 32 to 2540
	;WITH NcharCodesSubset AS
	(
		--2540 rows
		SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RowNum
		FROM master..spt_values v
		--CROSS JOIN master..spt_values v2
	)
	SELECT TOP(@StringLength) @UnicodeString3 = --n.RowNum
		STRING_AGG(CAST(NCHAR(n.RowNum) AS NVARCHAR(MAX)), '') 
			WITHIN GROUP(ORDER BY NEWID()) --AS UnicodeString
	FROM NcharCodesSubset n
	CROSS JOIN ( SELECT * FROM (VALUES(1), (2), (3), (4)) AS X(X) ) X
	WHERE n.RowNum >= 32

	INSERT INTO dbo.RandomStrings(AsciiString, UnicodeString1, UnicodeString2, UnicodeString3) 
	VALUES (
		LEFT(@AsciiString, @StringLength),
		LEFT(@AsciiString, @StringLength),
		LEFT(@UnicodeString, @StringLength),
		LEFT(@UnicodeString3, @StringLength)
	);
	SET @StringLength += 1;
END
