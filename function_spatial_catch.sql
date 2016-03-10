create or replace function web.f_spatial_catch_query 
(
  i_fishing_entity_id int[],
  i_year int[],
  i_entity_id int[], 
  i_entity_layer_id int,
  i_reporting_status_id char[], 
  i_catch_status char[], 
  i_grouped_by_entity_layer_id int 
)
returns table(rollup_id varchar, cell_id int, total_catch numeric) as
$body$
declare
  rtn_sql text;
  entity_id_column_name varchar(50);
  grouped_by_column_name varchar(50);
  entity_filtering_clause text;
begin
  if i_entity_id is not null then
    case 
      when i_entity_layer_id = 300 then 
        entity_id_column_name := 'taxon_key';
      when i_entity_layer_id = 500 then 
        entity_id_column_name := 'commercial_group_id';
      when i_entity_layer_id = 600 then
        entity_id_column_name := 'functional_group_id';
      else
        raise exception 'Input entity layer id of % is not supported.', i_entity_layer_id;
    end case;
  end if;
  
  case 
    when i_grouped_by_entity_layer_id is null then
      grouped_by_column_name := '''''';
    when i_grouped_by_entity_layer_id = 100 then 
      grouped_by_column_name := 'cc.fishing_entity_id';
    when i_grouped_by_entity_layer_id = 300 then 
      grouped_by_column_name := 'cc.taxon_key';
    when i_grouped_by_entity_layer_id = 500 then 
      grouped_by_column_name := 'cc.commercial_group_id';
    when i_grouped_by_entity_layer_id = 600 then
      grouped_by_column_name := 'cc.functional_group_id';
    when i_grouped_by_entity_layer_id = 700 then
      grouped_by_column_name := 'cc.reporting_status';
    when i_grouped_by_entity_layer_id = 800 then                   
      grouped_by_column_name := 'cc.catch_status';
    else 
      raise exception 'Input grouped by entity layer id of % is not supported.', i_grouped_by_entity_layer_id;
  end case;
  
  rtn_sql :=
    format('select %s::varchar,cc.cell_id,sum(cc.catch_sum)
              from web.cell_catch cc
             where cc.year = any($1)
               and (case when $2 is null then true else cc.fishing_entity_id = any($2) end)' ||
             case when i_entity_id is null then '' else ' and cc.%s = any($3)' end ||
             case when i_reporting_status_id is null then '' else ' and cc.reporting_status = any($4)' end ||
             case when i_catch_status is null then '' else ' and cc.catch_status = any($5)' end ||
           ' group by %1$s::varchar,cc.cell_id', 
           grouped_by_column_name, 
           entity_id_column_name
    );                                                           

  --DEBUG ONLY
  --raise info 'rtn_sql: %', rtn_sql;

  return query execute rtn_sql                   
  using i_year, i_fishing_entity_id, i_entity_id, i_reporting_status_id, i_catch_status;
end
$body$                                         
language plpgsql;

create or replace function web.f_spatial_catch_json_in_ptile 
(
  i_fishing_entity_id int[],
  i_year int[],                                                                                
  i_percentile_bucket numeric[],
  i_entity_id int[] default null::int[], 
  i_entity_layer_id int default null::int,
  i_reporting_status_id char[] default null::int[], 
  i_catch_status char[] default null::int[], 
  i_grouped_by_entity_layer_id int default 100
)
returns json as
$body$
  with catch(rollup_key, cell_id, total_catch, cell_catch_per_km2) as (
    select f.*, 
           (f.total_catch / ce.water_area)::numeric
      from web.f_spatial_catch_query(i_fishing_entity_id, i_year, i_entity_id, i_entity_layer_id, i_reporting_status_id, i_catch_status, i_grouped_by_entity_layer_id) as f
      join allocation.cell ce on (ce.cell_id = f.cell_id)
  ),
  bucket_amounts(amount, min_catch, max_catch) as (
    select percentile_cont(i_percentile_bucket) within group (order by c.cell_catch_per_km2), 
           min(c.cell_catch_per_km2), 
           max(c.cell_catch_per_km2) 
      from catch c
  ),
  bucket_ranges(threshold, bucket_range) as (
    select s.idx, (format('(%s,%s]', coalesce(ba.amount[s.idx-1]::varchar, ''), coalesce(ba.amount[s.idx]::varchar, '')))::numrange 
      from bucket_amounts ba, generate_series(1, array_upper(i_percentile_bucket, 1) + 1, 1) as s(idx)  
  ),
  rollup(rollup_key, total_catch) as (
    select c.rollup_key,
           sum(c.total_catch)/1000.0
      from catch c
     group by c.rollup_key
  )
  select row_to_json(t.*) 
    from (select ba.min_catch, 
                 ba.max_catch,
                 ba.amount as bucket_boundaries,
                 array(select json_build_object('threshold', br.threshold, 'range', br.bucket_range) from bucket_ranges br) as bucket_ranges,
                 (select json_agg(roll.*) 
                    from (select r.rollup_key,
                                 r.total_catch,
                                 array(select json_build_object('threshold', brs.threshold, 'cells', array_agg(c.cell_id))
                                         from catch c
                                         join bucket_ranges brs on (c.cell_catch_per_km2 <@ brs.bucket_range) 
                                        where c.rollup_key = r.rollup_key
                                        group by brs.threshold
                                        order by brs.threshold) as data
                            from rollup r
                         ) roll
                 ) as rollup
            from bucket_amounts ba
         ) as t
   where t.min_catch is not null;
