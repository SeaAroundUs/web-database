CREATE OR REPLACE FUNCTION web.lookup_area_bucket_type(i_marine_layer_id int, i_bucket_type_name varchar)
RETURNS int AS
$body$
  SELECT area_bucket_type_id FROM web.area_bucket_type WHERE marine_layer_id = i_marine_layer_id AND name = i_bucket_type_name;
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.lookup_area_key(i_marine_layer_id int, i_main_area_id int[])
RETURNS int[] AS
$body$
  SELECT array_agg(DISTINCT area_key) FROM web.area WHERE marine_layer_id = i_marine_layer_id AND main_area_id = any(i_main_area_id);
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.lookup_area_key_for_fao(i_fao_area_id int[])
RETURNS int[] AS
$body$
  SELECT array_agg(DISTINCT a.area_key) 
    FROM web.fao_area f
    JOIN web.area a ON (a.main_area_id = f.fao_area_id AND a.marine_layer_id = 2)
   WHERE f.fao_area_id = ANY(i_fao_area_id);
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.get_area_status 
(
  i_marine_layer_id int,
  i_main_area_id int,                    
  i_sub_area_id int
)
RETURNS boolean AS
$body$
DECLARE 
  result BOOLEAN := false;
BEGIN
  --Exceptions
  IF (i_marine_layer_id IN (4, 6)) THEN
    result := TRUE;
  ELSIF (i_sub_area_id = 0) THEN
    IF EXISTS(SELECT 1 
                FROM web.area a 
                JOIN web.v_fact_data v ON (a.area_key = v.area_key) 
               WHERE a.marine_layer_iD = i_marine_layer_id
    	         AND a.main_area_iD = i_main_area_id
    	       LIMIT 1)
    THEN
      result := TRUE;
    END IF;
  ELSIF (i_sub_area_id > 0) THEN
    IF EXISTS(SELECT area_key
                FROM web.area a 
               WHERE a.marine_layer_id = i_marine_layer_id AND a.main_area_id = i_main_area_id AND a.sub_area_id = i_sub_area_id
                 AND EXISTS(Select 1 FROM web.v_fact_data v WHERE v.area_key = a.area_key LIMIT 1))
    THEN
      result := TRUE;
    END IF;
  END IF;

  return result; 
END;
$body$
LANGUAGE plpgsql;
                                

CREATE OR REPLACE FUNCTION web.area_get_all_active_combinations()
RETURNS TABLE(marine_layer_id int 
             ,main_area_id int
             ,sub_area_id int
             ,area numeric
             ,ifa numeric
             ,shelf_area numeric
             ,coral_reefs numeric
             ,sea_mounts numeric
             ,number_of_cells int)
AS
$body$
  --for the entire EEZs/LMEs/Global/Mariculture/persian_gulf/Tropics/MEOW
  SELECT marine_layer_id
         ,main_area_id
         ,0
         ,SUM(area)
         ,SUM(ifa)
         ,SUM(shelf_area)
         ,SUM(coral_reefs)
         ,SUM(sea_mounts)
         ,SUM(number_of_cells)::INT
    FROM web.area
   WHERE marine_layer_id IN (1,3,6, 8, 9,10,19)
     AND web.get_area_status(marine_layer_id, main_area_id, sub_area_id)
  GROUP BY main_area_id, marine_layer_id
  UNION ALL
  --for the rest of everything else
  SELECT marine_layer_id  
         ,main_area_id
         ,sub_area_id
         ,area         
         ,ifa  
         ,shelf_area
         ,coral_reefs
         ,sea_mounts
         ,number_of_cells
    FROM web.area
   WHERE web.get_area_status(marine_layer_id, main_area_id, sub_area_id);
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.area_get_all_active_combinations_v1()
RETURNS TABLE(marine_layer_id int 
             ,main_area_id int
             ,sub_area_id int
             ,area numeric
             ,shelf_area numeric
             ,coral_reefs numeric
             ,sea_mounts numeric
             ,number_of_cells int)			
