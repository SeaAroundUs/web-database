CREATE OR REPLACE FUNCTION geo.lookup_area_key_eez_immediate_neighbors(i_eez_id int)
RETURNS TABLE(area_id_reference int, area_id_bucket int[]) AS
$body$
  with ref_eez(eez_id, geom) as (
    select ez.eez_id, ez.wkb_geometry 
      from geo.eez ez
     where ez.eez_id = i_eez_id
  ),
  neighbors(eez_ids) as (
    select array_agg(e.eez_id) 
      from geo.eez e
      join ref_eez re on (st_intersects(re.geom, e.wkb_geometry))
     where e.eez_id != i_eez_id
  )
  select re.eez_id, re.eez_id || (select eez_ids from neighbors) 
    from ref_eez re;
$body$
LANGUAGE sql;

create or replace function geo.shift_geom_around_idl(i_geom geometry) 
returns geometry as
$body$
declare
  comp_geom geometry;
  extents box2d;
begin
  for comp_geom in select t.geom from st_dump(i_geom) as t order by st_area(t.geom) desc limit 1 loop
    extents := st_extent(comp_geom);
    
    if (st_xmin(extents) >= 180) then
      return st_translate(st_shift_longitude(i_geom), 360, 0); 
    else
      return st_translate(st_shift_longitude(i_geom), -360, 0); 
    end if;
  end loop;
end
$body$
language plpgsql;

CREATE OR REPLACE FUNCTION geo.insert_high_seas(i_fao_area_id int)
RETURNS SETOF geo.high_seas AS
$body$
declare
  fao_geom geometry;
  eez_geom geometry;
  fid int;
  ogc_fids int[];
begin
  select geom into fao_geom from geo.fao where fao_area_id = i_fao_area_id;
  
  if found then
    select array_agg(e.ogc_fid) 
      into ogc_fids
      from geo.fao f 
      join geo.eez e on (st_intersects(e.wkb_geometry, f.geom)) 
     where f.fao_area_id = i_fao_area_id;
    
    for eez_geom in select e.wkb_geometry from geo.eez e where e.ogc_fid = any(ogc_fids) loop
      fao_geom := st_difference(fao_geom, eez_geom);
    end loop;
    
    return query
    insert into geo.high_seas(fao_area_id, eez_ogc_fid_intersects, geom)
    values(i_fao_area_id, ogc_fids, st_multi(st_collectionextract(fao_geom, 3)))
    returning *;
  end if;
end
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION geo.insert_high_seas_via_union(i_fao_area_id int)
RETURNS SETOF geo.high_seas AS
$body$
declare
  eez_geom geometry;
  ogc_fids int[];
begin
  select st_union(st_buffer(e.wkb_geometry, 0.0000001::double precision)), array_agg(e.ogc_fid) 
    into eez_geom, ogc_fids
    from geo.fao f 
    join geo.eez e on (st_intersects(e.wkb_geometry, f.geom)) 
   where f.fao_area_id = i_fao_area_id
   group by f.fao_area_id;
  
  if found then
    return query
    insert into geo.high_seas(fao_area_id, eez_ogc_fid_intersects, geom)
    select i_fao_area_id, ogc_fids, st_multi(st_collectionextract(st_difference(f.geom, eez_geom), 3)) from geo.fao f where f.fao_area_id = i_fao_area_id
    returning *;
  end if;
end
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION geo.delete_high_seas_fragments(i_fao_area_id int)
RETURNS VOID AS
$body$
  with hs_filter(geom) as (
    select st_union(st_makevalid(t.geom)) 
      from (select (st_dump(h.geom)).* from geo.high_seas h where h.fao_area_id = i_fao_area_id) as t 
     where st_area(t.geom) > 10.0
  )
  update geo.high_seas h 
     set geom = st_multi(st_collectionextract(hf.geom, 3))
    from hs_filter hf 
   where h.fao_area_id = i_fao_area_id;
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION geo.insert_ifa(i_eez_id int, i_geom geometry)
RETURNS VOID AS
$body$
  insert into geo.ifa(object_id, eez_id, c_name, a_name, a_num, area_km2, shape_leng, shape_area, geom) 
  select (select max(i2.object_id)+1 from geo.ifa i2), e.eez_id, e.name, lc.country, e.legacy_c_number, 
         st_area(i_geom::geography)/1000000.0, st_perimeter(i_geom), st_area(i_geom), st_multi(i_geom) 
   from web.eez e, web.country lc 
  where e.legacy_c_number = lc.c_number
    and e.eez_id = i_eez_id;
$body$
language sql;

CREATE OR REPLACE FUNCTION geo.insert_eez(i_eez_id int, i_geom geometry)
RETURNS VOID AS
$body$
  insert into geo.eez(eez_id, shape_length, shape_area, wkb_geometry) 
  select i_eez_id, st_perimeter(i_geom), st_area(i_geom), st_multi(i_geom);
