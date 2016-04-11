---
--- Functions
---
create or replace function allocation.calculate_allocation_result_partition_map(i_number_of_partition int)
returns setof allocation.allocation_result_partition_map
AS
$body$
declare
  start_udi_id int;
  end_udi_id int;
  total_record_count bigint;
  records_per_partition int;
  partition_record_count int := 0;
  cur_udi int;
  cur_record_count int;
  cur_partition_id int := 1;
begin
  select min(universal_data_id), sum(record_count)
    into start_udi_id, total_record_count
    from allocation.allocation_result_distribution;
    
  if found then
    truncate allocation.allocation_result_partition_map;
    records_per_partition := round((total_record_count/i_number_of_partition) + .4);
    
    for cur_udi, cur_record_count in (select universal_data_id, record_count from allocation.allocation_result_distribution order by universal_data_id) union all (select -1, 0) loop
      if cur_udi = -1 then
        if cur_partition_id > i_number_of_partition then
          update allocation.allocation_result_partition_map set end_universal_data_id = end_udi_id, record_count = record_count + partition_record_count where partition_id = i_number_of_partition;
          exit;
        end if;
      elsif (partition_record_count + cur_record_count) < records_per_partition then
        partition_record_count := partition_record_count + cur_record_count;
        end_udi_id := cur_udi;
        continue;
      end if;
      
      insert into allocation.allocation_result_partition_map(partition_id, begin_universal_data_id, end_universal_data_id, record_count)
      values(cur_partition_id, start_udi_id, end_udi_id, partition_record_count);
      
      partition_record_count := cur_record_count;
      start_udi_id := cur_udi;
      cur_partition_id := cur_partition_id + 1;
    end loop;
    
    return query select * from allocation.allocation_result_partition_map;
  end if;
end
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION allocation.maintain_allocation_result_partition() 
RETURNS TABLE(created INT, dropped INT) AS
$body$
DECLARE 
  partitions_created INT := 0;
  partitions_dropped INT := 0;
  pid INT;
  begin_id INT;
  end_id INT;
  action VARCHAR(10);
BEGIN
  FOR pid, begin_id, end_id, action IN 
    SELECT COALESCE(fe.partition_id, p.partition_id),
           fe.begin_universal_data_id,
           fe.end_universal_data_id,
           CASE 
           WHEN fe.partition_id IS NULL THEN
             'drop'
           WHEN p.partition_id IS NULL THEN
             'create'
           ELSE
             'nop'
            END
      FROM allocation.allocation_result_partition_map AS fe
      FULL JOIN (SELECT REPLACE(table_name, 'allocation_result_', '')::INT AS partition_id FROM schema_v('allocation_partition') WHERE table_name ~ E'^allocation_result_\\d+$') AS p ON (p.partition_id = fe.partition_id)
  LOOP
    IF action = 'create' THEN
      EXECUTE 'CREATE TABLE allocation_partition.allocation_result_' || pid || '(CHECK(universal_data_id BETWEEN ' || begin_id || ' AND ' || end_id || ')) INHERITS (allocation.allocation_result)';
      EXECUTE 'ALTER TABLE allocation_partition.allocation_result_' || pid || ' SET (autovacuum_enabled = false)';
      partitions_created := partitions_created + 1;
    ELSIF action = 'drop' THEN
      EXECUTE 'DROP TABLE allocation_partition.allocation_result_' || pid; 
      partitions_dropped := partitions_dropped + 1;
    END IF;
  END LOOP;
  
  IF partitions_created > 0 THEN 
    GRANT USAGE ON SCHEMA allocation_partition TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA allocation_partition TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA allocation_partition TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA allocation_partition TO web;
  END IF;
  
  RETURN QUERY SELECT partitions_created, partitions_dropped;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION allocation.maintain_allocation_result_indexes(i_partition_name TEXT) 
