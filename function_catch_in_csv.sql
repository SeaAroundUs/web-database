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
           array['fishing_sector','catch_type', 'reporting_status', 'tonnes', 'landed_value'],
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
         'f.sector_type_id,f.catch_status,f.reporting_status' || 
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
  (select concat_ws(',', c.year::varchar, csv_escape(fe.name), st.name, cs.name, cr.name, c.catch_sum::varchar, c.real_value::varchar)
     from catch c
     join web.fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity)
     join web.sector_type st on (st.sector_type_id = c.fishing_sector)
     join web.get_catch_and_reporting_status_name() cs on (cs.status_type = 'catch' and cs.status = c.catch_status)
     join web.get_catch_and_reporting_status_name() cr on (cr.status_type = 'reporting' and cr.status = c.reporting_status)
    where i_entity_layer_id = 6
    order by c.year, c.fishing_entity, c.fishing_sector, c.catch_status, c.reporting_status)
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
             where c.entity_layer_id = 2 and i_entity_layer_id = 100
             group by c.year, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_sector, c.catch_status, c.reporting_status)) as d
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
             where c.entity_layer_id = 2 and i_entity_layer_id = 300
             group by c.year, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_sector, c.catch_status, c.reporting_status)) as d
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
     join web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as el on (el.entity_id = c.entity_id)
     join web.data_layer dl on (dl.data_layer_id = c.data_layer_id)
     left join uncertainty u on (u.eez_id = c.entity_id and u.sector_type_id = c.fishing_sector and u.year_range @> c.year and c.data_layer_id = 1)
    where i_entity_layer_id = 1
    order by c.year, dl.data_layer_id, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_entity, c.fishing_sector, c.catch_status, c.reporting_status)
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
     join web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as el on (el.entity_id = c.entity_id)
    where i_entity_layer_id not in (1, 6, 100, 300)
    order by c.year, c.taxon, t.functional_group_id, t.commercial_group_id, c.fishing_entity, c.fishing_sector, c.catch_status, c.reporting_status)
  ;
end
$body$
language plpgsql;
------
