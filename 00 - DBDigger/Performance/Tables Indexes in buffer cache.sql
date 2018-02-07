SELECT
o.name,
i.name,
bd.*
FROM
sys.dm_os_buffer_descriptors bd
INNER JOIN sys.allocation_units a
ON bd.allocation_unit_id = a.allocation_unit_id
INNER JOIN sys.partitions p
ON (a.container_id = p.hobt_id AND
a.type IN (1, 3)) OR
(a.container_id = p.partition_id AND
a.type = 2)
INNER JOIN sys.objects o
ON p.object_id = o.object_id
INNER JOIN sys.indexes i
ON p.object_id = i.object_id AND
p.index_id = i.index_id