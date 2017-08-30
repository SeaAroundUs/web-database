INSERT INTO web.entity_layer (entity_layer_id, name) VALUES (1100, 'gear type');

-----------------------
-- DOWNLOADABLE DATA --
-----------------------

DROP FUNCTION web.f_catch_query_for_csv(integer[],integer[],integer,integer,json);

-----------------
-- helper functions
create or replace function web.get_csv_headings 
(
  i_entity_layer_id int
)
returns text as
$body$
  select array_to_string(
           case when i_entity_layer_id = 6 
           then array['year']::text[] 
           else array['area_name', 'area_type']::text[] || 
                case when i_entity_layer_id = 1 then array['data_layer', 'uncertainty_score']::text[] else null::text[] end || 
                array['year', 'scientific_name', 'common_name', 'functional_group', 'commercial_group']::text[] 
           end ||
           case when i_entity_layer_id is distinct from 100 then array['fishing_entity']::text[] else array[]::text[] end ||
           array['fishing_sector','catch_type', 'reporting_status', 'gear_type', 'tonnes', 'landed_value'],
           ',');
$body$
language sql;

create or replace function web.get_csv_column_list
(
  i_entity_layer_id int,
  i_include_sum boolean
)
returns text as
$body$
  select 'f.year,' || 
         case when i_entity_layer_id is distinct from 6 then 'f.taxon_key,' else 'null::int,' end ||
         case when i_entity_layer_id is distinct from 100 then 'f.fishing_entity_id,' else 'null::smallint,' end || 
         case when i_entity_layer_id = 1 then 'f.data_layer_id::smallint,' else 'null::smallint,' end ||
         'f.sector_type_id,f.catch_status,f.reporting_status,f.gear_type_id' || 
         case when i_include_sum then ', sum(f.catch_sum)::numeric(20,10), sum(f.real_value)' else '' end;
$body$
language sql;

-----------------
create or replace function web.f_dimension_catch_query_layer_preprocessor_for_csv
(
  i_entity_layer_id int,
  i_area_bucket_id_layer int, 
  i_other_params json
)
returns table(main_area_col_name text, additional_join_clause text) as
$body$
declare
  main_area_col_name text;
  additional_join_clause text := '';
  managed_species_type varchar(20);
begin
  case 
    when i_entity_layer_id = 6 then
      main_area_col_name := 'null::int,null::int,';
    when i_entity_layer_id < 100 then 
      main_area_col_name := 'f.main_area_id,';
      
      /* Special consideration for RFMO */
      if i_entity_layer_id = 4 then
        if coalesce((json_object_field_text(i_other_params, 'managed_species_only'))::boolean, false) then
          managed_species_type := coalesce(lower(json_object_field_text(i_other_params, 'managed_species_type')), 'all');
          case managed_species_type
          when 'primary' then
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.primary_taxon_keys)))';
          when 'secondary' then
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.secondary_taxon_keys)))';
          else
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.primary_taxon_keys || mt.secondary_taxon_keys)))';
          end case;
        end if;
      end if;
    when i_entity_layer_id = 100 then 
      main_area_col_name := 'f.main_area_id,f.marine_layer_id,';
    when i_entity_layer_id = 200 then 
      main_area_col_name := 'ab.area_bucket_id,';
      
      if i_area_bucket_id_layer = 400 then
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.area_key = any(ab.area_id_bucket))';
      else
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.main_area_id = any(ab.area_id_bucket) and f.marine_layer_id = ' || i_area_bucket_id_layer || ')';
      end if;
    when i_entity_layer_id = 300 then                                           
      main_area_col_name := 'f.main_area_id,f.marine_layer_id,';
    when i_entity_layer_id = 400 then
      main_area_col_name := 'f.area_key,';
    when i_entity_layer_id = 500 then
      main_area_col_name := 'wt.commercial_group_id,';
      additional_join_clause := ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)';
    when i_entity_layer_id = 600 then
      main_area_col_name := 'wt.functional_group_id,';
      additional_join_clause := ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)';
    when i_entity_layer_id = 700 then
      main_area_col_name := 'f.reporting_status,';
    when i_entity_layer_id = 800 then
      main_area_col_name := 'f.catch_status,';
    when i_entity_layer_id = 900 then
      main_area_col_name := 'fa.fao_area_id,';
      additional_join_clause := additional_join_clause || ' join web.fao_area fa on (fa.fao_area_id = any($1) and f.area_key = any(fa.area_key))';
    when i_entity_layer_id = 1100 then
      main_area_col_name := 'f.gear_type,';
    else
      raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;
                                                                               
  return query select main_area_col_name, additional_join_clause;