RETURNS SETOF TEXT AS
$body$
DECLARE 
  indexes_created INT := 0;
  indexes_dropped INT := 0;
  table_name TEXT;
  index_name TEXT;
  column_name TEXT;         
  action VARCHAR(10);
  columns_to_index TEXT[] := ARRAY['allocation_simple_area_id', 'universal_data_id', 'cell_id'];
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
      FULL JOIN (SELECT iv.table_name, iv.index_name FROM index_v('allocation_partition') iv WHERE iv.table_name = i_partition_name AND iv.index_name NOT LIKE 'TOTALS:%') AS i ON (i.index_name = ti.index_name)
     WHERE (ti.index_name IS NULL OR i.index_name IS NULL)
  LOOP
    IF action = 'create' THEN
      RETURN NEXT ('CREATE INDEX ' || table_name || '_' || column_name || '_idx ON allocation_partition.' || table_name || '(' || column_name || ')');
      indexes_created := indexes_created + 1;
    ELSIF action = 'drop' THEN
      RETURN NEXT ('DROP INDEX allocation_partition.' || index_name); 
      indexes_dropped := indexes_dropped + 1;
    END IF;
  END LOOP;
  
  RETURN;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION allocation.maintain_allocation_data_partition() 
RETURNS TABLE(created INT, dropped INT) AS
$body$
DECLARE 
  partitions_created INT := 0;
  partitions_dropped INT := 0;
  p_year INT;
  action VARCHAR(10);
BEGIN
  FOR p_year, action IN 
    SELECT COALESCE(ay.year, p.year),
           CASE 
           WHEN ay.year IS NULL THEN
             'drop'
           WHEN p.year IS NULL THEN
             'create'
           ELSE
             'nop'
            END
      FROM (SELECT DISTINCT ad.year FROM allocation.allocation_data ad) AS ay
      FULL JOIN (SELECT REPLACE(table_name, 'allocation_data_', '')::INT AS year 
                   FROM schema_v('allocation_data_partition') 
                  WHERE table_name ~ E'^allocation_data_\\d+$') AS p ON (p.year = ay.year)
  LOOP
    IF action = 'create' THEN
      EXECUTE 'CREATE TABLE allocation_data_partition.allocation_data_' || p_year || '(CHECK(year = ' || p_year || ')) INHERITS (allocation.allocation_data_eez_hs)';
      partitions_created := partitions_created + 1;
    ELSIF action = 'drop' THEN
      EXECUTE 'DROP TABLE allocation_data_partition.allocation_data_' || p_year; 
      partitions_dropped := partitions_dropped + 1;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT partitions_created, partitions_dropped;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION allocation.maintain_allocation_data_indexes(i_partition_name TEXT) 
RETURNS SETOF TEXT AS
$body$
DECLARE 
  indexes_created INT := 0;
  indexes_dropped INT := 0;
  table_name TEXT;
  index_name TEXT;
  column_name TEXT;         
  action VARCHAR(10);
  columns_to_index TEXT[] := ARRAY['universal_data_id'];
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
      FULL JOIN (SELECT iv.table_name, iv.index_name 
                   FROM index_v('allocation_data_partition') iv 
                  WHERE iv.table_name = i_partition_name AND iv.index_name NOT LIKE 'TOTALS:%') AS i ON (i.index_name = ti.index_name)
     WHERE (ti.index_name IS NULL OR i.index_name IS NULL)
  LOOP
    IF action = 'create' THEN
      RETURN NEXT ('CREATE INDEX ' || table_name || '_' || column_name || '_idx ON allocation_data_partition.' || table_name || '(' || column_name || ')');
      indexes_created := indexes_created + 1;
    ELSIF action = 'drop' THEN
      RETURN NEXT ('DROP INDEX allocation_data_partition.' || index_name); 
      indexes_dropped := indexes_dropped + 1;
    END IF;
  END LOOP;
  
  RETURN;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION allocation.populate_allocation_data_partition_udi(i_year int) 
RETURNS VOID AS
$body$
BEGIN
  TRUNCATE TABLE allocation.allocation_data_partition_udi;
              
  EXECUTE 
  format('INSERT INTO allocation.allocation_data_partition_udi(fishing_entity_id, taxon_key, catch_type_id, sector_type_id, partition_id, udi)
          SELECT ad.fishing_entity_id, ad.taxon_key, ad.catch_type_id, ad.sector_type_id, 
                 array_agg(distinct m.partition_id order by m.partition_id) partition_id, 
                 array_agg(distinct ad.universal_data_id order by ad.universal_data_id) uid
            FROM allocation_data_partition.allocation_data_%s ad
            JOIN allocation.allocation_result_partition_map m 
              ON (ad.universal_data_id between m.begin_universal_data_id and m.end_universal_data_id)
           GROUP BY ad.fishing_entity_id, ad.taxon_key, ad.catch_type_id, ad.sector_type_id',
         i_year); 
