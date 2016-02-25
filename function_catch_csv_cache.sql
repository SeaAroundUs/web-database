CREATE OR REPLACE FUNCTION web_cache.maintain_catch_csv_partition(i_entity_layer_id int) 
RETURNS TABLE(created INT, dropped INT) AS
$body$
DECLARE
  entity_id int;
  partitions_created INT := 0;
  partitions_dropped INT := 0;
  partition_name TEXT;
  action VARCHAR(10);
BEGIN
  FOR entity_id, partition_name, action IN 
    SELECT fe.entity_id,
           COALESCE(fe.p_name, p.p_name) AS p_name,
           CASE 
           WHEN fe.p_name IS NULL THEN
             'drop'
           WHEN p.p_name IS NULL THEN
             'create'
           ELSE
             'nop'
            END
      FROM (SELECT DISTINCT v.main_area_id AS entity_id, ('catch_csv_' || i_entity_layer_id || '_' || v.main_area_id) AS p_name FROM web.v_fact_data v WHERE marine_layer_id = i_entity_layer_id) AS fe
      FULL JOIN (SELECT table_name AS p_name FROM schema_v('web_cache') WHERE table_name LIKE 'catch_csv_%') AS p ON (p.p_name = fe.p_name)
  LOOP
    IF action = 'create' THEN
      EXECUTE FORMAT('CREATE TABLE web_cache.%s (CHECK(entity_layer_id = %s AND entity_id = %s)) INHERITS (web.catch_data_in_csv_cache)', partition_name, i_entity_layer_id, entity_id);
      EXECUTE 'ALTER TABLE web_cache.' || partition_name || ' SET (autovacuum_enabled = false)';
      partitions_created := partitions_created + 1;
    ELSIF action = 'drop' THEN
      EXECUTE 'DROP TABLE web_cache.' || partition_name; 
      partitions_dropped := partitions_dropped + 1;
    END IF;
  END LOOP;
  
  IF partitions_created > 0 THEN
    PERFORM admin.grant_access();
  END IF;
  
  RETURN QUERY SELECT partitions_created, partitions_dropped;
END;
$body$
LANGUAGE plpgsql;
