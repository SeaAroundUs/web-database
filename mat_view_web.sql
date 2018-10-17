/* materialzed views */
CREATE MATERIALIZED VIEW web.v_all_taxon AS
 SELECT t.taxon_key,
    t.scientific_name,
    t.common_name,
    t.commercial_group_id,
    t.functional_group_id,
    t.tl,
    t.sl_max AS sl_max_cm,
    t.taxon_level_id,
    t.taxon_group_id,
    t.isscaap_id,
    t.lat_north,
    t.lat_south,
    t.min_depth,
    t.max_depth,
    t.loo,
    t.woo,
    t.k,
    0 AS x_min,
    0 AS x_max,
    0 AS y_min,
    0 AS y_max,
    t.has_habitat_index,
    t.has_map,
    t.is_baltic_only,
    t.fb_spec_code,
    t.slb_spec_code,
    t.fam_code,
    t.ord_code,
    t.slb_fam_code,
    t.slb_ord_code,
    ( SELECT td.is_backfilled
           FROM distribution.taxon_distribution td
          WHERE td.taxon_key = t.taxon_key
         LIMIT 1) AS is_taxon_distribution_backfilled
   FROM cube_dim_taxon t;

/*
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
*/

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

/* BEGIN SORTIZ 10/12/18 */
create materialized view web.v_dim_end_use
as                    
  with end_use as (
    select distinct cad.end_use_type_id from web.v_fact_data cad
  )
  select eut.end_use_type_id, eut.end_use_name                               
    from web.end_use_type eut
    join end_use eu on (eu.end_use_type_id = eut.end_use_type_id)
with no data;
/* END SORTIZ 10/12/18 */

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
         0::INT AS x_min,                                                                                 
         0::INT AS x_max,       
         0::INT AS y_min, 
         0::INT AS y_max, 
         has_habitat_index, 
         has_map, 
         is_baltic_only
    from web.cube_dim_taxon t
    join tax on (tax.taxon_key = t.taxon_key)
with no data;

create materialized view web.v_eez_catch as
select vfd.main_area_id id,year, fe.name fishing_entity, e.name eez, vfd.sub_area_id fao_area_id ,cdt.scientific_name, cdt.common_name, st.name sector, ct.name catch_type, rs.name reporting_status, g.name gear, g.super_code gear_group, eut.end_use_name end_use_name, sum(catch_sum) catch, sum(real_value) landed_value
from web.v_fact_data vfd,
web.cube_dim_taxon cdt,
web.fishing_entity fe,
web.gear g,
web.eez e,
web.catch_type ct,
web.reporting_status rs,
web.sector_type st,
web.end_use_type eut
where marine_layer_id = 1
and cdt.taxon_key = vfd.taxon_key
and g.gear_id = vfd.gear_id
and e.eez_id = vfd.main_area_id
and fe.fishing_entity_id = vfd.fishing_entity_id
and ct.catch_type_id = vfd.catch_type_id
and rs.reporting_status_id = vfd.reporting_status_id
and st.sector_type_id = vfd.sector_type_id
and eut.end_use_type_id = vfd.end_use_type_id
group by vfd.main_area_id, year, fe.name, e.name, vfd.sub_area_id ,cdt.scientific_name, cdt.common_name, st.name , ct.name , rs.name , g.name, g.super_code, eut.end_use_name
union all
select vfd.sub_area_id id, year, fe.name fishing_entity, e.name eez, vfd.main_area_id fao_area_id, cdt.scientific_name, cdt.common_name, st.name sector, ct.name catch_type, rs.name reporting_status, g.name gear, g.super_code gear_group, eut.end_use_name end_use_name, sum(catch_sum) catch, sum(real_value) landed_value
from web.v_fact_data vfd,
web.cube_dim_taxon cdt,
web.fishing_entity fe,
web.gear g,
web.eez e,
web.catch_type ct,
web.reporting_status rs,
web.sector_type st,
web.end_use_type eut
where marine_layer_id = 2
and cdt.taxon_key = vfd.taxon_key
and g.gear_id = vfd.gear_id
and e.eez_id = vfd.sub_area_id
and fe.fishing_entity_id = vfd.fishing_entity_id
and ct.catch_type_id = vfd.catch_type_id
and rs.reporting_status_id = vfd.reporting_status_id
and st.sector_type_id = vfd.sector_type_id
and eut.end_use_type_id = vfd.end_use_type_id
group by vfd.sub_area_id, year, fe.name,  e.name, vfd.main_area_id, cdt.scientific_name, cdt.common_name, st.name , ct.name , rs.name , g.name, g.super_code, eut.end_use_name;
;