end
$body$
language plpgsql;

create or replace function web.f_catch_query_for_csv 
(
  i_entity_id int[],
  i_sub_entity_id int[],            
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_other_params json default null
)
returns table(entity_id int, 
              entity_layer_id int, 
              year int, 
              taxon int, 
              fishing_entity smallint, 
              data_layer_id smallint, 
              fishing_sector smallint, 
              catch_status char(1), 
              reporting_status char(1),
              gear_type_id int,
              catch_sum numeric, 
              real_value double precision) as
$body$
declare
  rtn_sql text;                                              
  main_area_col_name text;
  additional_join_clause text := '';
begin
  select *
    into main_area_col_name, additional_join_clause
    from web.f_dimension_catch_query_layer_preprocessor_for_csv(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);
                                                                                                                                                                                         
  rtn_sql := 
    'select ' || main_area_col_name ||
    case when i_entity_layer_id in (6, 100, 300) then '' else i_entity_layer_id || ',' end ||
    web.get_csv_column_list(i_entity_layer_id, true) ||  
    ' from web.v_fact_data f' || 
    additional_join_clause ||                   
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' f.marine_layer_id = ' || i_entity_layer_id || ' and f.main_area_id = any($1) and'
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then ' f.taxon_key = any($1) and'
    else ''
     end ||
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by ' || main_area_col_name || web.get_csv_column_list(i_entity_layer_id, false);
  
  -- DEBUG ONLY
  --raise info 'f_catch_query_for_csv rtn_sql: %', rtn_sql;
  
  return query execute rtn_sql                 
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;
------