AS
$body$
  --for the entire EEZs/LMEs/Global/MEOW
  (SELECT marine_layer_iD
        ,main_area_id
        ,0
        ,SUM(area)
        ,SUM(shelf_area)
        ,SUM(coral_reefs)
        ,SUM(sea_mounts)
        ,SUM(number_of_cells)::INT
    FROM web.area
   WHERE marine_layer_id IN (1,3,6,19)
     AND web.get_area_status(marine_layer_id, main_area_id, sub_area_id)
  GROUP BY main_area_id, marine_layer_id)
  UNION ALL
  --for the rest of everything else
  (SELECT marine_layer_iD
        ,main_area_id
        ,sub_area_id
        ,Area
        ,shelf_area
        ,coral_reefs
        ,sea_mounts
        ,number_of_cells
    FROM web.area
   WHERE web.get_area_status(marine_layer_id, main_area_id, sub_area_id));
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.etl_get_area_catch_allocation_type_key 
(
  i_legacy_reallocate smallint
)
RETURNS smallint AS
$body$
  SELECT CASE i_legacy_reallocate 
         WHEN 0 THEN 1::SMALLINT 
         WHEN 1 THEN 2::SMALLINT 
         END;
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.etl_get_area_key 
(
  i_marine_layer_id int,
  i_main_area_id int,
  i_sub_area_id int
)
RETURNS int AS
$body$
  SELECT area_key 
    FROM web.area 
   WHERE marine_layer_id = i_marine_layer_id
     AND main_area_id = i_main_area_id
     AND sub_area_id = i_sub_area_id
   LIMIT 1;
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.etl_get_fishing_entity_id 
(
  i_legacy_c_number int
)
RETURNS smallint AS
$body$
  SELECT fishing_entity_id 
    FROM web.fishing_entity
   WHERE legacy_c_number = i_legacy_c_number
   LIMIT 1;
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.etl_get_time_key 
(
  i_year int
)
RETURNS int AS
$body$
  SELECT time_key 
    FROM web.time
   WHERE time_business_key = i_year 
   LIMIT 1;
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.etl_validation_get_fao_name 
(
  i_fao_area_id int
)
RETURNS varchar(50) AS
$body$
  SELECT ' [' || coalesce((SELECT Name FROM web.fao_area WHERE fao_area_id = i_fao_area_id LIMIT 1), '') || ']';
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.etl_validation_get_gear_name 
(                                                                     
  i_gear_id int
)        
RETURNS varchar(50) AS                    
$body$
  SELECT ' [' || coalesce((SELECT name FROM web.gear WHERE gear_id = i_gear_id LIMIT 1), '?') || ']';
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.etl_validation_get_lme_name 
(
  i_lme_id int
)
RETURNS varchar(50) AS
$body$
  SELECT ' [' || coalesce((SELECT name FROM web.lme WHERE lme_id = i_lme_id LIMIT 1), '?') || ']';
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.etl_validation_get_meow_name 
(
  i_meow_id int
)
RETURNS varchar(50) AS
$body$
  SELECT ' [' || coalesce((SELECT name FROM web.meow WHERE meow_id = i_meow_id LIMIT 1), '?') || ']';
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.get_area_primary_production_rate 
(
  i_marine_layer_id int,
  i_main_area_id int,
  i_sub_area_id int
)
RETURNS float AS
$body$
DECLARE 
  result float := NULL;
BEGIN
  IF (i_sub_area_id > 0) THEN
    SELECT ppr 
      INTO result 
      FROM web.area a 
     WHERE a.marine_layer_id = i_marine_layer_id
       AND a.main_area_id = i_main_area_id
       AND a.sub_area_id = i_sub_area_id 
     LIMIT 1;
  ELSIF (i_sub_area_id = 0) THEN
    SELECT SUM(a.ppr * a.area)/(SUM(a.area)) 
      INTO result 
      FROM web.area a 
     WHERE a.marine_layer_id = i_marine_layer_id
       AND a.main_area_id = i_main_area_id;
  END IF;

  RETURN coalesce(result, 0); 
