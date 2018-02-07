SELECT 
    DB_NAME(dbid) as DBName, 
    COUNT(dbid) as NumberOfConnections,
    hostname,
    loginame as LoginName
FROM
    sys.sysprocesses
WHERE 
    DB_NAME (DBID)  = 'wmp_ss'
GROUP BY     dbid, loginame, hostname
order by COUNT(dbid) desc