drop materialized view geo.v_eez;

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

refresh materialized view geo.v_eez;

CREATE UNIQUE INDEX v_eez_id_idx ON geo.v_eez(id);
CREATE INDEX v_eez_fishbase_id_idx ON geo.v_eez(fishbase_id);

select admin.grant_access();
