create materialized view geo.v_high_seas
as
  select w.fao_area_id as id,
         w.name as title,
         f.f_level,
         f.ocean,
         f.sub_ocean,
         a.area,
         a.shelf_area,
         a.ifa,
         a.coral_reefs,
         a.sea_mounts,
         a.ppr,
         st_simplify(h.geom, 0.05::double precision) as geom,
         st_asgeojson(st_simplify(h.geom, 0.02::double precision), 3)::json as geom_geojson
    from geo.high_seas h
    join web.fao_area w on (w.fao_area_id = h.fao_area_id)
    join geo.fao f on (f.fao_area_id = h.fao_area_id)
    join web.area a on (a.main_area_id = h.fao_area_id and a.marine_layer_id = 2)
with no data;

/* This view is no longer in use, but is left here as sample code
create materialized view geo.v_global
as
  -- This is global, so there's no need to calculate coral_reefs and sea_mounts percentage
  with areas(area, shelf_area, ifa, coral_reefs, sea_mounts, ppr) as (
    select sum(a.area),
           sum(a.shelf_area),
           sum(a.ifa),
           100.0,  
           100.0,
           sum(a.ppr * a.area)/sum(a.area)
      from web.area a
     where a.marine_layer_id in (1, 2)
  )
  select 1 as id,
         'Global'::varchar(254) as title,
         a.*,
         (select st_asgeojson(st_simplify(st_union(st_buffer(f.geom, 0.0000001::double precision)), 0.02::double precision), 3) from geo.fao as f)::json as geom_geojson
    from areas a
with no data;
*/

create materialized view geo.v_lme
as
  select max(wl.lme_id) as id,
         max(wl.name::text) as title,
         ('http://www.fishbase.org/trophiceco/FishEcoList.php?ve_code=' || max(lfl.e_code)) as fishbase_link,
         sum(a.area) as area,
         sum(a.shelf_area) as shelf_area,
         sum(a.ifa) as ifa,
         sum(a.coral_reefs) as coral_reefs,
         sum(a.sea_mounts) as sea_mounts,
         sum(a.ppr) as ppr,
         st_asgeojson(st_simplify(st_union(gl.geom), 0.02::double precision), 3)::json as geom_geojson
    from geo.lme gl
    join web.lme wl on (gl.lme_number = wl.lme_id)
    join web.area a on (wl.lme_id = a.main_area_id and a.marine_layer_id = 3)
    left join web.lme_fishbase_link lfl on (lfl.lme_id = wl.lme_id)
   group by wl.lme_id
with no data;

create materialized view geo.v_ifa                
as
  select i.eez_id,
         max(i.a_name) AS admin_title,
         max(i.a_num) AS admin_c_number,
         sum(i.area_km2) AS area,
         sum(i.shape_leng) AS shape_length,
         sum(i.shape_area) AS shape_area,
         st_asgeojson(st_simplify(st_union(i.geom), 0.02::double precision), 3)::json as geom_geojson
    from geo.ifa i
    join web.eez e on (e.eez_id = i.eez_id)
   group by i.eez_id
with no data;

create materialized view geo.v_fao                
as
  select f.fao_area_id,
         w.name AS title,
         w.alternate_name AS alternate_title,
         f.ocean,
         f.sub_ocean,
         0::numeric AS area,
         0::numeric AS shape_length,
         0::numeric AS shape_area,
         st_asgeojson(st_simplify(f.geom, 0.02::double precision), 3)::json as geom_geojson
    from geo.fao f
    join web.fao_area w on (w.fao_area_id = f.fao_area_id)
with no data;

create materialized view geo.v_rfmo                  
as
  select d.rfmo_id as id,
         max(d.name::text) as title,
         max(d.long_name::text) as long_title,
         max(d.profile_url::text) as profile_url,
         sum(a.area) as area,
         sum(a.shelf_area) as shelf_area,
         sum(a.ifa) as ifa,
         sum(a.coral_reefs) as coral_reefs,
         sum(a.sea_mounts) as sea_mounts,
         sum(a.ppr * a.area)/sum(a.area) as ppr,
         st_asgeojson(st_simplify(st_union(e.geom), 0.02::double precision), 3)::json as geom_geojson
    from web.rfmo d
    join geo.rfmo e on (e.rfmo_id = d.rfmo_id)
    join web.area a on (a.main_area_id = d.rfmo_id and a.marine_layer_id = 4)
   group by d.rfmo_id
