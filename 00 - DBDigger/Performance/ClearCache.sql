USE <YOURDATABASENAME>;
GO
CHECKPOINT;
GO
DBCC FREEPROCCACHE
GO
DBCC DROPCLEANBUFFERS
GO