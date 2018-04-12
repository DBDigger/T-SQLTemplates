SELECT OBJECT_NAME(c.object_id)
		,s.name AS statistics_name  
      ,c.name AS column_name  
	  ,s.auto_created
	  , s.user_created 
	  ,STATS_DATE(s.object_id, s.stats_id) AS [StatisticUpdateDate]
FROM sys.stats AS s  
INNER JOIN sys.stats_columns AS sc   
    ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id  
INNER JOIN sys.columns AS c   
    ON sc.object_id = c.object_id AND c.column_id = sc.column_id 
	--WHERE  STATS_DATE(s.object_id, s.stats_id) is not null
	ORDER BY [StatisticUpdateDate] asc