with no data;

create materialized view geo.v_mariculture_entity(
  mariculture_entity_id,
  name,
  c_number,
  c_iso_code,
  fao_link, 
  geom_geojson
) as
  with me_sub_unit as (
    select distinct eez_id, sub_unit, geom from geo.mariculture_entity g
  ),
  mgeo(mariculture_entity_id, geom) as (
    select me.mariculture_entity_id, st_union(g.geom)
      from me_sub_unit g
      join web.eez e on (e.eez_id = g.eez_id)
      join web.mariculture_entity me on (me.legacy_c_number = e.legacy_c_number)
     group by me.mariculture_entity_id
  )
  select me.mariculture_entity_id, me.name, me.legacy_c_number, lc.country, me.fao_link, 
         st_asgeojson(st_multi(st_simplify(g.geom, 0.02::double precision)), 3)::json 
    from web.mariculture_entity me
    join web.country lc on (lc.c_number = me.legacy_c_number)
    left join mgeo g on (g.mariculture_entity_id = me.mariculture_entity_id)
with no data;

create materialized view geo.v_sub_mariculture_entity(
  mariculture_entity_id,
  c_number,
  c_iso_code,
  fao_link, 
  sub_unit_id, 
  sub_unit_name, 
  total_production, 
  latitude,
  longitude,
  geom_geojson,
  point_geojson
) as
  with dat(mariculture_sub_entity_id, production) as (
    select md.mariculture_sub_entity_id, sum(md.production)/10.0
      from web.mariculture_data md 
     where md.year between 2000 and 2010  
     group by md.mariculture_sub_entity_id
  ),
  subunits(mariculture_sub_entity_id, geom) as (
    select se.mariculture_sub_entity_id, st_union(m.geom)
      from web.mariculture_entity me
      join web.mariculture_sub_entity se on (se.mariculture_entity_id = me.mariculture_entity_id)
      join geo.mariculture m on (m.c_number = me.legacy_c_number and m.sub_unit = se.name)
     group by se.mariculture_sub_entity_id
  ),
  points(mariculture_sub_entity_id, long, lat, geom) as (
    select se.mariculture_sub_entity_id, max(p.long), max(p.lat), st_union(p.geom)
      from web.mariculture_sub_entity se
      join geo.mariculture_points p on (p.sub_entity_id = se.mariculture_sub_entity_id)
     group by se.mariculture_sub_entity_id
  )
  select me.mariculture_entity_id, me.legacy_c_number, lc.country, me.fao_link, se.mariculture_sub_entity_id, se.name, d.production, p.lat, p.long, 
         st_asgeojson(st_multi(st_simplify(s.geom, 0.02::double precision)), 3)::json, 
         st_asgeojson(st_multi(st_simplify(p.geom, 0.02::double precision)), 3)::json
    from web.mariculture_entity me
    join web.mariculture_sub_entity se on (se.mariculture_entity_id = me.mariculture_entity_id)
    join web.country lc on (lc.c_number = me.legacy_c_number)
    left join dat d on (d.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
    left join subunits s on (s.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
    left join points p on (p.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
with no data;

create materialized view geo.v_area                  
as
  select g.area_key as id,
         a.marine_layer_id,
         a.main_area_id,
         a.sub_area_id,
         a.area,
         a.shelf_area,
         a.ifa,
         a.coral_reefs,
         a.sea_mounts,
         a.ppr,
         st_asgeojson(st_simplify(g.geom, 0.02::double precision), 3)::json as geom_geojson
    from web.area a
    join geo.area g on (g.area_key = a.area_key)
  union all
  select a.area_key as id,
         a.marine_layer_id,
         a.main_area_id,
         a.sub_area_id,
         a.area,
         a.shelf_area,
         a.ifa,
         a.coral_reefs,
         a.sea_mounts,
         a.ppr,
         (case a.sub_area_id
          when 1 then (select row_to_json(fc)
                         from (select 'FeatureCollection' as type, array_to_json(array_agg(f)) as features
                                 from (select 'Feature' as type,  
                                              json_build_object('eez_id', g.eez_id) as properties,  
                                              st_asgeojson(st_simplify(g.wkb_geometry, 0.02::double precision), 3)::json as geometry
                                         from geo.eez as g) as f 
                              ) as fc
                       )
          when 2 then (select st_asgeojson(st_simplify(st_union(st_buffer(h.geom, 0.0000001::double precision)), 0.02::double precision), 3)::json 
                         from geo.high_seas h)
          end) as geom_geojson
    from web.area a
   where a.marine_layer_id = 6
with no data;

create materialized view geo.v_eez(
  id,
  title,
  c_number,
  c_name,
  geo_entity_id,
  area,
  shelf_area,    
  ifa,
  coral_reefs,
  sea_mounts,
  ppr,
  geom_geojson,
  fishbase_id,
  ohi_link,
  intersecting_fao_area_id,
  year_started_eez_at,
  year_allowed_to_fish_other_eezs,
  year_allowed_to_fish_high_seas,
  declaration_year
)
as
  with ee(id,title,c_number,declaration_year,area,shelf_area,ifa,coral_reefs,sea_mounts,ppr,fishbase_id,ohi_link,geo_entity_id) as (
    select d.eez_id,
           max(d.name::text),
           max(d.legacy_c_number),
           max(d.declaration_year),
           coalesce(sum(a.area), 0.0),
           coalesce(sum(a.shelf_area), 0.0),
           coalesce(sum(a.ifa), 0.0),
           coalesce(sum(a.coral_reefs), 0.0),
           coalesce(sum(a.sea_mounts), 0.0),
           coalesce(sum(a.ppr * a.area)/sum(a.area), 0.0),
           max(d.fishbase_id),
           max(d.ohi_link),
           max(d.geo_entity_id) as geo_entity_id
      from web.eez d
      left join web.area a on (a.main_area_id = d.eez_id and a.marine_layer_id = 1)
     group by d.eez_id
  )                       
  select ee.id,ee.title,ee.c_number,c.country,
         case
         when exists (select 1 from web.subsidy s where s.geo_entity_id = ee.geo_entity_id limit 1) then ee.geo_entity_id 
         when exists (select 1 from web.subsidy s where s.geo_entity_id = ge.admin_geo_entity_id limit 1) then ge.admin_geo_entity_id
         else ee.geo_entity_id
         end,
         ee.area,ee.shelf_area,ee.ifa,ee.coral_reefs,ee.sea_mounts,ee.ppr,
         st_asgeojson(st_multi(st_simplify(e.wkb_geometry, 0.02::double precision)), 3)::json,
         ee.fishbase_id,ee.ohi_link,
         (select array_agg(distinct f.fao_area_id) from web.area a, web.fao_area f where a.marine_layer_id=1 and a.main_area_id = ee.id and a.area_key = any(f.area_key)),
         coalesce(ge.started_eez_at::int, 9999),
         (case when fe2.geo_entity_id is not null then fe2.date_allowed_to_fish_other_eezs
               when fe3.geo_entity_id is not null then fe3.date_allowed_to_fish_other_eezs
               else 9999
           end),
         (case when fe2.geo_entity_id is not null then fe2.date_allowed_to_fish_high_seas
               when fe3.geo_entity_id is not null then fe3.date_allowed_to_fish_high_seas
               else 9999
           end),
         ee.declaration_year
    from ee
    join geo.eez e on (e.eez_id = ee.id)
    join web.country c on (c.c_number = ee.c_number)
    join web.geo_entity ge on (ge.geo_entity_id = ee.geo_entity_id)
    left join web.fishing_entity fe2 on (fe2.geo_entity_id = ge.geo_entity_id and fe2.is_currently_used_for_web)
    left join web.fishing_entity fe3 on (fe3.geo_entity_id = ge.admin_geo_entity_id)
with no data;

create materialized view geo.v_country                  
as
  select nc.gid as id,
         nc.name::text as title,
         lc.c_number,
         nc.iso_a3 c_iso_code,
         st_asgeojson(st_simplify(nc.geom, 0.02::double precision), 3)::json as geom_geojson
    from geo.ne_country nc
    left join web.country lc on (lc.c_number = nc.c_number)
with no data;
