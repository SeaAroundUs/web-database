SELECT OBJECT_SCHEMA_NAME(object_id) AS [schema], OBJECT_NAME(object_id) AS [table_name], SUM(row_count) AS rows
  FROM sys.dm_db_partition_stats
 WHERE index_id < 2
   AND OBJECT_SCHEMA_NAME(object_id) = 'dbo'
 GROUP BY OBJECT_SCHEMA_NAME(object_id), OBJECT_NAME(object_id)
 ORDER BY 3 desc, 1, 2;

CREATE VIEW dbo.vwRowCount AS
WITH tabs AS (
  SELECT ps.object_id, SUM(COALESCE(ps.row_count, 0)) AS rows 
    FROM sys.dm_db_partition_stats ps
   WHERE ps.index_id < 2
     AND OBJECT_SCHEMA_NAME(ps.object_id) = 'dbo'
   GROUP BY ps.object_id
)
SELECT OBJECT_SCHEMA_NAME(t.object_id) AS [schema], OBJECT_NAME(t.object_id) AS [table_name], t.rows,
       (SELECT MIN(stats_date(st.object_id, st.stats_id)) FROM sys.stats st WHERE st.object_id = t.object_id) AS oldest_stat_date
  FROM tabs t
;

CREATE VIEW dbo.vwMerlinToMerlinQACompare AS
WITH merlin(table_name, row_count) as (
  SELECT o.name, SUM(row_count) AS rows
    FROM Merlin.sys.dm_db_partition_stats s
    JOIN Merlin.sys.all_objects o ON (o.object_id = s.object_id AND o.schema_id = 1) 
   WHERE s.index_id < 2
   GROUP BY o.name
),
merlin_qa(table_name, row_count) as (
  SELECT o.name, SUM(row_count) AS rows
    FROM Merlin_qa.sys.dm_db_partition_stats s
    JOIN Merlin_qa.sys.all_objects o ON (o.object_id = s.object_id AND o.schema_id = 1) 
   WHERE s.index_id < 2
   GROUP BY o.name
)
SELECT ma.table_name, ma.row_count AS merlin_qa_rows, m.row_count AS merlin_rows, ABS(ma.row_count - m.row_count) AS rows_difference
  FROM merlin_qa ma
  JOIN merlin m ON (m.table_name = ma.table_name);
