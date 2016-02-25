CREATE OR REPLACE FUNCTION web_partition.maintain_cell_catch_partition() 
RETURNS TABLE(created INT, dropped INT) AS
$body$
DECLARE 
  partitions_created INT := 0;
  partitions_dropped INT := 0;
  partition_name TEXT;
  action VARCHAR(10);
BEGIN
  FOR partition_name, action IN 
    SELECT COALESCE(fe.p_name, p.p_name) AS p_name,
           CASE 
           WHEN fe.p_name IS NULL THEN
             'drop'
           WHEN p.p_name IS NULL THEN
             'create'
           ELSE
             'nop'
            END
      FROM (SELECT ('cell_catch_p' || time_business_key) AS p_name FROM web.time) AS fe
      FULL JOIN (SELECT table_name AS p_name FROM schema_v('web_partition') WHERE table_name LIKE 'cell_catch_p%') AS p ON (p.p_name = fe.p_name)
  LOOP
    IF action = 'create' THEN
      EXECUTE 'CREATE TABLE web_partition.' || partition_name || '(CHECK(year = ' || REPLACE(partition_name, 'cell_catch_p', '')::INT || ')) INHERITS (web.cell_catch)';
      EXECUTE 'ALTER TABLE web_partition.' || partition_name || ' SET (autovacuum_enabled = false)';
      partitions_created := partitions_created + 1;
    ELSIF action = 'drop' THEN
      EXECUTE 'DROP TABLE web_partition.' || partition_name; 
      partitions_dropped := partitions_dropped + 1;
    END IF;
  END LOOP;
  
  IF partitions_created > 0 THEN 
    GRANT USAGE ON SCHEMA web TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA web TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA web TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA web TO web;
    
    GRANT USAGE ON SCHEMA web_partition TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA web_partition TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA web_partition TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA web_partition TO web;
  END IF;
  
  RETURN QUERY SELECT partitions_created, partitions_dropped;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION web_partition.maintain_cell_catch_indexes(i_partition_name TEXT) 
RETURNS SETOF TEXT AS
$body$
DECLARE 
  indexes_created INT := 0;
  indexes_dropped INT := 0;
  table_name TEXT;
  index_name TEXT;
  column_name TEXT;         
  action VARCHAR(10);
  columns_to_index TEXT[] := ARRAY['fishing_entity_id', 'taxon_key', 'commercial_group_id', 'functional_group_id'];
BEGIN
  FOR table_name, index_name, column_name, action IN 
    WITH ti(table_name, index_name, column_name) AS (
      SELECT i_partition_name, i_partition_name || '_' || col.name || '_idx', col.name
        FROM unnest(columns_to_index) AS col(name)
    )
    SELECT COALESCE(i.table_name, ti.table_name) AS table_name,
           COALESCE(i.index_name, ti.index_name) AS index_name,
           ti.column_name,
           CASE 
           WHEN i.index_name IS NULL THEN
             'create'
           WHEN ti.index_name IS NULL THEN
             'drop'
           ELSE
             'nop'
            END
      FROM ti
      FULL JOIN (SELECT iv.table_name, iv.index_name FROM index_v('web_partition') iv WHERE iv.table_name = i_partition_name AND iv.index_name NOT LIKE 'TOTALS:%') AS i ON (i.index_name = ti.index_name)
     WHERE (ti.index_name IS NULL OR i.index_name IS NULL)
  LOOP
    IF action = 'create' THEN
      RETURN NEXT ('CREATE INDEX ' || table_name || '_' || column_name || '_idx ON web_partition.' || table_name || '(' || column_name || ')');
      indexes_created := indexes_created + 1;
    ELSIF action = 'drop' THEN
      RETURN NEXT ('DROP INDEX web_partition.' || index_name); 
      indexes_dropped := indexes_dropped + 1;
    END IF;
  END LOOP;
  
  RETURN;
END;
$body$
LANGUAGE plpgsql;

/* for remote connection to cloud db instance */
CREATE OR REPLACE FUNCTION web_partition.create_remote_cell_catch_partition(i_foreign_server text) 
RETURNS TABLE(created INT, dropped INT) AS
$body$
DECLARE 
  partitions_created INT := 0;
  partitions_dropped INT := 0;
  partition_name TEXT;
  action VARCHAR(10);
  partition_column_list TEXT;
BEGIN
  partition_column_list := get_table_column_and_type('web.cell_catch');
     
  FOR partition_name, action IN 
    SELECT COALESCE(fe.p_name, p.p_name) AS p_name,
           CASE 
           WHEN fe.p_name IS NULL THEN
             'drop'
           WHEN p.p_name IS NULL THEN
             'create'
           ELSE
             'nop'
            END
      FROM (SELECT ('cell_catch_p' || time_business_key) AS p_name FROM web.time) AS fe
      FULL JOIN (SELECT table_name AS p_name FROM schema_v('rwp') WHERE table_name LIKE 'cell_catch_p%') AS p ON (p.p_name = fe.p_name)
  LOOP
    IF action = 'create' THEN
      EXECUTE FORMAT('CREATE FOREIGN TABLE rwp.%s(%s) SERVER %s OPTIONS(schema_name ''web_partition'', table_name ''%1$s'')', partition_name, partition_column_list, i_foreign_server);
      partitions_created := partitions_created + 1;
    ELSIF action = 'drop' THEN
      EXECUTE 'DROP FOREIGN TABLE rwp.' || partition_name; 
      partitions_dropped := partitions_dropped + 1;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT partitions_created, partitions_dropped;
END;
$body$
LANGUAGE plpgsql;