END
$body$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION web.get_area_primary_production 
(
  i_marine_layer_id int,
  i_main_area_id int,
  i_sub_area_id int,
  i_area float
)                      
RETURNS float
AS
$body$
  SELECT web.get_area_primary_production_rate(i_marine_layer_id, i_main_area_id, i_sub_area_id) * i_area * 365 * 1e6 *9 / (1e9);
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.get_area_url_token 
(
  i_marine_layer_id int,
  i_main_area_id int,
  i_sub_area_id int
)
RETURNS varchar(50) AS
$body$
DECLARE 
  result varchar(50);
BEGIN
  SELECT (name || '/' || i_main_area_id) INTO result FROM web.marine_layer WHERE marine_layer_id = i_marine_layer_id LIMIT 1;

  IF i_sub_area_id <> 0 THEN 
    result := result || '_' || i_sub_area_id;
  END IF;

  RETURN result; 
END;
$body$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION web.get_marine_entities
(
  i_marine_layer_id int
)
RETURNS TABLE(area_key int,
              main_area_id int,
              sub_area_id int)	
AS
$body$
  --for the entire EEZs/LMEs/MEOWs
  SELECT area_key, main_area_id, sub_area_id
    FROM web.area
   WHERE (marine_layer_id = i_marine_layer_id) AND (web.get_area_status(marine_layer_id, main_area_id, sub_area_id));
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.get_eez()
RETURNS TABLE(area_key int, 
              main_area_id int,
              sub_area_id int) 
AS
$body$
   --for the entire EEZs/LMEs/MEOWs
   SELECT * FROM web.get_marine_entities(1); 
$body$
LANGUAGE sql;


/* Why 3 input parameters for this function. Only i_main_area_id is used ever */
CREATE OR REPLACE FUNCTION web.get_geo_entity_id 
(
  i_marine_layer_id int,
  i_main_area_id int,
  i_sub_area_id int
)
RETURNS int AS
$body$
  SELECT CASE 
         WHEN i_marine_layer_id = 1 THEN (SELECT geo_entity_id FROM web.eez e WHERE e.eez_id = i_main_area_id LIMIT 1)
         ELSE NULL  
         END;       
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.get_high_sea()
RETURNS TABLE(area_key int, 
              main_area_id int,
              sub_area_id int)	
AS
$body$
  --for the entire EEZs/LMEs/MEOWs                                               
  SELECT * FROM web.get_marine_entities(2); 
$body$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION web.get_lme()
RETURNS TABLE(area_key int, 
              main_area_id int,
              sub_area_id int)	
AS
$body$
  --for the entire EEZs/LMEs/MEOWs
  SELECT * FROM web.get_marine_entities(3); 
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.get_meow()
RETURNS TABLE(area_key int, 
              main_area_id int,
              sub_area_id int)	
AS
$body$
  --for the entire EEZs/LMEs/MEOWs
  SELECT * FROM web.get_marine_entities(19); 
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION web.ppr 
(
  i_total_catch float, 
  i_tl float 
)
RETURNS float AS
$body$
DECLARE 
  result float;
BEGIN
  --SET i_total_catch = i_total_catch * 1e6 -- covert ton to grams
  result := (i_total_catch / 9) * power(10, i_tl-1);
  --SET result = result / 1e12 -- PPR is expressed in billion G x C
  result := result * 9; -- to comply with previous data model
  
  RETURN result;
END
$body$
LANGUAGE plpgsql;

create or replace function web.update_subsidy_landed_value(i_for_year int) returns void as
$body$
  WITH lv AS (
    SELECT w.geo_entity_id, 
           SUM(e.total_catch * d.unit_price) AS landed_value
      FROM allocation.allocation_result_eez e 
      JOIN allocation.allocation_data d ON (d.universal_data_id = e.universal_data_id AND d.year = i_for_year)
      JOIN web.eez w ON (w.eez_id = e.eez_id) 
     WHERE e.eez_id > 0
     GROUP BY w.geo_entity_id
  )
  UPDATE web.subsidy s
     SET landed_value = lv.landed_value/1000.00
    FROM lv
   WHERE s.geo_entity_id = lv.geo_entity_id
     AND s.year = i_for_year;
$body$
language sql;