$body$
language sql;

create or replace function web.f_spatial_catch_json_in_ntile 
(
  i_fishing_entity_id int[],
  i_year int[],                                                                                
  i_number_of_buckets int,
  i_entity_id int[] default null::int[], 
  i_entity_layer_id int default null::int,
  i_reporting_status_id char[] default null::int[], 
  i_catch_status char[] default null::int[], 
  i_grouped_by_entity_layer_id int default 100
)
returns json as
$body$
  with catch(rollup_key, cell_id, total_catch, cell_catch_per_km2, tile) as (
    select f.*, f.total_catch / ce.water_area, ntile(i_number_of_buckets) over (order by (f.total_catch/ce.water_area)) 
      from web.f_spatial_catch_query(i_fishing_entity_id, i_year, i_entity_id, i_entity_layer_id, i_reporting_status_id, i_catch_status, i_grouped_by_entity_layer_id) as f
      join allocation.cell ce on (ce.cell_id = f.cell_id)
  ),
  bucket_amounts(tile, amount) as (
    select tile, max(c.cell_catch_per_km2) 
      from catch c
     where tile < i_number_of_buckets
     group by tile
  )
  select row_to_json(t.*) 
    from (select min(c.cell_catch_per_km2) as min_catch,
                 max(c.cell_catch_per_km2) as max_catch,
                 (select array_agg(ba.amount order by ba.tile) from bucket_amounts ba) as bucket_boundaries,
                 (select json_agg(roll.*)         
                    from (select cr.rollup_key,
                                 sum(cr.total_catch)/1000.0 as total_catch,
                                 array(select json_build_object('threshold', c2.tile, 'cells', array_agg(c2.cell_id))
                                         from catch c2
                                        where c2.rollup_key = cr.rollup_key
                                        group by c2.tile
                                        order by c2.tile) as data
                            from catch cr
                           group by cr.rollup_key
                         ) roll
                 ) as rollup
            from catch c) as t
   where t.min_catch is not null;
$body$
language sql;

create or replace function web.f_spatial_catch_json_in_plog 
(
  i_fishing_entity_id int[],
  i_year int[],                                                                                
  i_percentile_bucket numeric[],
  i_entity_id int[] default null::int[], 
  i_entity_layer_id int default null::int,
  i_reporting_status_id char[] default null::int[], 
  i_catch_status char[] default null::int[], 
  i_grouped_by_entity_layer_id int default 100
)
returns json as
$body$
  with catch(rollup_key, cell_id, total_catch, cell_catch_per_km2) as (
    select f.*, (f.total_catch / ce.water_area)::numeric 
      from web.f_spatial_catch_query(i_fishing_entity_id, i_year, i_entity_id, i_entity_layer_id, i_reporting_status_id, i_catch_status, i_grouped_by_entity_layer_id) as f
      join allocation.cell ce on (ce.cell_id = f.cell_id)
  ),
  bucket_amounts(amount, min_catch, max_catch) as (
    select percentile_cont(i_percentile_bucket) within group (order by log(c.cell_catch_per_km2)), 
           min(c.cell_catch_per_km2), 
           max(c.cell_catch_per_km2)
      from catch c
  ),
  bucket_ranges(threshold, bucket_range) as (
    select s.idx, (format('(%s,%s]', coalesce(ba.amount[s.idx-1]::varchar, ''), coalesce(ba.amount[s.idx]::varchar, '')))::numrange 
      from bucket_amounts ba, generate_series(1, array_upper(i_percentile_bucket, 1) + 1, 1) as s(idx)  
  ),
  rollup(rollup_key, total_catch) as (
    select c.rollup_key,
           sum(c.total_catch)/1000.0
      from catch c
     group by c.rollup_key
  )
  select row_to_json(t.*) 
    from (select ba.min_catch, 
                 ba.max_catch,
                 ba.amount as bucket_boundaries,
                 (select json_agg(roll.*) 
                    from (select r.rollup_key,
                                 r.total_catch,
                                 array(select json_build_object('threshold', brs.threshold, 'cells', array_agg(c.cell_id))
                                         from catch c
                                         join bucket_ranges brs on (log(c.cell_catch_per_km2) <@ brs.bucket_range) 
                                        where c.rollup_key = r.rollup_key
                                        group by brs.threshold
                                        order by brs.threshold) as data
                            from rollup r
                         ) roll
                 ) as rollup
            from bucket_amounts ba
         ) as t 
   where t.min_catch is not null;
