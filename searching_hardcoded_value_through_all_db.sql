/*
Created by Viktoria Rimko.
The script helps to find the hardcoded value in all MS SQL databases on the current server\instance.
If you have any questions about using the script, be sure to let me know.

Comments and changes are welcome. :) 
*/


USE [master]
GO

SET NOCOUNT ON;


CREATE TABLE #temp (
	 TABLE_CATALOG nvarchar(max)
	,TABLE_SCHEMA nvarchar(max)
	,TABLE_NAME nvarchar(max)
	,COLUMN_NAME nvarchar(max)
	,row_numb int identity(1,1)
)


CREATE TABLE #result (
	 ColumnValue nvarchar(max)
	,DatabaseName nvarchar(max)
	,SchemaName nvarchar(max)
	,TableName nvarchar(max)
	,ColumnName nvarchar(max)
)


DECLARE 

	 @database sysname
	,@schema sysname
	,@table sysname
	,@column sysname
	,@list nvarchar(max) = N'Everything you want to find' -- Here you should write hardcoded value.
	,@row_numb int
	,@counter int
	,@query nvarchar(max)



SELECT [name], ROW_NUMBER() OVER(ORDER BY [name] ASC) AS row_numb
INTO #dblist
FROM sys.databases
WHERE database_id > 4 -- Here you can list all the database IDs for which you want to search.
-- WHERE database_id IN (5, 6, 7)

-- All database IDs you can find here:
/*
SELECT [name], [database_id]
FROM sys.databases
*/

SET @counter = 1
SET	@row_numb = (SELECT COUNT(*) FROM #dblist)


WHILE (@counter <= @row_numb)
BEGIN

	SET	@database = (SELECT [name] FROM #dblist WHERE row_numb = @counter)

	SET @query = N'

	USE ['+@database+'];

	INSERT INTO #temp
	SELECT a.*
	FROM (
		SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
		FROM ['+@database+'].INFORMATION_SCHEMA.COLUMNS
		WHERE DATA_TYPE NOT IN (N''image'',N''timestamp'')  -- Optional filter
	) a
	'

	EXEC (@query)
    SET @counter = @counter + 1

END



SET @counter = 1
SET	@row_numb = (SELECT COUNT(*) FROM #temp)


WHILE (@counter <= @row_numb)
BEGIN

    SET	@database = (SELECT TABLE_CATALOG FROM #temp WHERE row_numb = @counter)
	SET	@schema = (SELECT TABLE_SCHEMA FROM #temp WHERE row_numb = @counter)
	SET	@table = (SELECT TABLE_NAME FROM #temp WHERE row_numb = @counter)
	SET	@column = (SELECT COLUMN_NAME FROM #temp WHERE row_numb = @counter)

	
	SET @query = N'

	USE ['+@database+'];


	-----Uncomment this block if you need to change the value to something else.-----
	--UPDATE ['+@table+']
	--SET ['+@column+'] = REPLACE(['+@column+'], ''C:\Temp\Production'', ''C:\Temp\Test'')
	---------------------------------------------------------------------------------
	
	INSERT INTO #result
	SELECT r.*
	FROM (
	SELECT
	     CAST(['+@column+'] AS nvarchar(max)) as ColumnValue
		,N'''+@database+N''' as DatabaseName
		,N'''+@schema+N''' as SchemaName
		,N'''+@table+N''' as TableName
		,N'''+@column+N''' as ColumnName
	
	FROM ['+@database+'].['+@schema+'].['+@table+']
	WHERE CAST(['+@column+'] AS nvarchar(max)) LIKE '''+@list+'%'''+'
	) r
	'

	EXEC (@query)
    SET @counter = @counter + 1
END

SELECT DISTINCT * FROM #result;
PRINT @query

DROP TABLE #dblist;
DROP TABLE #temp;
DROP TABLE #result;