------
create or replace function web.f_catch_data_in_csv
(
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[],                             
  i_other_params json default null
)
returns setof text as            
$body$
begin
  if i_entity_layer_id = 4 and array_upper(i_entity_id, 1) = 1 then
    if exists (select 1 from schema_v('web_cache') where table_name = format('catch_csv_%s_%s', i_entity_layer_id, i_entity_id[1]) and ds_raw > 0 limit 1) then
      return query
      select csv_data from web.catch_data_in_csv_cache where entity_layer_id = i_entity_layer_id and entity_id = i_entity_id[1] order by seq;
      return;
    end if;
  end if;
  
  return query
  with catch as (
    select c.*
      from web.f_catch_query_for_csv(i_entity_id, i_sub_entity_id, i_entity_layer_id, case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end, i_other_params) as c
  ),
  uncertainty as (
    select ue.eez_id, ue.sector_type_id, ue.score, utp.year_range
      from web.uncertainty_eez ue  
      join web.uncertainty_time_period utp on (utp.period_id = ue.period_id)
     where i_entity_layer_id = 1 
       and ue.eez_id = any(i_entity_id)
  ) 
  (select web.get_csv_headings(i_entity_layer_id) where exists (select 1 from catch limit 1))
  union all
  --
  -- Global 
  --   global should NOT include area id/area type. in fact, this is the only format that does not include area id/name
  --
  (select concat_ws(',', c.year::varchar, csv_escape(fe.name), st.name, cs.name, cr.name, g.name, c.catch_sum::varchar, c.real_value::varchar)
     from catch c
     join web.fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity)
     join web.sector_type st on (st.sector_type_id = c.fishing_sector)
     join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
     join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
     join web.gear g on (g.gear_id = c.gear_type_id)
    where i_entity_layer_id = 6
    order by c.year, c.fishing_entity, c.fishing_sector, c.catch_status, c.reporting_status, c.gear_type_id)
  union all
  --
  -- Fishing Entity 
  --   for fishing entity as input, fishing entity column shouldn't be shown in the download file
  --   we need to have one single row per year for All of High_seas, but break out separate row per year/eez combination
  --
  (select tsv                                      
     from ((select c.year, c.entity_layer_id, c.entity_id, concat_ws(',', csv_escape(e.name), 'eez', c.year::varchar, csv_escape(t.scientific_name), csv_escape(t.common_name), csv_escape(fg.description), csv_escape(cg.name), st.name, cs.name, cr.name, c.catch_sum::varchar, c.real_value::varchar) as tsv
              from catch c
              join web.eez e on (e.eez_id = c.entity_id)
              join web.cube_dim_taxon t on (t.taxon_key = c.taxon)
              join web.functional_groups fg on (fg.functional_group_id = t.functional_group_id)
              join web.commercial_groups cg on (cg.commercial_group_id = t.commercial_group_id)
              join web.sector_type st on (st.sector_type_id = c.fishing_sector)
              join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
              join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
              join web.gear g on (g.gear_id = c.gear_type_id)
             where c.entity_layer_id = 1 and i_entity_layer_id = 100)
           union all
           (select c.year, 2, 1, concat_ws(',', 'All', 'high_seas', c.year::varchar, csv_escape(max(t.scientific_name)), csv_escape(max(t.common_name)), csv_escape(max(fg.description)), csv_escape(max(cg.name)), max(st.name), max(cs.name), max(cr.name), sum(c.catch_sum)::varchar, sum(c.real_value)::varchar)
              from catch c
              join web.cube_dim_taxon t on (t.taxon_key = c.taxon)
              join web.functional_groups fg on (fg.functional_group_id = t.functional_group_id)
              join web.commercial_groups cg on (cg.commercial_group_id = t.commercial_group_id)
              join web.sector_type st on (st.sector_type_id = c.fishing_sector)
              join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
              join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
              join web.gear g on (g.gear_id = c.gear_type_id)
             where c.entity_layer_id = 2 and i_entity_layer_id = 100
             group by c.year, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_sector, c.catch_status, c.reporting_status, c.gear_type_id)) as d
    order by d.year, d.entity_layer_id, d.entity_id
  )
  union all
  --
  -- Taxon 
  --   we need to have one single row per year for All of High_seas, but break out separate row per year/eez combination
  --
  (select tsv                                      
     from ((select c.year, c.entity_layer_id, c.entity_id, concat_ws(',', csv_escape(e.name), 'eez', c.year::varchar, csv_escape(t.scientific_name), csv_escape(t.common_name), csv_escape(fg.description), csv_escape(cg.name), csv_escape(fe.name), st.name, cs.name, cr.name, c.catch_sum::varchar, c.real_value::varchar) as tsv
              from catch c
              join web.eez e on (e.eez_id = c.entity_id)
              join web.cube_dim_taxon t on (t.taxon_key = c.taxon)
              join web.functional_groups fg on (fg.functional_group_id = t.functional_group_id)
              join web.commercial_groups cg on (cg.commercial_group_id = t.commercial_group_id)
              join web.fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity)
              join web.sector_type st on (st.sector_type_id = c.fishing_sector)
              join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
              join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
              join web.gear g on (g.gear_id = c.gear_type_id)
             where c.entity_layer_id = 1 and i_entity_layer_id = 300)
           union all
           (select c.year, 2, 1, concat_ws(',', 'All', 'high_seas', c.year::varchar, csv_escape(max(t.scientific_name)), csv_escape(max(t.common_name)), csv_escape(max(fg.description)), csv_escape(max(cg.name)), csv_escape(max(fe.name)), max(st.name), max(cs.name), max(cr.name), sum(c.catch_sum)::varchar, sum(c.real_value)::varchar)
              from catch c
              join web.cube_dim_taxon t on (t.taxon_key = c.taxon)
              join web.functional_groups fg on (fg.functional_group_id = t.functional_group_id)
              join web.commercial_groups cg on (cg.commercial_group_id = t.commercial_group_id)
              join web.fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity)
              join web.sector_type st on (st.sector_type_id = c.fishing_sector)
              join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
              join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
              join web.gear g on (g.gear_id = c.gear_type_id)
             where c.entity_layer_id = 2 and i_entity_layer_id = 300
             group by c.year, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_sector, c.catch_status, c.reporting_status, c.gear_type_id)) as d
    order by d.year, d.entity_layer_id, d.entity_id
  )
  union all
  --
  -- EEZ 
  --   any other spatial entity layer beside (6, 100, 300) which needs to return Data_layer_id as well
  --
  (select concat_ws(',', csv_escape(el.name), el.layer_name, dl.name, coalesce(u.score::varchar, ''), c.year::varchar, csv_escape(t.scientific_name), csv_escape(t.common_name), csv_escape(fg.description), csv_escape(cg.name), csv_escape(fe.name), st.name, cs.name, cr.name, c.catch_sum::varchar, c.real_value::varchar)
     from catch c
     join web.cube_dim_taxon t on (t.taxon_key = c.taxon)
     join web.functional_groups fg on (fg.functional_group_id = t.functional_group_id)
     join web.commercial_groups cg on (cg.commercial_group_id = t.commercial_group_id)
     join web.fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity)
     join web.sector_type st on (st.sector_type_id = c.fishing_sector)
     join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
     join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
     join web.gear g on (g.gear_id = c.gear_type_id)
     join web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as el on (el.entity_id = c.entity_id)
     join web.data_layer dl on (dl.data_layer_id = c.data_layer_id)
     left join uncertainty u on (u.eez_id = c.entity_id and u.sector_type_id = c.fishing_sector and u.year_range @> c.year and c.data_layer_id = 1)
    where i_entity_layer_id = 1
    order by c.year, dl.data_layer_id, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_entity, c.fishing_sector, c.catch_status, c.reporting_status, c.gear_type_id)
  union all
  --
  -- All other entity layers
  --   
  (select concat_ws(',', csv_escape(el.name), el.layer_name, c.year::varchar, csv_escape(t.scientific_name), csv_escape(t.common_name), csv_escape(fg.description), csv_escape(cg.name), csv_escape(fe.name), st.name, cs.name, cr.name, c.catch_sum::varchar, c.real_value::varchar)
     from catch c
     join web.cube_dim_taxon t on (t.taxon_key = c.taxon)
     join web.functional_groups fg on (fg.functional_group_id = t.functional_group_id)
     join web.commercial_groups cg on (cg.commercial_group_id = t.commercial_group_id)
     join web.fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity)
     join web.sector_type st on (st.sector_type_id = c.fishing_sector)
     join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
     join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
     join web.gear g on (g.gear_id = c.gear_type_id)
     join web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as el on (el.entity_id = c.entity_id)
    where i_entity_layer_id not in (1, 6, 100, 300)
    order by c.year, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_entity, c.fishing_sector, c.catch_status, c.reporting_status, c.gear_type_id)
  ;
