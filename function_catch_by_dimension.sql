/********
 helper functions
********/
create or replace function web.get_area_bucket_id_layer 
(
  i_entity_id int[]
)
returns int as
$body$
declare 
  bucket_type_count int := 0;
  area_bucket_id_type varchar(100);
begin
  select max(abt.area_id_type), count(distinct ab.area_bucket_type_id) 
    into area_bucket_id_type, bucket_type_count
    from web.area_bucket ab
    join web.area_bucket_type abt on (abt.area_bucket_type_id = ab.area_bucket_type_id)
   where ab.area_bucket_id = any(i_entity_id);
   
  if bucket_type_count > 1 then
    raise exception 'More than one area bucket types found in the input area_bucket_id list. Aborting!';
  end if;
  
  return case area_bucket_id_type 
         when 'eez id' then 1
         when 'fao area id' then 2 
         when 'lme id' then 3
		 when 'meow id' then 19
         when 'area key' then 400
         end;
end
$body$
language plpgsql;

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
  when  19 then return query select 'meow_id'::varchar, m.meow_id, 'meow_name'::varchar, m.name, 'meow'::varchar FROM web.meow m WHERE m.meow_id = ANY(i_entity_id);
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

create or replace function web.lookup_entity_name_by_entity_layer(i_entity_layer_id int, i_entity_id varchar[])
returns table(id_heading varchar(30), entity_id varchar, name_heading varchar(100), name varchar(256), layer_name varchar(30)) as
$body$
begin
  case i_entity_layer_id
  when 700 then return query select 'reporting_status_code'::varchar, r.stat, 'reporting_status'::varchar, CASE WHEN r.stat = 'R' THEN 'Reported' ELSE 'Unreported' END, 'reporting_status'::varchar FROM unnest(i_entity_id) AS r(stat);
  when 800 then return query select 'catch_type_code'::varchar, c.ctype, 'catch_type'::varchar, CASE WHEN c.ctype = 'R' THEN 'Landings' ELSE 'Discarded' END, 'catch_type'::varchar FROM unnest(i_entity_id) AS c(ctype);
  else raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;
end
$body$
language plpgsql;