END;
$body$
LANGUAGE plpgsql;
       
CREATE OR REPLACE FUNCTION allocation.generate_insert_cell_catch_partition_statements(i_year int) 
RETURNS SETOF TEXT AS
$body$
DECLARE
  PARTITION_BATCH_SIZE constant smallint := 20;
  UDI_BATCH_SIZE constant smallint := 80;
  rec record;
  allocation_data_partition_udi_id int[] := '{}';
  partition_count smallint := 0;
  udi_count int := 0;
BEGIN
  FOR rec IN SELECT id, array_length(partition_id, 1) partitions, array_length(udi, 1) udis FROM allocation.allocation_data_partition_udi
             UNION ALL
             SELECT -1, -1, -1
  LOOP
    IF rec.id = -1 OR (partition_count + rec.partitions) > PARTITION_BATCH_SIZE OR (udi_count + rec.udis) > UDI_BATCH_SIZE THEN
      RETURN NEXT format('SELECT allocation.insert_cell_catch_partition(%s, u.id) FROM unnest(''%s''::int[]) AS u(id)', 
                         i_year, 
                         allocation_data_partition_udi_id);
      partition_count := rec.partitions;                     
      udi_count := rec.udis;
      allocation_data_partition_udi_id := ARRAY[rec.id];
    ELSE
      partition_count := partition_count + rec.partitions;                     
      udi_count := udi_count + rec.udis;
      allocation_data_partition_udi_id := allocation_data_partition_udi_id || rec.id;
    END IF;
  END LOOP;
  
  RETURN;
END;
$body$
LANGUAGE plpgsql;
       
CREATE OR REPLACE FUNCTION allocation.insert_cell_catch_partition(i_year int, i_allocation_data_partition_udi_id INT) 
RETURNS VOID AS
$body$
DECLARE
  adpu allocation.allocation_data_partition_udi%ROWTYPE;
  ar_query TEXT;        
  cell_catch_query TEXT;
  c_group smallint;
  f_group smallint;
  c_status char(1);
  r_status char(1);
BEGIN                                
  SELECT * INTO adpu FROM allocation.allocation_data_partition_udi WHERE id = i_allocation_data_partition_udi_id;
  
  IF FOUND THEN
    SELECT cdt.commercial_group_id, cdt.functional_group_id
      INTO c_group, f_group
      FROM web.cube_dim_taxon cdt 
     WHERE cdt.taxon_key = adpu.taxon_key;
 
    c_status := (case when adpu.catch_type_id in (1, 3) then 'R' when adpu.catch_type_id = 2 then 'D' else null end)::CHAR(1);
    r_status := (case when adpu.catch_type_id = 1 then 'R' when adpu.catch_type_id in (2, 3) then 'U' else null end)::CHAR(1);
    
    SELECT array_to_string(ARRAY_AGG('(SELECT cell_id, SUM(allocated_catch) ac' || 
                                     '   FROM allocation_partition.allocation_result_' || u.partition_id || 
                                     '  WHERE universal_data_id = ANY($8) GROUP BY cell_id)'), 
                           ' UNION ALL ')
      INTO ar_query                                                              
      FROM unnest(adpu.partition_id) AS u(partition_id);  
      
    cell_catch_query := format(
      'INSERT INTO web_partition.cell_catch_p%s(year,fishing_entity_id,taxon_key,cell_id,commercial_group_id,functional_group_id,sector_type_id,catch_status,reporting_status,catch_sum)
       SELECT %1$s, $1, $2, t.cell_id, $3, $4, $5, $6, $7, sum(ac)
         FROM (%s) AS t
        GROUP BY t.cell_id',
      i_year, ar_query);
      
    EXECUTE cell_catch_query 
      USING adpu.fishing_entity_id, adpu.taxon_key, c_group, f_group, adpu.sector_type_id, c_status, r_status, adpu.udi;
  END IF;
END;
$body$
LANGUAGE plpgsql;

------
------ GRANTS for the functions defined above
------

/*
The command below should be maintained as the last command in this entire script.
*/
SELECT admin.grant_access();
