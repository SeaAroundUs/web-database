/**
helper functions
**/


create or replace function fishing_effort.f_dimension_effort_query_layer_preprocessor
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
    when i_entity_layer_id = 100 then 
      main_area_col_name := 'f.fishing_entity_id::int';
    else
      raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;
  
  return query select main_area_col_name, additional_join_clause;
end
$body$
language plpgsql;


create or replace function fishing_effort.f_kw_by_dimension_json
(
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_top_count int default 10,
  i_other_params json default null
)
returns setof json as
$body$
  select f.data from fishing_effort.f_effort_data_in_json('kw', i_dimension, i_entity_id, i_entity_layer_id, i_top_count, i_other_params) as f(data) where f.data is not null;
$body$
language sql;


create or replace function fishing_effort.f_boats_by_dimension_json
(
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_top_count int default 10,
  i_other_params json default null
)
returns setof json as
$body$
  select f.data from fishing_effort.f_effort_data_in_json('boats', i_dimension, i_entity_id, i_entity_layer_id, i_top_count, i_other_params) as f(data) where f.data is not null;
$body$
language sql;


create or replace function fishing_effort.f_co2_by_dimension_json
(
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_top_count int default 10,
  i_other_params json default null
)
returns setof json as
$body$
  select f.data from fishing_effort.f_effort_data_in_json('co2', i_dimension, i_entity_id, i_entity_layer_id, i_top_count, i_other_params) as f(data) where f.data is not null;
$body$
language sql;


create or replace function fishing_effort.f_effort_data_in_json 
(
  i_measure varchar(20),
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_top_count int default 10,
  i_other_params json default null
)                 
returns json as
$body$
  select f.* from fishing_effort.f_dimension_effort_fishing_sector_json(i_measure, i_entity_id, i_entity_layer_id, i_other_params) as f where i_dimension = 'fishing_sector'
  union all
  select f.* from fishing_effort.f_dimension_effort_length_json(i_measure, i_entity_id, i_entity_layer_id, i_other_params) as f where i_dimension = 'length_class'
  union all
  select f.* from fishing_effort.f_dimension_effort_gear_json(i_measure, i_entity_id, i_entity_layer_id, i_other_params) as f where i_dimension = 'gear_type'
   ;   
$body$
language sql;


create or replace function fishing_effort.f_dimension_fishing_sector_effort_query 
(
  i_measure varchar(20),
  i_entity_id int[],
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
    from fishing_effort.f_dimension_effort_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select f.year,' || 
    case when coalesce(i_output_area_id, false) then main_area_col_name else 'null::int' end ||
    ',f.sector_type_id::int' ||
    case when i_measure = 'kw' then ',sum(f.kw_boat)' when i_measure = 'boats' then ',sum(f.number_boats)::numeric' else ',sum(f.co2)::numeric' end ||  
    ' from fishing_effort.v_fishing_effort f' ||
    additional_join_clause ||
    ' where f.fishing_entity_id = any($1) group by f.year' || 
    case when coalesce(i_output_area_id, false) 
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.sector_type_id';

  return query execute rtn_sql
   using i_entity_id;
end
$body$
language plpgsql;


create or replace function fishing_effort.f_dimension_effort_fishing_sector_json
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with effort(year, entity_id, sector_type_id, measure) as (
      select * from fishing_effort.f_dimension_fishing_sector_effort_query(i_measure, i_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(sector_type_id, measure_rank) as (
      select e.sector_type_id, row_number() over(order by sum(e.measure) desc)
        from effort e
       group by e.sector_type_id
    )
    select json_agg(fd.*)       
      from (select max(st.name) as key, array_accum(array[array[tm.time_business_key::int, e.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm 
              join ranking r on (true)
              join web.sector_type st on (st.sector_type_id = r.sector_type_id)
              left join effort e on (e.year = tm.time_business_key and e.sector_type_id = st.sector_type_id)
             group by st.sector_type_id
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;

create or replace function fishing_effort.f_dimension_effort_length_json
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with effort(year, entity_id, length_code, measure) as (
      select * from fishing_effort.f_dimension_length_effort_query(i_measure, i_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(length_code, measure_rank) as (
      select e.length_code, row_number() over(order by sum(e.measure) desc)
        from effort e
       group by e.length_code
    )
    select json_agg(fd.*)       
      from (select max(lc.length_name) as key, array_accum(array[array[tm.time_business_key::int, e.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm 
              join ranking r on (true)
              join fishing_effort.length_class lc on (lc.length_class_id = r.length_code)
              left join effort e on (e.year = tm.time_business_key and e.length_code = lc.length_class_id)
             group by lc.length_class_id
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;


create or replace function fishing_effort.f_dimension_length_effort_query 
(
  i_measure varchar(20),
  i_entity_id int[],
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
    from fishing_effort.f_dimension_effort_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select f.year,' || 
    case when coalesce(i_output_area_id, false) then main_area_col_name else 'null::int' end ||
    ',f.length_code::int' ||
    case when i_measure = 'kw' then ',sum(f.kw_boat)' when i_measure = 'boats' then ',sum(f.number_boats)::numeric' else ',sum(f.co2)::numeric' end ||  
    ' from fishing_effort.v_fishing_effort f' ||
    additional_join_clause ||
    ' where f.fishing_entity_id = any($1) group by f.year' || 
    case when coalesce(i_output_area_id, false) 
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.length_code';

  return query execute rtn_sql
   using i_entity_id;
end
$body$
language plpgsql;


create or replace function fishing_effort.f_dimension_effort_gear_json
(
  i_measure varchar(20),
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
begin
  return (
    with effort(year, entity_id, gear_id, measure) as (
      select * from fishing_effort.f_dimension_gear_effort_query(i_measure, i_entity_id, i_entity_layer_id, area_bucket_id_layer, false, i_other_params)
    ),
    ranking(gear_id, measure_rank) as (
      select e.gear_id, row_number() over(order by sum(e.measure) desc)
        from effort e
       group by e.gear_id
    )
    select json_agg(fd.*)       
      from (select max(g.name) as key, array_accum(array[array[tm.time_business_key::int, e.measure::numeric(20, 2)]] order by tm.time_business_key) as values
              from web.time tm 
              join ranking r on (true)
              join web.gear g on (g.gear_id = r.gear_id)
              left join effort e on (e.year = tm.time_business_key and g.gear_id = e.gear_id)
             group by g.name
             order by max(r.measure_rank)
           )
        as fd
  );
end
$body$
language plpgsql;


create or replace function fishing_effort.f_dimension_gear_effort_query 
(
  i_measure varchar(20),
  i_entity_id int[],
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
    from fishing_effort.f_dimension_effort_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select f.year,' || 
    case when coalesce(i_output_area_id, false) then main_area_col_name else 'null::int' end ||
    ',f.gear_id::int' ||
    case when i_measure = 'kw' then ',sum(f.kw_boat)' when i_measure = 'boats' then ',sum(f.number_boats)::numeric' else ',sum(f.co2)::numeric' end ||  
    ' from fishing_effort.v_fishing_effort f' ||
    additional_join_clause ||
    ' where f.fishing_entity_id = any($1) group by f.year' || 
    case when coalesce(i_output_area_id, false) 
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.gear_id';

  return query execute rtn_sql
   using i_entity_id;
end
$body$
language plpgsql;