/********
 catch reports 
*********/
create or replace function web.f_dimension_species_catch_query 
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
    ',f.taxon_key' ||
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
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800, 1000) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false)
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.taxon_key';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_species_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, taxon, measure) as ( 
       select * from web.f_dimension_species_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(taxon, measure_rank) as (
      select c.taxon, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.taxon not in (100039, 100139, 100239, 100339)
       group by c.taxon
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total) as (
      select c.year, sum(case when r.taxon is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.taxon = c.taxon)
       group by c.year
    )
    select json_agg(fd.*) 
      from ((select r.taxon as entity_id, t.common_name as key, t.scientific_name as scientific_name, 
                    (select array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 3)]] order by tm.time_business_key)
                       from web.time tm
                       left join catch c on (c.year = tm.time_business_key and c.taxon = r.taxon) 
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               from ranking r 
               join web.cube_dim_taxon t on (t.taxon_key = r.taxon)
               order by r.measure_rank)
            union all
            (select null::int, 'Others'::text as key, null::text, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_species_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
  i_output_area_id boolean default false,
  i_use_scientific_name boolean default false,
  i_other_params json default null
)
returns setof text as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  i_use_scientific_name := coalesce(i_use_scientific_name, false);
  
  if coalesce(i_output_area_id, false) then
    return query
    with catch(year, main_area_id, taxon, measure) as (
       select * from web.f_dimension_species_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(taxon, measure_rank) as (
      select c.taxon, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.taxon not in (100039, 100139, 100239, 100339)
       group by c.taxon
       order by sum(c.measure) desc
       limit i_top_count        
    ),
    total(year, main_area_id, mixed_total) as (
      select c.year, c.main_area_id, sum(case when r.taxon is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.taxon = c.taxon)
       group by c.year, c.main_area_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg((case when i_use_scientific_name then t.scientific_name else t.common_name end)::text order by r.measure_rank) || 'Others'::text, E'\t') 
      from ranking r
      join web.cube_dim_taxon t on (t.taxon_key = r.taxon)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) ||
                           (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key and tby.main_area_id = an.entity_id), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.taxon = r.taxon)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, taxon, measure) as (
      select * from web.f_dimension_species_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(taxon, measure_rank) as (
      select c.taxon, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.taxon not in (100039, 100139, 100239, 100339)
       group by c.taxon
       order by sum(c.measure) desc
       limit i_top_count        
    ),
    total(year, mixed_total) as (
      select c.year, sum(case when r.taxon is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.taxon = c.taxon)
       group by c.year
    )                                               
    (select array_to_string('year'::text || array_agg((case when i_use_scientific_name then t.scientific_name else t.common_name end)::text order by r.measure_rank) || 'Others'::text, E'\t') 
      from ranking r
      join web.cube_dim_taxon t on (t.taxon_key = r.taxon))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.taxon = r.taxon)) || 
                            (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql;
-----


-----
create or replace function web.f_dimension_commercial_group_catch_query 
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
    
    ',wt.commercial_group_id::int' ||
    
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    
    ' from web.v_fact_data f' ||
    
    -- if entity layer is not already commercial group, then add the join to get commercial_group_id here
    case when i_entity_layer_id <> 500 then ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)' else '' end ||
    
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
    
    ',wt.commercial_group_id';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_commercial_group_json 
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
    with catch(year, entity_id, commercial_group_id, measure) as (
       select * from web.f_dimension_commercial_group_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(commercial_group_id, measure_rank) as (
      select c.commercial_group_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.commercial_group_id
    )
    select json_agg(fd.*) 
      from (select max(cg.name) as key, array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm
              join ranking r on (true)
              join web.commercial_groups cg on (cg.commercial_group_id = r.commercial_group_id)
              left join catch c on (c.year = tm.time_business_key and c.commercial_group_id = r.commercial_group_id) 
             group by cg.commercial_group_id
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_commercial_group_tsv
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
    with catch(year, entity_id, commercial_group_id, measure) as (
       select * from web.f_dimension_commercial_group_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(commercial_group_id, measure_rank) as (
      select c.commercial_group_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.commercial_group_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(cg.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.commercial_groups cg on (cg.commercial_group_id = r.commercial_group_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.entity_id = an.entity_id and c.commercial_group_id = r.commercial_group_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, commercial_group_id, measure) as (
       select * from web.f_dimension_commercial_group_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(commercial_group_id, measure_rank) as (
      select c.commercial_group_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.commercial_group_id
    )
    select array_to_string('year'::text || array_agg(cg.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.commercial_groups cg on (cg.commercial_group_id = r.commercial_group_id)
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key and c.commercial_group_id = r.commercial_group_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;
-----                             


-----                                 
create or replace function web.f_dimension_functional_group_catch_query 
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
    ',wt.functional_group_id::int' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' ||
    case when i_entity_layer_id <> 600 then ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)' else '' end ||
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
    ',wt.functional_group_id';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_functional_group_json
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, functional_group_id, measure) as (
      select * from web.f_dimension_functional_group_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),                                                 
    ranking(functional_group_id, measure_rank) as (
      select c.functional_group_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.functional_group_id
       order by sum(c.measure) desc   
       limit i_top_count
    ),
    total(year, mixed_total) as (
      select c.year, sum(case when r.functional_group_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.functional_group_id = c.functional_group_id)
       group by c.year
    )
    select json_agg(fd.*) 
      from ((select max(fg.description) as key, array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
               from web.time tm 
               join ranking r on (true)
               join web.functional_groups fg on (fg.functional_group_id = r.functional_group_id)
               left join catch c on (c.year = tm.time_business_key and c.functional_group_id = fg.functional_group_id) 
              group by fg.functional_group_id
              order by max(r.measure_rank))
            union all
            (select 'Others'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
              where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )
           )                 
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_functional_group_tsv
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
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
    with catch(year, main_area_id, functional_group_id, measure) as (
      select * from web.f_dimension_functional_group_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(functional_group_id, measure_rank) as (
      select c.functional_group_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.functional_group_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, main_area_id, mixed_total) as (
      select c.year, c.main_area_id, sum(case when r.functional_group_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.functional_group_id = c.functional_group_id)
       group by c.year, c.main_area_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(fg.description::text order by r.measure_rank) || 'Others'::text, E'\t') 
      from ranking r
      join web.functional_groups fg on (fg.functional_group_id = r.functional_group_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) || 
                           (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key and tby.main_area_id = an.entity_id), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.functional_group_id = r.functional_group_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, functional_group_id, measure) as (
      select * from web.f_dimension_functional_group_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(functional_group_id, measure_rank) as (
      select c.functional_group_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.functional_group_id
       order by sum(c.measure) desc   
       limit i_top_count        
    ),
    total(year, mixed_total) as (
      select c.year, sum(case when t.functional_group_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.functional_group_id = c.functional_group_id)
       group by c.year
    )                                               
    (select array_to_string('year'::varchar || array_agg(fg.description order by r.measure_rank) || 'Others'::varchar, E'\t') 
      from ranking r
      join web.functional_groups fg on (fg.functional_group_id = r.functional_group_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.functional_group_id = r.functional_group_id)) || 
                            (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql;
-----


-----
create or replace function web.f_dimension_fishing_entity_catch_query 
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
    ',f.fishing_entity_id::int' ||
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
    ',f.fishing_entity_id::int';
raise info 'rtn_sql: %', rtn_sql;
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_fishing_entity_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$ 
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  home_fishing_entity_id smallint := (select e.is_home_eez_of_fishing_entity_id from web.eez e where e.eez_id = i_entity_id[1] and i_entity_layer_id = 1);
begin
  return (
    with catch(year, entity_id, fishing_entity_id, measure) as (
      select * from web.f_dimension_fishing_entity_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(fishing_entity_id, measure_rank) as (
      select c.fishing_entity_id, row_number() over(order by case when i_entity_layer_id = 1 then (c.fishing_entity_id = home_fishing_entity_id) else false end desc, sum(c.measure) desc)
        from catch c
       group by c.fishing_entity_id
       limit i_top_count
    ),
    total(year, mixed_total) as (
      select c.year, sum(case when r.fishing_entity_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fishing_entity_id = c.fishing_entity_id)
       group by c.year
    )
    select json_agg(fd.*) 
      from ((select fe.name as key, 
                    array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 3)]] order by tm.time_business_key) as values
                       from web.time tm
                       join ranking r on (true)
                       join web.v_dim_fishing_entity fe on (fe.fishing_entity_id = r.fishing_entity_id)
                       left join catch c on (c.year = tm.time_business_key and c.fishing_entity_id = r.fishing_entity_id)
              		   group by r.measure_rank, fe.name
                       order by max(r.measure_rank))
            union all
            (select 'Others'::text as key,                                                           
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
              where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )
           )
        as fd  
  );
end
$body$
language plpgsql;
    
create or replace function web.f_dimension_fishing_entity_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns setof text as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  home_fishing_entity_id smallint := (select e.is_home_eez_of_fishing_entity_id from web.eez e where e.eez_id = i_entity_id[1] and i_entity_layer_id = 1);
begin
  if coalesce(i_output_area_id, false) then
    return query
    with catch(year, main_area_id, fishing_entity_id, measure) as (
      select * from web.f_dimension_fishing_entity_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(fishing_entity_id, measure_rank) as (
      select c.fishing_entity_id, row_number() over(order by case when i_entity_layer_id = 1 then (c.fishing_entity_id = home_fishing_entity_id) else false end desc, sum(c.measure) desc)
        from catch c
       group by c.fishing_entity_id
       limit i_top_count
    ),
    total(year, main_area_id, mixed_total) as (
      select c.year, c.main_area_id, sum(case when r.fishing_entity_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fishing_entity_id = c.fishing_entity_id)
       group by c.year, c.main_area_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(fe.name::text order by r.measure_rank) || 'Others'::text, E'\t') 
      from ranking r
      join web.fishing_entity fe on (fe.fishing_entity_id = r.fishing_entity_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank) ||
                           (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key and tby.main_area_id = an.entity_id), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.fishing_entity_id = r.fishing_entity_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, fishing_entity_id, measure) as (
      select * from web.f_dimension_fishing_entity_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(fishing_entity_id, measure_rank) as (
      select c.fishing_entity_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.fishing_entity_id
       order by sum(c.measure) desc
       limit i_top_count        
    ),
    total(year, mixed_total) as (
      select c.year, sum(case when t.fishing_entity_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fishing_entity_id = c.fishing_entity_id)
       group by c.year
    )                                               
    (select array_to_string('year'::varchar || array_agg(fe.name order by r.measure_rank) || 'Others'::varchar, E'\t') 
      from ranking r
      join web.fishing_entity fe on (fe.fishing_entity_id = r.fishing_entity_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.fishing_entity_id = r.fishing_entity_id)) || 
                            (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
   end if;
end
$body$
language plpgsql;
-----


-----
create or replace function web.f_dimension_fishing_sector_catch_query 
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
    ',f.sector_type_id::int' ||
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
    ',f.sector_type_id';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_fishing_sector_json
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
    with catch(year, entity_id, sector_type_id, measure) as (
      select * from web.f_dimension_fishing_sector_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(sector_type_id, measure_rank) as (
      select c.sector_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.sector_type_id
    )
    select json_agg(fd.*)       
      from (select max(st.name) as key, array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm 
              join ranking r on (true)
              join web.sector_type st on (st.sector_type_id = r.sector_type_id)
              left join catch c on (c.year = tm.time_business_key and c.sector_type_id = st.sector_type_id)
             group by st.sector_type_id
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_fishing_sector_tsv
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
    with catch(year, main_area_id, sector_type_id, measure) as (
      select * from web.f_dimension_fishing_sector_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(sector_type_id, measure_rank) as (
      select c.sector_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.sector_type_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(t.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.sector_type t on (t.sector_type_id = r.sector_type_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.sector_type_id = r.sector_type_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, sector_type_id, measure) as (
      select * from web.f_dimension_fishing_sector_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(sector_type_id, measure_rank) as (
      select c.sector_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.sector_type_id
    )
    select array_to_string('year'::text || array_agg(t.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.sector_type t on (t.sector_type_id = r.sector_type_id)
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key and c.sector_type_id = r.sector_type_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;
-----


-----
create or replace function web.f_dimension_catch_type_catch_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id char, measure numeric) as
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
    ',f.catch_status' ||
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
    ',f.catch_status';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_catch_type_json
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
    with catch(year, entity_id, catch_status, measure) as (
      select * from web.f_dimension_catch_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(catch_status, measure_rank) as (
      select c.catch_status, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.catch_status
    )
    select json_agg(fd.*) 
      from (select max(stat.name) as key,
                   array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm
              join ranking r on (true)
              join web.get_catch_and_reporting_status_name() stat on (stat.status_type = 'catch' and stat.status = r.catch_status)
              left join catch c on (c.year = tm.time_business_key and c.catch_status = r.catch_status)
             group by r.catch_status
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_catch_type_tsv
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
    with catch(year, main_area_id, catch_status, measure) as (
      select * from web.f_dimension_catch_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(catch_status, measure_rank) as (
      select c.catch_status, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.catch_status
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(case when r.catch_status = 'R' then 'Landings' else 'Discards' end order by r.measure_rank), E'\t') 
      from ranking r
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.catch_status = r.catch_status)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, catch_status, measure) as (
      select * from web.f_dimension_catch_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(catch_status, measure_rank) as (
      select c.catch_status, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.catch_status
    )
    select array_to_string('year'::text || array_agg(case when r.catch_status = 'R' then 'Landings' else 'Discards' end order by r.measure_rank), E'\t') 
      from ranking r
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key and c.catch_status = r.catch_status)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;
-----


-----
create or replace function web.f_dimension_reporting_status_catch_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id char, measure numeric) as
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
    ',f.reporting_status' ||
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
    ',f.reporting_status';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_reporting_status_json
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
    with catch(year, entity_id, reporting_status, measure) as (
      select * from web.f_dimension_reporting_status_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(reporting_status, measure_rank) as (
      select c.reporting_status, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.reporting_status
    )
    select json_agg(fd.*) 
      from (select case when r.reporting_status = 'R' then 'Reported' else 'Unreported' end as key,
                   array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm
              join ranking r on (true)
              left join catch c on (c.year = tm.time_business_key and c.reporting_status = r.reporting_status)
             group by r.reporting_status
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_reporting_status_tsv
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
    with catch(year, main_area_id, reporting_status, measure) as (
      select * from web.f_dimension_reporting_status_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(reporting_status, measure_rank) as (
      select c.reporting_status, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.reporting_status
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(case when r.reporting_status = 'R' then 'Reported' else 'Unreported' end order by r.measure_rank), E'\t') 
      from ranking r
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.reporting_status = r.reporting_status)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, reporting_status, measure) as (
      select * from web.f_dimension_reporting_status_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(reporting_status, measure_rank) as (
      select c.reporting_status, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.reporting_status
    )
    select array_to_string('year'::text || array_agg(case when r.reporting_status = 'R' then 'Reported' else 'Unreported' end order by r.measure_rank), E'\t') 
      from ranking r
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key and c.reporting_status = r.reporting_status)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;
-----------------

-----------------
create or replace function web.f_dimension_eez_and_highseas_catch_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id int, dimension_member_layer_id int, measure numeric) as
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
    ',f.main_area_id, f.marine_layer_id' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' || 
    additional_join_clause ||
    ' where f.marine_layer_id in (1, 2)' ||   
    case 
    when i_entity_layer_id = 100 then ' and f.fishing_entity_id = any($1)'
    when i_entity_layer_id = 300 then ' and f.taxon_key = any($1)'
    else ''
     end ||
    ' and (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false)
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.main_area_id, f.marine_layer_id';
    
  --DEBUG ONLY
  --raise info 'rtn_sql: %', rtn_sql;
  --DEBUG ONLY
  
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_eez_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as ( 
       select * from web.f_dimension_eez_and_highseas_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(eez_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 1
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total, non_eez_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 1 and r.eez_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 2 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.eez_id = c.main_area_id and c.marine_layer_id = 1)
       group by c.year
    )
select json_agg(fd.*) 
      from ((select e.eez_id as entity_id, e.name as key, 
                   array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm
              join ranking r on (true)
              join web.eez e on (e.eez_id = r.eez_id)
              left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.eez_id and c.marine_layer_id = 1)
             group by r.measure_rank, e.eez_id
             order by max(r.measure_rank))
            union all
            (select null::int, 'Other EEZs'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )          
            union all
            (select null::int, 'Other EEZs'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )
            union all
            (select null::int, 'High Seas'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.non_eez_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from total t where t.non_eez_total is distinct from 0 limit 1)
               
            )
           )  as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_eez_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
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
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
       select * from web.f_dimension_eez_and_highseas_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(eez_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 1
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, entity_id, mixed_total, non_eez_total) as (
      select c.year, 
             c.entity_id, 
             sum(case when c.marine_layer_id = 1 and r.eez_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 2 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.eez_id = c.main_area_id and c.marine_layer_id = 1)
       group by c.year, c.entity_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(e.name::text order by r.measure_rank) || 'Other EEZs'::text || 'High Seas'::text, E'\t') 
      from ranking r
      join web.eez e on (e.eez_id = r.eez_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) ||
                           (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.non_eez_total::numeric(20, 2))::text, '')] 
                              from total tby where tby.year = tm.time_business_key and tby.entity_id = an.entity_id), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.entity_id = an.entity_id and c.main_area_id = r.eez_id and c.marine_layer_id = 1)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
      select * from web.f_dimension_eez_and_highseas_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(eez_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 1
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total, non_eez_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 1 and r.eez_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 2 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.eez_id = c.main_area_id and c.marine_layer_id = 1)
       group by c.year
    )                                               
    (select array_to_string('year'::text || array_agg(e.name::text order by r.measure_rank) || 'Other EEZs'::text || case when area_bucket_id_layer <> 1 then 'High Seas'::text else null end, E'\t') 
      from ranking r
      join web.eez e on (e.eez_id = r.eez_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.eez_id and c.marine_layer_id = 1)) ||
                            case 
                            when area_bucket_id_layer <> 1 then 
                              (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.non_eez_total::numeric(20, 2))::text, '')] 
                                 from total tby where tby.year = tm.time_business_key)
                            else
                              (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') 
                                 from total tby where tby.year = tm.time_business_key)
                            end, 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql;
-----------------

-----------------
create or replace function web.f_dimension_lme_catch_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id int, dimension_member_layer_id int, measure numeric) as
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
    ',f.main_area_id, f.marine_layer_id' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' || 
    additional_join_clause ||
    ' where f.marine_layer_id in (3, 6)' ||   
    case 
    when i_entity_layer_id = 100 then ' and f.fishing_entity_id = any($1)'
    when i_entity_layer_id = 300 then ' and f.taxon_key = any($1)'
    else ''
     end ||
    ' and (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false)
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.main_area_id, f.marine_layer_id';
    
  --DEBUG ONLY
raise info 'rtn_sql: %', rtn_sql;
  --DEBUG ONLY
  
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_lme_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as ( 
       select * from web.f_dimension_lme_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),                                                 
    ranking(lme_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 3
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    l3_total(year, mixed_total) as (
      select c.year, 
             sum(case when r.lme_id is null then c.measure else 0 end) as mt
        from catch c
        left join ranking r on (r.lme_id = c.main_area_id)
       where c.marine_layer_id = 3
       group by c.year
    ),
    l6_total(year, non_lme_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 6 then c.measure else 0 end) - sum(case when c.marine_layer_id = 3 then c.measure else 0 end) as nlt
        from catch c
       group by c.year
    )
    select json_agg(fd.*) 
      from ((select l.lme_id as entity_id, l.name as key, 
                    array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 3)]] order by tm.time_business_key) as values
                       from web.time tm                                                                                             
              join ranking r on (true)
              join web.lme l on (l.lme_id = r.lme_id)
              left join catch c on (c.year = tm.time_business_key and c.main_area_id = l.lme_id and c.marine_layer_id = 3)
             group by r.measure_rank, l.lme_id
             order by max(r.measure_rank))
            union all
            (select null::int, 'Others'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join l3_total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from l3_total t where t.mixed_total is distinct from 0 limit 1)
            )
            union all
            (select null::int, 'Non-LME'::text as key, 
                    array_accum(array[array[tm.time_business_key, coalesce(tby.non_lme_total::numeric(20, 2), 0)]] order by tm.time_business_key) as values
                       from web.time tm
                       left join l6_total tby on (tby.year = tm.time_business_key)
               where exists (select 1 from l6_total t where t.non_lme_total is distinct from 0 limit 1)
            )
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_lme_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
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
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
       select * from web.f_dimension_lme_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(lme_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 3
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, entity_id, mixed_total, non_lme_total) as (
      select c.year, 
             c.entity_id, 
             sum(case when c.marine_layer_id = 3 and r.lme_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 6 then c.measure else 0 end) - sum(case when c.marine_layer_id = 3 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.lme_id = c.main_area_id and c.marine_layer_id = 3)
       group by c.year, c.entity_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(l.name::text order by r.measure_rank) || 'Others'::text || 'Non-LME'::text, E'\t') 
      from ranking r
      join web.lme l on (l.lme_id = r.lme_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) ||
                           (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.non_lme_total::numeric(20, 2))::text, '')] 
                              from total tby 
                             where tby.year = tm.time_business_key and tby.entity_id = an.entity_id), 
                           E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.entity_id = an.entity_id and c.main_area_id = r.lme_id and c.marine_layer_id = 3)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
      select * from web.f_dimension_lme_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(lme_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 3
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total, non_lme_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 3 and r.lme_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 6 then c.measure else 0 end) - sum(case when c.marine_layer_id = 3 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.lme_id = c.main_area_id and c.marine_layer_id = 3)
       group by c.year
    )                                               
    (select array_to_string('year'::text || array_agg(l.name::text order by r.measure_rank) || 'Others'::text || 'Non-LME'::text, E'\t') 
      from ranking r
      join web.lme l on (l.lme_id = r.lme_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.lme_id and c.marine_layer_id = 3)) || 
                            (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.non_lme_total::numeric(20, 2))::text, '')] 
                               from total tby 
                              where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql;
