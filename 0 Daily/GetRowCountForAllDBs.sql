SELECT	o.name AS [TableName],
	i.rows AS [RowCount]
FROM	sysobjects o
JOIN	sysindexes i	ON o.id = i.id
WHERE	xtype='u'
	AND	indid < 2 --heap or clustered
ORDER BY [RowCount] DESC