end
$body$
language plpgsql;
------


-------------------
-- REGION GRAPHS --
-------------------


create or replace function web.f_dimension_catch_query_layer_preprocessor
(
  i_entity_layer_id int,
  i_area_bucket_id_layer int, 
  i_other_params json
)
returns table(main_area_col_name text, additional_join_clause text) as
$body$
declare
  main_area_col_name text;
  additional_join_clause text := '';
  managed_species_type varchar(20);
begin
  case 
    when i_entity_layer_id < 100 then 
      main_area_col_name := 'f.main_area_id';
      
      /* Special consideration for RFMO */
      if i_entity_layer_id = 4 then
        if coalesce((json_object_field_text(i_other_params, 'managed_species_only'))::boolean, false) then
          managed_species_type := coalesce(lower(json_object_field_text(i_other_params, 'managed_species_type')), 'all');
          case managed_species_type
          when 'primary' then
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.primary_taxon_keys)))';
          when 'secondary' then
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.secondary_taxon_keys)))';
          else
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.primary_taxon_keys || mt.secondary_taxon_keys)))';
          end case;
        end if;
      end if;
    when i_entity_layer_id = 100 then 
      main_area_col_name := 'f.fishing_entity_id::int';
    when i_entity_layer_id = 200 then 
      main_area_col_name := 'ab.area_bucket_id';
      
      if i_area_bucket_id_layer = 400 then
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.area_key = any(ab.area_id_bucket))';
      else
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.main_area_id = any(ab.area_id_bucket) and f.marine_layer_id = ' || i_area_bucket_id_layer || ')';
      end if;
    when i_entity_layer_id = 300 then
      main_area_col_name := 'f.taxon_key';
    when i_entity_layer_id = 400 then
      main_area_col_name := 'f.area_key';
    when i_entity_layer_id = 500 then
      main_area_col_name := 'wt.commercial_group_id';
      additional_join_clause := ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)';
    when i_entity_layer_id = 600 then
      main_area_col_name := 'wt.functional_group_id';
      additional_join_clause := ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)';
    when i_entity_layer_id = 700 then
      main_area_col_name := 'f.reporting_status';
    when i_entity_layer_id = 800 then
      main_area_col_name := 'f.catch_status';
    when i_entity_layer_id = 900 then
      main_area_col_name := 'fa.fao_area_id';
      additional_join_clause := additional_join_clause || ' join web.fao_area fa on (fa.fao_area_id = any($1) and f.area_key = any(fa.area_key))';
    when i_entity_layer_id = 1000 then
      main_area_col_name := 'f.data_layer_id';
    when i_entity_layer_id = 1100 then
      main_area_col_name := 'f.gear_type';
    else
      raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;
  
  return query select main_area_col_name, additional_join_clause;