$body$
language sql;

create or replace function web.f_spatial_catch_json_in_nlog 
(
  i_fishing_entity_id int[],
  i_year int[],                                                                                
  i_number_of_buckets int,
  i_entity_id int[] default null::int[], 
  i_entity_layer_id int default null::int,
  i_reporting_status_id char[] default null::int[], 
  i_catch_status char[] default null::int[], 
  i_grouped_by_entity_layer_id int default 100
)
returns json as
$body$
  with catch(rollup_key, cell_id, total_catch, cell_catch_per_km2, tile) as (
    select f.*, f.total_catch / ce.water_area, ntile(i_number_of_buckets) over (order by log(f.total_catch/ce.water_area)) 
      from web.f_spatial_catch_query(i_fishing_entity_id, i_year, i_entity_id, i_entity_layer_id, i_reporting_status_id, i_catch_status, i_grouped_by_entity_layer_id) as f
      join allocation.cell ce on (ce.cell_id = f.cell_id)
  ),
  bucket_amounts(tile, amount) as (
    select tile, max(c.cell_catch_per_km2) 
      from catch c
     where tile < i_number_of_buckets
     group by tile
  )
  select row_to_json(t.*) 
    from (select min(c.cell_catch_per_km2) as min_catch,
                 max(c.cell_catch_per_km2) as max_catch,
                 (select array_agg(ba.amount order by ba.tile) from bucket_amounts ba) as bucket_boundaries,
                 (select json_agg(roll.*)         
                    from (select cr.rollup_key,
                                 sum(cr.total_catch)/1000.0 as total_catch,
                                 array(select json_build_object('threshold', c2.tile, 'cells', array_agg(c2.cell_id))
                                         from catch c2
                                        where c2.rollup_key = cr.rollup_key
                                        group by c2.tile
                                        order by c2.tile) as data
                            from catch cr
                           group by cr.rollup_key
                         ) roll
                 ) as rollup
            from catch c) as t
   where t.min_catch is not null;
$body$
language sql;

create or replace function web.f_spatial_catch_json 
(
  i_year int[],
  i_fishing_entity_id int[] default null::int[],
  i_number_of_buckets int default 5,
  i_bucketing_method varchar(20) default 'ptile', 
  i_entity_id int[] default null::int[], 
  i_entity_layer_id int default null::int,
  i_reporting_status_id char[] default null::int[], 
  i_catch_status char[] default null::int[], 
  i_grouped_by_entity_layer_id int default null
)
returns setof json as         
$body$
begin
  if i_fishing_entity_id is null 
     and coalesce(i_bucketing_method, 'ptile') = 'ptile' 
     and i_entity_id is null 
     and i_reporting_status_id is null 
     and i_catch_status is null 
     and i_grouped_by_entity_layer_id is null 
  then
    return query select result from web.cell_catch_global_cache where year = any(i_year);
  else
    return query
      with dat(json) as (   
        select web.f_spatial_catch_json_in_ptile(
                           i_fishing_entity_id,
                           i_year,                                                                                
                           (select array_agg(((1.0/i_number_of_buckets)*g.idx)::numeric) from generate_series(1, i_number_of_buckets-1, 1) as g(idx)),
                           i_entity_id, 
                           i_entity_layer_id,
                           i_reporting_status_id, 
                           i_catch_status, 
                           i_grouped_by_entity_layer_id)
         where i_bucketing_method = 'ptile'
        union all
        select web.f_spatial_catch_json_in_ntile(
                           i_fishing_entity_id,
                           i_year,                                                                                
                           i_number_of_buckets,
                           i_entity_id, 
                           i_entity_layer_id,
                           i_reporting_status_id, 
                           i_catch_status, 
                           i_grouped_by_entity_layer_id)
         where i_bucketing_method = 'ntile'
        union all
        select web.f_spatial_catch_json_in_plog(
                           i_fishing_entity_id,
                           i_year,                                                                                
                           (select array_agg(((1.0/i_number_of_buckets)*g.idx)::numeric) from generate_series(1, i_number_of_buckets-1, 1) as g(idx)),
                           i_entity_id, 
                           i_entity_layer_id,
                           i_reporting_status_id, 
                           i_catch_status, 
                           i_grouped_by_entity_layer_id)
         where i_bucketing_method = 'plog'
        union all
        select web.f_spatial_catch_json_in_nlog(
                           i_fishing_entity_id,
                           i_year,                                                                                
                           i_number_of_buckets,
                           i_entity_id, 
                           i_entity_layer_id,
                           i_reporting_status_id, 
                           i_catch_status, 
                           i_grouped_by_entity_layer_id)
         where i_bucketing_method = 'nlog'
      )
      select * from dat where json is not null;
  end if;
end
$body$
language plpgsql;
