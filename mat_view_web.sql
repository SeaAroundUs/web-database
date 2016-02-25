/* materialzed views */
create materialized view web.v_all_taxon
as
  select taxon_key, 
         scientific_name, 
         common_name, 
         commercial_group_id, 
         functional_group_id, 
         tl,        
         sl_max as sl_max_cm, 
         taxon_level_id, 
         taxon_group_id, 
         isscaap_id, 
         lat_north, 
         lat_south, 
         min_depth, 
         max_depth, 
         loo, 
         woo, 
         k, 
         x_min, 
         x_max, 
         y_min, 
         y_max, 
         has_habitat_index, 
         has_map,              
         is_baltic_only
    from web.cube_dim_taxon
with no data;


create materialized view web.v_area_detail
as
  select marine_layer_id, 
         main_area_id, 
         sub_area_id, 
         area, 
         ifa, 
         shelf_area, 
         coral_reefs, 
         sea_mounts, 
         number_of_cells, 
         web.get_area_primary_production_rate(marine_layer_id, main_area_id, sub_area_id) as primary_production_rate, 
         web.get_area_url_token(marine_layer_id, main_area_id, sub_area_id) as area_url_token
    from web.area_get_all_active_combinations()
with no data;


create materialized view web.v_dim_area
as
  select area_key, 
         marine_layer_id, 
         main_area_id, 
         sub_area_id,
         web.get_geo_entity_id(marine_layer_id, main_area_id, sub_area_id) as belongs_to_geo_entity_id,
         web.get_area_primary_production(marine_layer_id, main_area_id, sub_area_id, area) as primary_production
    from web.area
   where web.get_area_status(marine_layer_id, main_area_id, sub_area_id)
with no data;


create materialized view web.v_dim_fishing_entity
as
  with active_fishing_entity as (
    select distinct cad.fishing_entity_id from web.v_fact_data cad
  )
  select fe.fishing_entity_id, name
    from web.fishing_entity fe
    join active_fishing_entity afe on (afe.fishing_entity_id = fe.fishing_entity_id)
with no data;


create materialized view web.v_dim_gear
as                    
  with active_gear as (
    select distinct cad.gear_id from web.v_fact_data cad
  )
  select g.gear_id, g.name                               
    from web.gear g
    join active_gear ag on (ag.gear_id = g.gear_id)
with no data;


create materialized view web.v_dim_taxon
as
  with tax as (
    select distinct taxon_key from web.v_fact_data
  )
  select t.taxon_key, 
         t.scientific_name, 
         t.common_name, 
         t.commercial_group_id, 
         t.functional_group_id, 
         t.tl, 
         t.sl_max as sl_max_cm
    from web.cube_dim_taxon t
    join tax on (tax.taxon_key = t.taxon_key)
with no data;

  
create or replace function web.etl_validation_get_taxon_name 
(
  i_taxon_key int
)
returns varchar(50) as
$body$
  select ' [' || coalesce((select common_name from web.v_dim_taxon where taxon_key = i_taxon_key limit 1), '') || ']'; 
$body$
language sql;


create materialized view web.v_dim_time
as
  with active_time as (
    select distinct time_key from web.v_fact_data cad
  )
  select t.time_key, t.time_business_key
    from web.time t
    join active_time at on (at.time_key = t.time_key);

create materialized view web.v_functional_group
as
  select functional_group_id, name, description, target_grp
    from web.functional_groups
with no data;


create materialized view web.v_saup_jurisdiction
as
  select jurisdiction_id, name, legacy_c_number
    from web.jurisdiction
  with no data;


create materialized view web.v_web_taxon
as
  with tax as (
    select distinct taxon_key from web.v_fact_data
  )
  select t.taxon_key, 
         scientific_name, 
         common_name, 
         commercial_group_id, 
         functional_group_id, 
         tl, 
         sl_max as sl_max_cm, 
         taxon_level_id, 
         taxon_group_id, 
         isscaap_id, 
         lat_north, 
         lat_south, 
         min_depth, 
         max_depth, 
         loo, 
         woo, 
         k, 
         x_min,                                                                                 
         x_max, 
         y_min, 
         y_max, 
         has_habitat_index, 
         has_map, 
         is_baltic_only
    from web.cube_dim_taxon t
    join tax on (tax.taxon_key = t.taxon_key)
with no data;