end
$body$
language plpgsql;

create or replace function web.get_tsv_headings 
(
  i_entity_layer_id int
)
returns text as
$body$
  select array_to_string(
           case when i_entity_layer_id is distinct from 6 
           then array['area_name', 'area_type', 'year', 'scientific_name', 'common_name', 'functional_group', 'commercial_group']::text[] 
           else array['year']::text[] 
           end ||
           case when i_entity_layer_id is distinct from 100 then array['fishing_entity']::text[] else array[]::text[] end ||
           array['fishing_sector','catch_type', 'reporting_status', 'gear_type', 'tonnes', 'landed_value'],
           E'\t');
$body$
language sql;

create or replace function web.get_catch_and_reporting_status_name()
returns table(status_type varchar(10), status char(1), name varchar) as
$body$
  select t.* 
    from (values('catch', 'R', 'Landings'),
                ('catch', 'D', 'Discards'),
                ('reporting', 'R', 'Reported'),
                ('reporting', 'U', 'Unreported')
         )
      as t;
$body$
language sql;

create or replace function web.lookup_entity_name_by_entity_layer(i_entity_layer_id int, i_entity_id int[])
returns table(id_heading varchar(30), entity_id int, name_heading varchar(100), name varchar(256), layer_name varchar(30)) AS
$body$
begin
  case i_entity_layer_id
  when   1 then return query select 'eez_id'::varchar, e.eez_id, 'eez_name'::varchar, e.name, 'eez'::varchar FROM web.eez e WHERE e.eez_id = ANY(i_entity_id);
  when   2 then return query select 'fao_area_id'::varchar, f.fao_area_id, 'fao_area_name'::varchar, f.name, 'high_seas'::varchar FROM web.fao_area f WHERE f.fao_area_id = ANY(i_entity_id);
  when   3 then return query select 'lme_id'::varchar, l.lme_id, 'lme_name'::varchar, l.name, 'lme'::varchar FROM web.lme l WHERE l.lme_id = ANY(i_entity_id);
  when   4 then return query select 'rfmo_id'::varchar, r.rfmo_id, 'rfmo_name'::varchar, r.name, 'rfmo'::varchar FROM web.rfmo r WHERE r.rfmo_id = ANY(i_entity_id);
  when   6 then return query select 'global_id'::varchar, 1, 'global_name'::varchar, 'global'::varchar, 'global'::varchar;
  when 100 then return query select 'fishing_entity_id'::varchar, f.fishing_entity_id::int, 'fishing_entity_name'::varchar, f.name, 'fishing_entity'::varchar FROM web.fishing_entity f WHERE f.fishing_entity_id = ANY(i_entity_id);
  when 200 then return query select 'area_bucket_id'::varchar, ab.area_bucket_id, 'area_bucket_name'::varchar, ab.name, 'area_bucket'::varchar FROM web.area_bucket ab WHERE ab.area_bucket_id = ANY(i_entity_id);
  when 300 then return query select 'taxon_key'::varchar, t.taxon_key, 'common_name'::varchar, t.common_name, 'taxon'::varchar FROM web.cube_dim_taxon t WHERE t.taxon_key = ANY(i_entity_id);
  when 400 then return query select 'area_key'::varchar, a.area_key, 'area_name'::varchar, a.area_key::varchar, 'area'::varchar FROM web.area a WHERE a.area_key = ANY(i_entity_id);
  when 500 then return query select 'commercial_group_id'::varchar, cg.commercial_group_id::int, 'commercial_group_name'::varchar, cg.name, 'commercial_group'::varchar FROM web.commercial_groups cg WHERE cg.commercial_groups = ANY(i_entity_id);
  when 600 then return query select 'functional_group_id'::varchar, cg.functional_group_id::int, 'functional_group_name'::varchar, cg.description, 'functional_group'::varchar FROM web.functional_groups fg WHERE fg.functional_group_id = ANY(i_entity_id);
  when 900 then return query select 'fao_area_id'::varchar, f.fao_area_id, 'fao_area_name'::varchar, f.name, 'fao_area'::varchar FROM web.fao_area f WHERE f.fao_area_id = ANY(i_entity_id);
  when 1000 then return query select 'data_layer_id'::varchar, l.data_layer_id, 'data_layer_name'::varchar, l.name, 'data_layer'::varchar FROM web.data_layer l WHERE l.data_layer_id = ANY(i_entity_id);
  when 1100 then return query select 'gear_type_id'::varchar, f.gear_id, 'gear_name'::varchar, f.super_code, 'gear'::varchar FROM web.gear f WHERE f.gear_id = ANY(i_entity_id);  
  else raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;