-----------------

-----------------
create or replace function web.f_dimension_meow_catch_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id int, dimension_member_layer_id int, measure numeric) as
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
    ',f.main_area_id, f.marine_layer_id' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' || 
    additional_join_clause ||
    ' where f.marine_layer_id in (19, 6)' ||   
    case 
    when i_entity_layer_id = 100 then ' and f.fishing_entity_id = any($1)'
    when i_entity_layer_id = 300 then ' and f.taxon_key = any($1)'
    else ''
     end ||
    ' and (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false)
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.main_area_id, f.marine_layer_id';
    
  --DEBUG ONLY
raise info 'rtn_sql: %', rtn_sql;
  --DEBUG ONLY
  
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_meow_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as ( 
       select * from web.f_dimension_meow_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),                                                 
    ranking(meow_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 19
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    l3_total(year, mixed_total) as (
      select c.year, 
             sum(case when r.meow_id is null then c.measure else 0 end) as mt
        from catch c
        left join ranking r on (r.meow_id = c.main_area_id)
       where c.marine_layer_id = 19
       group by c.year
    ),
    l6_total(year, non_meow_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 6 then c.measure else 0 end) - sum(case when c.marine_layer_id = 19 then c.measure else 0 end) as nlt
        from catch c
       group by c.year
    )
    select json_agg(fd.*) 
      from ((select m.meow_id as entity_id, m.name as key, 
                    (select array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 3)]] order by tm.time_business_key)
                       from web.time tm                                                                                             
                       left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.meow_id and c.marine_layer_id = 19) 
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               from ranking r 
               join web.meow m on (m.meow_id = r.meow_id)
               order by r.measure_rank)
            union all
            (select null::int, 'Others'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join l3_total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from l3_total t where t.mixed_total is distinct from 0 limit 1)
            )
            union all
            (select null::int, 'Non-MEOW'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.non_meow_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join l6_total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from l6_total t where t.non_meow_total is distinct from 0 limit 1)
            )
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_meow_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
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
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
       select * from web.f_dimension_meow_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(meow_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 19
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, entity_id, mixed_total, non_lme_total) as (
      select c.year, 
             c.entity_id, 
             sum(case when c.marine_layer_id = 19 and r.lme_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 6 then c.measure else 0 end) - sum(case when c.marine_layer_id = 19 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.meow_id = c.main_area_id and c.marine_layer_id = 19)
       group by c.year, c.entity_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(m.name::text order by r.measure_rank) || 'Others'::text || 'Non-MEOW'::text, E'\t') 
      from ranking r
      join web.meow m on (m.meow_id = r.meow_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) ||
                           (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.non_meow_total::numeric(20, 2))::text, '')] 
                              from total tby 
                             where tby.year = tm.time_business_key and tby.entity_id = an.entity_id), 
                           E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.entity_id = an.entity_id and c.main_area_id = r.meow_id and c.marine_layer_id = 19)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
      select * from web.f_dimension_meow_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(meow_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 19
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total, non_meow_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 19 and r.meow_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 6 then c.measure else 0 end) - sum(case when c.marine_layer_id = 3 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.meow_id = c.main_area_id and c.marine_layer_id = 19)
       group by c.year
    )                                               
    (select array_to_string('year'::text || array_agg(m.name::text order by r.measure_rank) || 'Others'::text || 'Non-MEOW'::text, E'\t') 
      from ranking r
      join web.meow m on (m.meow_id = r.meow_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.meow_id and c.marine_layer_id = 19)) || 
                            (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.non_meow_total::numeric(20, 2))::text, '')] 
                               from total tby 
                              where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql;
