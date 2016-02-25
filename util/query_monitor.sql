CREATE TABLE admin.query_monitor(
  id serial primary key,
  db_name text,
  app_name text,
  query text,
  query_start timestamp, 
  elapsed interval,
  constraint query_monitor_ak unique(db_name, app_name, query)
);

CREATE OR REPLACE FUNCTION admin.f_query_monitor(i_elapsed_time_threshold TEXT) 
RETURNS TABLE(updated int, inserted int) AS
$body$
  WITH stat(db_name, app_name, query_start, elapsed, query) AS (
    SELECT pa.datname, pa.application_name, pa.query_start, now() - pa.query_start, pa.query
      FROM pg_stat_activity pa
     WHERE state = 'active'
  ),
  fstat AS (
    SELECT s.*,
           CASE 
           WHEN s.query IS NULL THEN
             'na'
           WHEN qm.query IS NULL THEN
             'insert'
           ELSE
             'update'
           END AS action
      FROM stat s
      FULL JOIN admin.query_monitor qm ON (qm.db_name = s.db_name and qm.app_name = s.app_name and qm.query = s.query)
     WHERE s.elapsed > i_elapsed_time_threshold::INTERVAL
  ),
  ins AS (
    INSERT INTO admin.query_monitor(db_name, app_name, query, query_start, elapsed) 
    SELECT db_name, app_name, query, query_start, elapsed FROM fstat WHERE action = 'insert' RETURNING 1
  ),                                        
  upd AS (
    UPDATE admin.query_monitor qm
       SET query_start = fs.query_start, 
           elapsed = fs.elapsed
      FROM fstat fs 
     WHERE fs.action = 'update'
       AND qm.db_name = fs.db_name
       AND qm.app_name = fs.app_name
       AND qm.query = fs.query
       AND qm.elapsed < fs.elapsed
     RETURNING 1
  )
  SELECT (SELECT COUNT(*) FROM upd)::INT, (SELECT COUNT(*) FROM ins)::INT;
$body$
LANGUAGE sql;