end
$body$                             
language plpgsql;

create or replace function web.f_dimension_gear_type_catch_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id int, measure numeric) as
$body$
declare
  rtn_sql text;
  main_area_col_name text;
  additional_join_clause text := '';
begin
  select *
    into main_area_col_name, additional_join_clause
    from web.f_dimension_catch_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select f.year,' || 
    case when coalesce(i_output_area_id, false) then main_area_col_name else 'null::int' end ||
    ',f.gear_id::int' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' ||
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' f.marine_layer_id = ' || i_entity_layer_id || ' and f.main_area_id = any($1) and'
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then ' f.taxon_key = any($1) and'
    else ''
     end ||
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false) 
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.gear_id';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_gear_type_json
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[],
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, gear_type_id, measure) as (
      select * from web.f_dimension_gear_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(gear_type_id, measure_rank) as (
      select c.gear_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.gear_type_id
    )
    select json_agg(fd.*)       
      from (select max(g.super_code) as key, array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm 
              join ranking r on (true)
              join web.gear g on (g.gear_id = r.gear_type_id)
              left join catch c on (c.year = tm.time_business_key and c.gear_type_id = g.gear_id)
             where tm.time_business_key >= (select min(ci.year) from catch ci)
             group by g.gear_id
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_gear_type_tsv
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns setof text as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  if coalesce(i_output_area_id, false) then
    return query
    with catch(year, main_area_id, gear_type_id, measure) as (
      select * from web.f_dimension_gear_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(gear_type_id, measure_rank) as (
      select c.gear_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.gear_type_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(t.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.gear t on (t.gear_id = r.gear_type_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.gear_type_id = r.gear_type_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, gear_type_id, measure) as (
      select * from web.f_dimension_gear_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(gear_type_id, measure_rank) as (
      select c.gear_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.gear_type_id
    )
    select array_to_string('year'::text || array_agg(t.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.gear t on (t.gear_id = r.gear_type_id)
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key and c.gear_type_id = r.gear_type_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;

create or replace function web.f_catch_data_in_json 
(
  i_measure varchar(20),
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)                 
returns json as
$body$
  select f.* from web.f_dimension_species_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'species'
  union all
  select f.* from web.f_dimension_functional_group_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'functional_group'
  union all
  select f.* from web.f_dimension_fishing_entity_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'fishing_entity'
  union all
  select f.* from web.f_dimension_commercial_group_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'commercial_group'
  union all
  select f.* from web.f_dimension_fishing_sector_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'fishing_sector'
  union all
  select f.* from web.f_dimension_catch_type_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'catch_type'
  union all
  select f.* from web.f_dimension_reporting_status_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'reporting_status'
  union all
  select f.* from web.f_dimension_eez_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'eez' and i_entity_layer_id >= 100
  union all
  select f.* from web.f_dimension_highseas_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'highseas' and i_entity_layer_id >= 100
  union all
  select f.* from web.f_dimension_lme_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'lme' and i_entity_layer_id >= 100
  union all
  select f.* from web.f_dimension_fao_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f where i_dimension = 'fao' and i_entity_layer_id >= 100
  union all
  select f.* from web.f_dimension_data_layer_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'data_layer'
  union all
  select f.* from web.f_dimension_gear_type_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'gear_type'
   ;    
$body$
language sql;


select admin.grant_access();