create materialized view web.v_meow_catch AS
select m.meow_id id, year, fe.name fishing_entity, m.name me, cdt.scientific_name, cdt.common_name, st.name sector, ct.name catch_type, rs.name reporting_status, g.name gear, g.super_code gear_group, eut.end_use_name end_use_name, sum(catch_sum) catch, sum(real_value) landed_value
from web.v_fact_data vfd,
web.cube_dim_taxon cdt,
web.fishing_entity fe,
web.gear g,
web.meow m,
web.catch_type ct,
web.reporting_status rs,
web.sector_type st,
web.end_use_type eut
where marine_layer_id = 19
and cdt.taxon_key = vfd.taxon_key
and g.gear_id = vfd.gear_id
and m.meow_id = vfd.main_area_id
and fe.fishing_entity_id = vfd.fishing_entity_id
and ct.catch_type_id = vfd.catch_type_id
and rs.reporting_status_id = vfd.reporting_status_id
and st.sector_type_id = vfd.sector_type_id
and eut.end_use_type_id = vfd.end_use_type_id
group by m.meow_id, year, fe.name, m.name, cdt.scientific_name, cdt.common_name, st.name , ct.name , rs.name , g.name, g.super_code, eut.end_use_name;

create materialized view web.v_lme_catch AS
select l.lme_id id, year, fe.name fishing_entity, l.name lme, cdt.scientific_name, cdt.common_name, st.name sector, ct.name catch_type, rs.name reporting_status, g.name gear, g.super_code gear_group, eut.end_use_name end_use_name, sum(catch_sum) catch, sum(real_value) landed_value
from web.v_fact_data vfd,
web.cube_dim_taxon cdt,
web.fishing_entity fe,
web.gear g,
web.lme l,
web.catch_type ct,
web.reporting_status rs,
web.sector_type st,
web.end_use_type eut
where marine_layer_id = 3
and l.lme_id = vfd.main_area_id
and cdt.taxon_key = vfd.taxon_key
and g.gear_id = vfd.gear_id
and fe.fishing_entity_id = vfd.fishing_entity_id
and ct.catch_type_id = vfd.catch_type_id
and rs.reporting_status_id = vfd.reporting_status_id
and st.sector_type_id = vfd.sector_type_id
and eut.end_use_type_id = vfd.end_use_type_id
group by l.lme_id, year, fe.name, l.name, vfd.sub_area_id ,cdt.scientific_name, cdt.common_name, st.name , ct.name , rs.name , g.name, g.super_code, eut.end_use_name;

create materialized view web.v_rfmo_catch AS
select r.rfmo_id id, year, fe.name fishing_entity, r.name rfmo,cdt.scientific_name, cdt.common_name, st.name sector, ct.name catch_type, rs.name reporting_status, g.name gear, g.super_code gear_group, sum(catch_sum) catch, sum(real_value) landed_value
from web.v_fact_data vfd,
web.cube_dim_taxon cdt,
web.fishing_entity fe,
web.gear g,
web.rfmo r,
web.catch_type ct,
web.reporting_status rs,
web.sector_type st
where marine_layer_id = 4
and r.rfmo_id = vfd.main_area_id
and cdt.taxon_key = vfd.taxon_key
and g.gear_id = vfd.gear_id
and fe.fishing_entity_id = vfd.fishing_entity_id
and ct.catch_type_id = vfd.catch_type_id
and rs.reporting_status_id = vfd.reporting_status_id
and st.sector_type_id = vfd.sector_type_id
group by r.rfmo_id, year, fe.name, r.name,cdt.scientific_name, cdt.common_name, st.name , ct.name , rs.name , g.name, g.super_code;


/*
The command below should be maintained as the last command in this entire script.
*/
SELECT admin.grant_access();