$body$
language sql;

CREATE OR REPLACE FUNCTION geo.geom_idl_reflect(i_geom geometry(Multipolygon, 4326), i_direction smallint default -1)
RETURNS geometry(Multipolygon, 4326) AS
$body$
  select st_multi(st_union(i_geom, st_translate(i_geom, i_direction * 360, 0)));
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION geo.insert_geo_area_with_eez(i_area_key int)
RETURNS VOID AS
$body$
DECLARE
  area_geom geometry(MultiPolygon, 4326) := null;
  area_m2 numeric := null;
  ifa_area_geom geometry(MultiPolygon, 4326) := null;
  ifa_area_m2 numeric := null;
BEGIN
  select st_multi(st_collectionextract(st_intersection(e.wkb_geometry, f.geom), 3))
    into area_geom
    from web.area a
    join geo.eez e on (e.eez_id = a.main_area_id)
    join geo.fao f on (f.fao_area_id = a.sub_area_id)
   where a.area_key = i_area_key
     and a.marine_layer_id = 1;
  
  if found then
    begin
      area_m2 := st_area(area_geom::geography);
    exception
    when others then
      area_m2 := st_area(area_geom::geography, false);
    end;
    
    begin
      select st_multi(st_collectionextract(st_intersection(i.geom, f.geom), 3))
        into ifa_area_geom
        from web.area a
        join geo.ifa i on (i.eez_id = a.main_area_id)
        join geo.fao f on (f.fao_area_id = a.sub_area_id)
       where a.area_key = i_area_key;
     
      if found then
        begin
          ifa_area_m2 := st_area(ifa_area_geom::geography);
        exception
        when others then
          ifa_area_m2 := st_area(ifa_area_geom::geography, false);
        end;
      end if;
    exception
      when others then
        ifa_area_geom := null;
        ifa_area_m2 := null;
    end;
    
    insert into geo.area(area_key, area_km2, geom, ifa_area_km2, ifa_geom)
    values (i_area_key, area_m2/1000000.0, area_geom, ifa_area_m2/1000000.0, ifa_area_geom);
  end if;
END
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION geo.insert_geo_area_with_lme(i_area_key int)
RETURNS VOID AS
$body$
DECLARE
  area_geom geometry(MultiPolygon, 4326) := null;
  area_m2 numeric := null;
BEGIN
  select st_multi(st_collectionextract(st_intersection(l.geom, f.geom), 3))
    into area_geom
    from web.area a
    join geo.lme l on (l.lme_number = a.main_area_id)
    join geo.fao f on (f.fao_area_id = a.sub_area_id)
   where a.area_key = i_area_key
     and a.marine_layer_id = 3;
  
  if found then
    begin
      area_m2 := st_area(area_geom::geography);
    exception
    when others then
      area_m2 := st_area(area_geom::geography, false);
    end;
    
    insert into geo.area(area_key, area_km2, geom, ifa_area_km2, ifa_geom)
    values (i_area_key, area_m2/1000000.0, area_geom, null, null);
  end if;
END
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION geo.insert_geo_v_global()
RETURNS VOID AS
$body$
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
  insert into geo.v_global(id,title,area,shelf_area,ifa,coral_reefs,sea_mounts,ppr,geom_geojson)
  select 1 as id,
         'Global'::varchar(254) as title,
         a.*,
         (select st_asgeojson(st_simplify(st_union(st_buffer(f.geom, 0.0000001::double precision)), 0.02::double precision), 3) from geo.fao as f)::json as geom_geojson
    from areas a;
$body$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION geo.update_web_area_total_area(i_marine_layer_id int)
RETURNS VOID AS
$body$
BEGIN
  IF i_marine_layer_id = 1 THEN
    UPDATE web.area a SET area = st_area(st_intersection(g.wkb_geometry, f.geom)::geography) FROM geo.eez g, geo.fao f WHERE a.marine_layer_id = i_marine_layer_id AND a.main_area_id = g.eez_id AND a.sub_area_id = f.fao_area_id;
  ELSIF i_marine_layer_id = 2 THEN
    UPDATE web.area a SET area = st_area(g.geom::geography) FROM geo.high_seas g WHERE a.marine_layer_id = i_marine_layer_id AND a.main_area_id = g.fao_area_id;
  ELSIF i_marine_layer_id = 3 THEN
    UPDATE web.area a SET area = st_area(g.geom::geography) FROM geo.lme g WHERE a.marine_layer_id = i_marine_layer_id AND a.main_area_id = g.lme_number;
  END IF;
END
$body$
LANGUAGE plpgsql;