-----------------

-----------------
create or replace function web.f_dimension_highseas_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as ( 
       select * from web.f_dimension_eez_and_highseas_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(fao_area_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 2
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total, eez_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 2 and r.fao_area_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 1 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fao_area_id = c.main_area_id and c.marine_layer_id = 2)
       group by c.year
    )
        select json_agg(fd.*) 
      from ((select f.fao_area_id as entity_id, f.name as key, 
                    array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 3)]] order by tm.time_business_key)  as values
                       from web.time tm
                       join ranking r on (true)
                       join web.fao_area f on (f.fao_area_id = r.fao_area_id)
                       left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.fao_area_id and c.marine_layer_id = 2) 
               			group by r.measure_rank, f.fao_area_id
                       order by max(r.measure_rank))
            union all
            (select null::int, 'Other High Seas'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )
            union all
            (select null::int, 'EEZs'::text as key, 
                    array_accum(array[array[tm.time_business_key, coalesce(tby.eez_total::numeric(20, 2), null)]] order by tm.time_business_key) as values
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
               where exists (select 1 from total t where t.eez_total is distinct from 0 limit 1)
            )
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_highseas_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
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
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
       select * from web.f_dimension_eez_and_highseas_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(fao_area_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 2
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, entity_id, mixed_total, eez_total) as (
      select c.year, 
             c.entity_id, 
             sum(case when c.marine_layer_id = 2 and r.fao_area_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 1 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fao_area_id = c.main_area_id and c.marine_layer_id = 2)
       group by c.year, c.entity_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(f.name::text order by r.measure_rank) || 'Other High Seas'::text || 'EEZs'::text, E'\t') 
      from ranking r
      join web.fao_area f on (f.fao_area_id = r.fao_area_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) ||
                           (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.eez_total::numeric(20, 2))::text, '')] 
                              from total tby 
                             where tby.year = tm.time_business_key and tby.entity_id = an.entity_id), 
                           E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.entity_id = an.entity_id and c.main_area_id = r.fao_area_id and c.marine_layer_id = 2)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, main_area_id, marine_layer_id, measure) as (
      select * from web.f_dimension_eez_and_highseas_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(fao_area_id, measure_rank) as (
      select c.main_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       where c.marine_layer_id = 2
       group by c.main_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total, eez_total) as (
      select c.year, 
             sum(case when c.marine_layer_id = 2 and r.fao_area_id is null then c.measure else 0 end),
             sum(case when c.marine_layer_id = 1 then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fao_area_id = c.main_area_id and c.marine_layer_id = 2)
       group by c.year
    )                                               
    (select array_to_string('year'::text || array_agg(f.name::text order by r.measure_rank) || 'Other High Seas'::text || 'EEZs'::text, E'\t') 
      from ranking r
      join web.fao_area f on (f.fao_area_id = r.fao_area_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.main_area_id = r.fao_area_id and c.marine_layer_id = 2)) || 
                            (select array[coalesce((tby.mixed_total::numeric(20, 2))::text, ''), coalesce((tby.eez_total::numeric(20, 2))::text, '')] 
                               from total tby 
                              where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql;
-----------------

-----------------
create or replace function web.f_dimension_fao_catch_query 
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
    ',fa.fao_area_id' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' || 
    -- if entity layer is not already fao, then add the join to get fao area_keys here
    case when i_entity_layer_id <> 900 then ' join web.fao_area fa on (f.area_key = any(fa.area_key))' else '' end ||
    additional_join_clause ||
    ' where ' ||   
    case 
    when i_entity_layer_id = 100 then 'f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then 'f.taxon_key = any($1) and'
    when i_entity_layer_id = 400 then 'f.area_key = any($1) and'
    when i_entity_layer_id = 700 then 'f.reporting_status = any($1) and'
    when i_entity_layer_id = 800 then 'f.catch_status = any($1) and'
    else ''
     end ||
    ' (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false)
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',fa.fao_area_id';
    
  --DEBUG ONLY
  --raise info 'rtn_sql: %', rtn_sql;
  --DEBUG ONLY
  
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_fao_json 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with catch(year, entity_id, fao_area_id, measure) as ( 
       select * from web.f_dimension_fao_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(fao_area_id, measure_rank) as (
      select c.fao_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.fao_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total) as (
      select c.year, 
             sum(case when r.fao_area_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fao_area_id = c.fao_area_id)
       group by c.year
    )
    select json_agg(fd.*) 
      from ((select f.fao_area_id as entity_id, f.alternate_name as key, 
                    (select array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 3)]] order by tm.time_business_key)
                       from web.time tm
                       left join catch c on (c.year = tm.time_business_key and c.fao_area_id = r.fao_area_id) 
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               from ranking r 
               join web.fao_area f on (f.fao_area_id = r.fao_area_id)
               order by r.measure_rank)
            union all
            (select null::int, 'Others'::text as key, 
                    (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_total::numeric(20, 2), 0)]] order by tm.time_business_key) 
                       from web.time tm
                       left join total tby on (tby.year = tm.time_business_key)
                      where tm.time_business_key >= (select min(ci.year) from catch ci)) as values
               where exists (select 1 from total t where t.mixed_total is distinct from 0 limit 1)
            )
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function web.f_dimension_fao_tsv 
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10, 
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
    with catch(year, entity_id, fao_area_id, measure) as (
       select * from web.f_dimension_fao_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(fao_area_id, measure_rank) as (
      select c.fao_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.fao_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, entity_id, mixed_total) as (
      select c.year, 
             c.entity_id, 
             sum(case when r.fao_area_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fao_area_id = c.fao_area_id)
       group by c.year, c.entity_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(f.alternate_name::text order by r.measure_rank) || 'Others'::text, E'\t') 
      from ranking r
      join web.fao_area f on (f.fao_area_id = r.fao_area_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank) ||
                           (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key and tby.entity_id = an.entity_id), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.entity_id = an.entity_id and c.fao_area_id = r.fao_area_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, fao_area_id, measure) as (
      select * from web.f_dimension_fao_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(fao_area_id, measure_rank) as (
      select c.fao_area_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.fao_area_id
       order by sum(c.measure) desc
       limit i_top_count
    ),
    total(year, mixed_total) as (
      select c.year, 
             sum(case when r.fao_area_id is null then c.measure else 0 end)
        from catch c
        left join ranking r on (r.fao_area_id = c.fao_area_id)
       group by c.year
    )                                               
    (select array_to_string('year'::text || array_agg(f.alternate_name::text order by r.measure_rank) || 'Others'::text, E'\t') 
      from ranking r
      join web.fao_area f on (f.fao_area_id = r.fao_area_id))
    union all
    (select array_to_string(tm.time_business_key::text || 
                            (select array_agg(coalesce((c.measure::numeric(20, 2))::text, '')::text order by r.measure_rank)
                               from ranking r 
                               left join catch c on (c.year = tm.time_business_key and c.fao_area_id = r.fao_area_id)) || 
                            (select coalesce((tby.mixed_total::numeric(20, 2))::text, '') from total tby where tby.year = tm.time_business_key), 
                            E'\t')
       from web.time tm
      where tm.time_business_key >= (select min(ci.year) from catch ci)
      order by tm.time_business_key);
  end if;
end
$body$
language plpgsql; 

create or replace function web.f_dimension_data_layer_catch_query 
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
    'select f.year,1, f.data_layer_id::int' ||
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
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800, 1000) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.year,f.data_layer_id';
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_dimension_data_layer_json
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
    with catch(year, entity_id, data_layer_id, measure) as (
      select * from web.f_dimension_data_layer_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(data_layer_id, measure_rank) as (
      select c.data_layer_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.data_layer_id
    )
    select json_agg(fd.*) 
      from (select l.name as key,
                   array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm
              join ranking r on (true)
              join web.data_layer l on l.data_layer_id = r.data_layer_id
              left join catch c on (c.year = tm.time_business_key and c.data_layer_id = r.data_layer_id)
             where tm.time_business_key >= (select min(ci.year) from catch ci)
             group by l.name
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;
-----------------

-----------------
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
    ',g.super_code::text' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f, web.gear g' ||
    additional_join_clause ||
    ' where f.gear_id = g.gear_id and' ||   
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
    ',g.super_code';
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
    with catch(time_business_key, entity_id, gear_type, measure) as (
      select * from web.f_dimension_gear_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    catch2(time_business_key, entity_id, gear_type, measure) as (
		select distinct generate_series(1950, 2014), entity_id, gear_type, 0 from catch order by generate_series, gear_type desc
	),
	catch3(time_business_key, entity_id, gear_type, measure) as (
		select c2.time_business_key, c2.entity_id, c2.gear_type, coalesce(c.measure - c2.measure, 0) from catch2 c2 left join catch c on c.time_business_key = c2.time_business_key and c.gear_type = c2.gear_type
	),
	 ranking(gear_type, measure_rank) as (
     select c.gear_type, row_number() over(order by sum(c.measure) desc)
       from catch3 c
      group by c.gear_type
    )
    select json_agg(fd.*)       
      from (select r.gear_type as key, array_accum(array[array[c.time_business_key::int, c.measure::numeric(20, 2)]] order by c.time_business_key) as values 
              from ranking r,
              catch3 c 
              where r.gear_type = c.gear_type
             group by r.gear_type
             order by max(r.measure_rank))
        as fd);
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
    with catch(year, main_area_id, gear_type, measure) as (
      select * from web.f_dimension_gear_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(gear_type, measure_rank) as (
      select c.gear_type, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.gear_type
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(r.gear_type::text order by r.measure_rank), E'\t') 
      from ranking r
  --    join web.gear t on (t.gear_id = r.gear_type_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, gear_type, measure) as (
      select * from web.f_dimension_gear_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(gear_type_id, measure_rank) as (
      select c.gear_type, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.gear_type
    )
    select array_to_string('year'::text || array_agg(r.gear_type::text order by r.measure_rank), E'\t') 
      from ranking r
 --     join web.gear t on (t.gear_id = r.gear_type_id)
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;
-----------------

-----
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

create or replace function web.f_value_by_dimension_json
(
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,                               
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns setof json as
$body$
  select f.data from web.f_catch_data_in_json('value', i_dimension, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f(data) where f.data is not null;
$body$
language sql;

create or replace function web.f_catch_by_dimension_json
(
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_top_count int default 10,
  i_other_params json default null
)
returns setof json as
$body$
  select f.data from web.f_catch_data_in_json('catch', i_dimension, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_top_count, i_other_params) as f(data) where f.data is not null;
$body$
language sql;
-----

-----
create or replace function web.f_dimension_end_use_type_catch_query
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
    ',eu.end_use_name::text' ||
    case when i_measure = 'catch' then ',sum(f.catch_sum)' else ',sum(f.real_value)::numeric' end ||  
    ' from web.v_fact_data f' ||
    additional_join_clause || ', web.end_use_type eu'
    ' where f.end_use_type_id = eu.end_use_type_id  and' ||   
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
    ',eu.end_use_name';
  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;
------
create or replace function web.f_dimension_end_use_type_json
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
    with catch(year, entity_id, end_use_type_id, measure) as (
      select * from web.f_dimension_catch_type_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(end_use_type_id, measure_rank) as (
      select c.end_use_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.end_use_type_id
    )
    select json_agg(fd.*)       
      from (select max(st.name) as key, array_accum(array[array[tm.time_business_key::int, c.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm 
              join ranking r on (true)
              join web.end_use_type eut on (eut.end_use_type_id = r.end_use_type_id)
              left join catch c on (c.year = tm.time_business_key and c.end_use_type_id = eut.end_use_type_id)
             group by eut.end_use_type_id
             order by max(r.measure_rank)
           )
        as fd
  );
$body$
language plpgsql;
------
create or replace function web.f_dimension_end_use_type_tsv
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
    with catch(year, main_area_id, end_use_type_id, measure) as (
      select * from web.f_dimension_end_use_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, true, i_other_params)
    ),
    ranking(end_use_type_id, measure_rank) as (
      select c.end_use_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.end_use_type_id
    ),
    area_name as (
      select * from web.lookup_entity_name_by_entity_layer(i_entity_layer_id, i_entity_id) as t
    )
    select array_to_string(array['year'::text, max(an.name_heading)] || array_agg(t.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.end_use_type t on (t.end_use_type_id = r.end_use_type_id)
      join (select * from area_name limit 1) an on (true)
    union all
    select array_to_string(array[tm.time_business_key::text, max(an.name)] || 
                           array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true)
      join area_name an on (true)
      left join catch c on (c.year = tm.time_business_key and c.main_area_id = an.entity_id and c.end_use_type_id = r.end_use_type_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key, an.entity_id;
  else
    return query
    with catch(year, entity_id, end_use_id, measure) as (
      select * from web.f_dimension_end_use_catch_query(i_measure, i_entity_id, i_sub_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(end_use_type_id, measure_rank) as (
      select c.end_use_type_id, row_number() over(order by sum(c.measure) desc)
        from catch c
       group by c.end_use_type_id
    )
    select array_to_string('year'::text || array_agg(t.name::text order by r.measure_rank), E'\t') 
      from ranking r
      join web.end_use_type t on (t.end_use_type_id = r.end_use_type_id)
    union all
    select array_to_string(tm.time_business_key::text || array_agg(coalesce((c.measure::numeric(20, 3))::text, '')::text order by r.measure_rank), E'\t')
      from web.time tm 
      join ranking r on (true) 
      left join catch c on (c.year = tm.time_business_key and c.end_use_type_id = r.end_use_type_id)
     where tm.time_business_key >= (select min(ci.year) from catch ci)
     group by tm.time_business_key;
  end if;
end
$body$
language plpgsql;
-----