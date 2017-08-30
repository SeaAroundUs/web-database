drop view if exists web.v_gear_catch;
drop materialized view if exists web.v_dim_gear;

ALTER TABLE web.v_fact_data ALTER COLUMN gear_id type integer;

create or replace view web.v_gear_catch
as
 select f.marine_layer_id,
        f.main_area_id,
        f.sub_area_id,
        f.year,
        g.gear_id,
        g.name AS gear_name,
        f.catch_sum,
        f.real_value
   from web.v_fact_data f
   join web.gear g on g.gear_id = f.gear_id;

create materialized view web.v_dim_gear
as                    
  with active_gear as (
    select distinct cad.gear_id from web.v_fact_data cad
  )
  select g.gear_id, g.name                               
    from web.gear g
    join active_gear ag on (ag.gear_id = g.gear_id)
with no data;

DROP TABLE IF EXISTS allocation.allocation_data;

CREATE TABLE allocation.allocation_data ( 
    universal_data_id integer PRIMARY KEY,
    allocation_area_type_id smallint DEFAULT 0 NOT NULL,
    generic_allocation_area_id integer NOT NULL,
    data_layer_id smallint DEFAULT 0 NOT NULL,
    fishing_entity_id integer NOT NULL,
    year integer NOT NULL,
    taxon_key integer NOT NULL,
    catch_amount double precision NOT NULL,
    sector_type_id smallint DEFAULT 0 NOT NULL,
    catch_type_id smallint DEFAULT 0 NOT NULL,
    reporting_status_id smallint DEFAULT 0 NOT NULL,
    input_type_id smallint DEFAULT 0 NOT NULL,
    gear_type_id integer DEFAULT 0 NOT NULL,
    unique_area_id_auto_gen integer,
    original_fishing_entity_id integer NOT NULL,
    unit_price double precision not null default 1466
);

CREATE INDEX allocation_data_taxon_key_idx ON allocation.allocation_data(taxon_key);
CREATE INDEX allocation_data_fishing_entity_id_year_idx ON allocation.allocation_data(fishing_entity_id, year);

ALTER TABLE allocation.allocation_data_eez_hs ADD COLUMN gear_type_id integer NOT NULL DEFAULT 0;
ALTER TABLE web.cell_catch ADD COLUMN gear_type_id integer;
ALTER TABLE allocation.allocation_data_partition_udi ADD COLUMN gear_type_id integer;


CREATE OR REPLACE FUNCTION allocation.populate_allocation_data_partition_udi(i_year int) 
RETURNS VOID AS
$body$
BEGIN
  TRUNCATE TABLE allocation.allocation_data_partition_udi;
              
  EXECUTE 
  format('INSERT INTO allocation.allocation_data_partition_udi(fishing_entity_id, taxon_key, catch_type_id, reporting_status_id, sector_type_id, partition_id, udi, gear_type_id)
          SELECT ad.fishing_entity_id, ad.taxon_key, ad.catch_type_id, ad.reporting_status_id, ad.sector_type_id, 
                 array_agg(distinct m.partition_id order by m.partition_id) partition_id, 
                 array_agg(distinct ad.universal_data_id order by ad.universal_data_id) uid,
                 ad.gear_type_id
            FROM allocation_data_partition.allocation_data_%s ad
            JOIN allocation.allocation_result_partition_map m 
              ON (ad.universal_data_id between m.begin_universal_data_id and m.end_universal_data_id)
           GROUP BY ad.fishing_entity_id, ad.taxon_key, ad.catch_type_id, ad.reporting_status_id, ad.sector_type_id, ad.gear_type_id',
         i_year); 
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
 
    SELECT c.abbreviation, r.abbreviation 
      INTO c_status, r_status 
      FROM web.catch_type c, web.reporting_status r
     WHERE c.catch_type_id = adpu.catch_type_id AND r.reporting_status_id = adpu.reporting_status_id;
    
    SELECT array_to_string(ARRAY_AGG('(SELECT cell_id, SUM(allocated_catch) ac' || 
                                     '   FROM allocation_partition.allocation_result_' || u.partition_id || 
                                     '  WHERE universal_data_id = ANY($8) GROUP BY cell_id)'), 
                           ' UNION ALL ')
      INTO ar_query                                                              
      FROM unnest(adpu.partition_id) AS u(partition_id);  
      
    cell_catch_query := format(
      'INSERT INTO web_partition.cell_catch_p%s(year,fishing_entity_id,taxon_key,cell_id,commercial_group_id,functional_group_id,sector_type_id,catch_status,reporting_status,catch_sum,gear_type_id)
      SELECT %1$s, $1, $2, t.cell_id, $3, $4, $5, $6, $7, sum(ac), $9
         FROM (%s) AS t
        GROUP BY t.cell_id',
      i_year, ar_query);
      
    EXECUTE cell_catch_query 
      USING adpu.fishing_entity_id, adpu.taxon_key, c_group, f_group, adpu.sector_type_id, c_status, r_status, adpu.udi, adpu.gear_type_id;
  END IF;
END;
$body$
LANGUAGE plpgsql;

select admin.grant_access();
