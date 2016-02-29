/******
 Functions to support the new MT and UI
******/
create or replace function web.f_marine_trophic_index_query 
(
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_taxon_exclusion_list int[] default null,
  i_area_bucket_id_layer int default null,
  i_other_params json default null
)
returns table(entity_id int, year int, catch_sum int, catch_trophic_level numeric(50, 10), catch_max_length numeric(50, 10)) as
$body$
declare
  rtn_sql text;
  main_area_col_name text;
  additional_join_clause text := '';
  taxon_exclusion_list int[] := array[100000, 100011, 100025, 100039, 100047, 100058, 100077, 100139, 100239, 100339] || i_taxon_exclusion_list;
begin
  select *
    into main_area_col_name, additional_join_clause
    from web.f_dimension_catch_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select ' || main_area_col_name || ', f.year, sum(f.catch_sum)::int as catch_sum, sum(f.catch_trophic_level)::numeric(50, 10), sum(f.catch_max_length)::numeric(50, 10)
       from web.v_fact_data f' || 
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' f.marine_layer_id = ' || i_entity_layer_id || ' and f.main_area_id = any($1) and'
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then ' f.taxon_key = any($1) and'
    else ''
     end ||
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when array_length(coalesce($2, ''{}''::int[]), 1) is null then true else f.sub_area_id = any($2) end) and' ||
    ' f.taxon_key != all($3)' ||
    ' group by ' || main_area_col_name || ', f.year';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id, taxon_exclusion_list;
end
$body$
language plpgsql;

create or replace function web.f_marine_trophic_index(
  i_entity_id int[], 
  i_entity_layer_id int default 1, 
  i_sub_area_id int[] default null::int[], 
  i_taxon_exclusion_list int[] default null, 
  i_base_year int default 1950, 
  i_transfer_efficiency numeric default 0.1, 
  i_other_params json default null
)
returns table(entity_id integer, entity_layer_id integer, year integer, mean_trophic_level numeric(6,2), mean_max_length numeric(6,1), fib_index numeric(6,2), expansion_factor numeric(10,2), catch_sum integer) as
$body$
declare
  taxon_exclusion_list int[] := array[100000, 100011, 100025, 100039, 100047, 100058, 100077, 100139, 100239, 100339] || i_taxon_exclusion_list;
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  te_fraction numeric := 1.0/coalesce(i_transfer_efficiency, 0.1);
  base_year int := coalesce(i_base_year, 1950);
begin
  return query
  with fact(entity_id, year, catch_sum, catch_trophic_level, catch_max_length) as (
    select * from web.f_marine_trophic_index_query(i_entity_id, i_sub_area_id, i_entity_layer_id, i_taxon_exclusion_list, area_bucket_id_layer, i_other_params)
  ),
  factwithmean as (
    select f.entity_id, f.year, 
           (case when f.catch_sum = 0 then null else f.catch_sum end) as catch_sum, 
           f.catch_trophic_level, 
           (case when f.catch_sum = 0 then null else (f.catch_trophic_level/f.catch_sum)::numeric(6,2) end) as mean_trophic_level, 
           f.catch_max_length, 
           (case when f.catch_sum = 0 then null else (f.catch_max_length/f.catch_sum)::numeric(6,1) end) mean_max_length
      from fact f
  ),
  areabaseyear as (
    select distinct fwm.entity_id, first_value(fwm.catch_sum) over(w) as catch_sum, first_value(fwm.mean_trophic_level) over(w) as mean_trophic_level
      from factwithmean fwm
     where fwm.catch_sum != 0 and fwm.year >= base_year
    window w as (partition by fwm.entity_id order by case when fwm.year = base_year then 0 else fwm.year end)
  ),
  factwithfib as (
    select fwm.*,
           coalesce(ln(fwm.catch_sum * power(te_fraction, fwm.mean_trophic_level)) - ln(aby.catch_sum * power(te_fraction, aby.mean_trophic_level)), 0.0)::numeric(6,2) fib
      from factwithmean fwm
      left join areabaseyear aby on (aby.entity_id = fwm.entity_id)
  ),
  timewitharea as (
    select a.id as entity_id, t.time_business_key as year
      from web.time t, unnest(i_entity_id) as a(id)
  )
  select twa.entity_id, i_entity_layer_id, twa.year, fwf.mean_trophic_level, fwf.mean_max_length, fwf.fib, exp(fwf.fib)::numeric(10,2) as expansion_factor, fwf.catch_sum 
    from timewitharea twa
    left join factwithfib fwf on (fwf.entity_id = twa.entity_id and fwf.year = twa.year)
   order by twa.entity_id, twa.year;
end;
$body$
language plpgsql;

create or replace function web.f_marine_trophic_index(i_entity_id int, i_entity_layer_id int default 1, i_sub_area_id int[] default null::int[], i_taxon_exclusion_list int[] default null, i_base_year int default 1950, i_transfer_efficiency numeric default 0.1, i_other_params json default null)
returns table(entity_id integer, entity_layer_id integer, year integer, mean_trophic_level numeric(6,2), mean_max_length numeric(6,1), fib_index numeric(6,2), expansion_factor numeric(10,2), catch_sum integer) as
$body$
  select * from web.f_marine_trophic_index(array[i_entity_id]::int[], i_entity_layer_id, i_sub_area_id, i_taxon_exclusion_list, i_base_year, i_transfer_efficiency, i_other_params);
$body$
language sql;

create or replace function web.f_marine_trophic_index_species_list(i_main_area_id int[], i_marine_layer_id int default 1, i_sub_area_id int[] default null::int[], i_taxon_exclusion_list int[] default null)
returns table(main_area_id integer, marine_layer_id integer, taxon_key int, catch_sum numeric(50,20), trophic_level numeric(50,20), sl_max int, common_name varchar(255), scientific_name varchar(255)) as
$body$
declare
  taxon_exclusion_list int[] := array[100000, 100011, 100025, 100039, 100047, 100058, 100077, 100139, 100239, 100339] || i_taxon_exclusion_list;
begin
  return query
  select f.main_area_id,
         f.marine_layer_id,
         f.taxon_key,
         sum(f.catch_sum),
         min(t.tl) as trophic_level,
         min(t.sl_max_cm) as sl_max,
         min(t.common_name)::varchar(255),
         min(t.scientific_name)::varchar(255)
    from v_fact_data f
         join v_web_taxon t on (t.taxon_key = f.taxon_key)
   where f.taxon_key != all(taxon_exclusion_list)
     and f.main_area_id = any(i_main_area_id)
     and f.marine_layer_id = i_marine_layer_id
     and (case when i_sub_area_id is null or array_length(i_sub_area_id, 1) = 0 then true else f.sub_area_id = any(i_sub_area_id) end)
   group by f.main_area_id, f.marine_layer_id, f.taxon_key
   order by f.main_area_id, f.marine_layer_id, trophic_level desc, sl_max desc;
end
$body$
language plpgsql;

create or replace function web.f_marine_trophic_index_species_list(i_main_area_id int, i_marine_layer_id int default 1, i_sub_area_id int[] default null::int[], i_taxon_exclusion_list int[] default null)
returns table(main_area_id integer, marine_layer_id integer, taxon_key int, catch_sum numeric(50,20), trophic_level numeric(50,20), sl_max int, common_name varchar(255), scientific_name varchar(255)) as
$body$
  select * from web.f_marine_trophic_index_species_list(array[i_main_area_id]::int[], i_marine_layer_id, i_sub_area_id, i_taxon_exclusion_list);
$body$
language sql;


create or replace function web.f_marine_trophic_index_species_list_json(
  i_entity_id int[], 
  i_entity_layer_id int default 1, 
  i_sub_entity_id int[] default null::int[], 
  i_taxon_exclusion_list int[] default null, 
  i_other_params json default null
)
returns setof json as
$body$
declare
  data_sql text;
  main_area_col_name text;
  additional_join_clause text := '';
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  taxon_exclusion_list int[] := array[100000, 100011, 100025, 100039, 100047, 100058, 100077, 100139, 100239, 100339] || i_taxon_exclusion_list;
begin
  select *
    into main_area_col_name, additional_join_clause
    from web.f_dimension_catch_query_layer_preprocessor(i_entity_layer_id, area_bucket_id_layer, i_other_params);

  data_sql :=
    'select ' || main_area_col_name || ' as entity_id,' || i_entity_layer_id || 
            ' as entity_layer_id, f.taxon_key, sum(f.catch_sum) as catch_sum, min(t.tl) as trophic_level, min(t.sl_max_cm) as sl_max, min(t.common_name)::varchar(255) as common_name, min(t.scientific_name)::varchar(255) as scientific_name
       from web.v_fact_data f 
       join v_web_taxon t on (t.taxon_key = f.taxon_key)' ||
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' f.marine_layer_id = ' || i_entity_layer_id || ' and f.main_area_id = any($1) and'
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then ' f.taxon_key = any($1) and'
    else ''
     end ||
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when array_length(coalesce($2, ''{}''::int[]), 1) is null then true else f.sub_area_id = any($2) end) and' ||
    ' f.taxon_key != all($3)' ||
    ' group by ' || main_area_col_name || ', f.taxon_key
      order by ' || main_area_col_name || ', trophic_level desc, sl_max desc';

  return query execute ('select json_agg(fd.*) from (' || data_sql || ') as fd')
   using i_entity_id, i_sub_entity_id, taxon_exclusion_list;
end
$body$
language plpgsql;

create or replace function web.f_marine_trophic_index_species_list_json(
  i_entity_id int[], 
  i_entity_layer_id int default 1, 
  i_sub_entity_id int[] default null::int[], 
  i_taxon_exclusion_list int[] default null, 
  i_other_params json default null
)
returns setof json as
$body$
  select * from web.f_marine_trophic_index_species_list_json(array[i_entity_id]::int[], i_entity_layer_id, i_sub_entity_id, i_taxon_exclusion_list, i_other_params);
$body$
language sql;


/* 
    Stock Status 
*/
create or replace function web.f_stock_status_category_heading() returns text[] as
$body$
  select array['Collapsed', 'Over-exploited', 'Exploited', 'Developing', 'Rebuilding'];
$body$
language sql;

create or replace function web.f_stock_status_query 
(
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_other_params json default null
)
returns table(year int, taxon_key int, catch_sum numeric) as
$body$
declare
  rtn_sql text;
  main_area_col_name text;
  additional_join_clause text := '';
  taxon_exclusion_list constant int[] := array[100000, 100011, 100025, 100039, 100047, 100058, 100077, 100139, 100239, 100339];
begin
  select *
    into main_area_col_name, additional_join_clause
    from web.f_dimension_catch_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select f.year, f.taxon_key, sum(f.catch_sum)
       from web.v_fact_data f' ||
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' f.marine_layer_id = ' || i_entity_layer_id || ' and f.main_area_id = any($1) and'
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then ' f.taxon_key = any($1) and'
    else ''
     end ||
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when array_length(coalesce($2, ''{}''::int[]), 1) is null then true else f.sub_area_id = any($2) end) and' ||
    ' f.taxon_key != all($3)' ||
    ' group by f.year, f.taxon_key';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id, taxon_exclusion_list;
end
$body$
language plpgsql;

create or replace function web.get_data_for_stock_status(
  i_entity_id int[], 
  i_entity_layer_id int default 1, 
  i_sub_area_id int[] default null::int[],
  i_other_params json default null
)
returns table(year integer, taxon int, catch_sum numeric(50,20), peak_year int, peak_catch_sum numeric(50,20), final_year int, post_peak_min_year int, post_peak_min_catch_sum numeric(50,20)) as
$body$
  with fact(year, taxon_key, year_taxon_catch_sum) as (
    select * from web.f_stock_status_query(i_entity_id, i_sub_area_id, i_entity_layer_id, case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end, i_other_params)
  ),
  factwithsum(year, taxon, catch_sum) as (
    select dim.year, dim.taxon_key, f.year_taxon_catch_sum::numeric(20)
      from (select dt.time_business_key as year, taxon.taxon_key 
              from web.v_dim_time dt, 
                   (select distinct f2.taxon_key from fact as f2) as taxon) as dim
      left join fact f on (f.year = dim.year and f.taxon_key = dim.taxon_key)
  ),
  catch as (
    select s.*,
           first_value(s.year) over (peak_window) as peak_year,
           first_value(s.catch_sum) over (peak_window) as peak_catch_sum,
           (case 
            when coalesce(s.catch_sum, 0) = 0 
            then 0 
            else sum(case when coalesce(s.catch_sum, 0) = 0 then 0 else 1 end) over (partition by s.taxon order by s.year::int 
                                                                                     rows between current row and 4 following) 
             end)::int as positive_catch_count  
      from factwithsum s
    window peak_window as (partition by s.taxon order by case when coalesce(s.catch_sum, 0) = 0 then 0 else s.catch_sum end desc)
  ),
  taxon_filter(taxon, final_year) as (
      -- Only taxons having at least 1000 tonnes of catch, at least 10 years of reported landings and at least 5 years of consecutive catches are considered 
      select c.taxon, max(c.year)
        from catch c
       where coalesce(c.catch_sum, 0) > 0 
       group by c.taxon
      having sum(c.catch_sum) >= 1000 and (max(c.year)::int - min(c.year)::int + 1) >= 10 and max(c.positive_catch_count) >= 5
  )
  select c.year, tf.taxon, c.catch_sum, c.peak_year, c.peak_catch_sum, tf.final_year,
         first_value(c.year) over (post_peak_window) as post_peak_min_year,
         first_value(c.catch_sum) over (post_peak_window) as post_peak_min_catch_sum
    from catch c
    join taxon_filter tf on (tf.taxon = c.taxon)
   where coalesce(c.catch_sum, 0) != 0
  window post_peak_window as (partition by tf.taxon order by case when c.year > c.peak_year then c.catch_sum else null end nulls last) 
   order by tf.taxon, c.year;
$body$
language sql;

create or replace function web.f_stock_status_json(
  i_entity_id int[], 
  i_entity_layer_id int default 1, 
  i_sub_area_id int[] default null::int[],
  i_other_params json default null                                                                       
)
returns json 
as
$body$
declare
  COLLAPSED constant smallint := 1; 
  OVER_EXPLOITED constant smallint := 2; 
  EXPLOITED constant smallint := 3; 
  DEVELOPING constant smallint := 4; 
  REBUILDING constant smallint := 5;
  UNKNOWN constant smallint := 6;
begin
  return(
  with categorized as (
    select t.year, t.taxon, t.catch_sum,
           (case 
            when (t.peak_year = t.final_year) or ((t.year <= t.peak_year) and (t.catch_sum <= (t.peak_catch_sum * .50))) then DEVELOPING
            when t.catch_sum > (t.peak_catch_sum * .50) then EXPLOITED
            when (t.catch_sum > (t.peak_catch_sum * .10)) and (t.catch_sum < (t.peak_catch_sum * .50)) and (t.post_peak_min_catch_sum < (t.peak_catch_sum * 0.1)) and (t.year > t.post_peak_min_year) then REBUILDING
            when (t.catch_sum > (t.peak_catch_sum * .10)) and (t.catch_sum < (t.peak_catch_sum * .50)) and (t.year > t.peak_year) then OVER_EXPLOITED
            when (t.catch_sum <= (t.peak_catch_sum * .10)) and (t.year > t.peak_year) then COLLAPSED
            else UNKNOWN
             end) as category_id
      from web.get_data_for_stock_status(i_entity_id, i_entity_layer_id, i_sub_area_id, i_other_params) t
  ),
  catch_sum_tally(category_id, year, category_catch_sum) as (
    select t.category_id, t.year, sum(t.catch_sum)  
      from categorized t
     where t.category_id != UNKNOWN
     group by t.category_id, t.year
  ),
  stock_count(year, year_taxon_count, year_catch_sum) as (
    select t.year, count(distinct taxon), sum(t.catch_sum) 
      from categorized t
     where t.category_id != UNKNOWN
     group by t.year
  ),
  year_window(begin_year, end_year) as ( 
    select min(t.year), max(t.year) 
      from categorized t
     where t.category_id != UNKNOWN
  ),                
  sum_data(taxa_count, should_be_displayed) as (
    select taxa_count,
           case when i_entity_layer_id = 1 then case when t.cellCount > 30 and t.taxa_count > 10 then true else false end else true end 
      from (select (select count(distinct taxon)::int from categorized) as taxa_count,
                   (select sum(a.number_of_cells) from web.area a where a.main_area_id = any(i_entity_id) and a.marine_layer_id = i_entity_layer_id and coalesce(a.sub_area_id = any(i_sub_area_id), true)) as cellCount) as t
  ),                                                                                                                 
  category_lookup as (
    select u.category, u.ordinality as category_id
      from unnest(web.f_stock_status_category_heading()) with ordinality as u(category)
  )
  select json_build_object(
           'css',                         
           (select json_agg(fd.*) 
              from (select c.category as key,
                           (select array_accum(array[array[t.time_business_key::numeric, coalesce(val, 0.0)]] order by t.time_business_key)
                              from web.time t
                              left join (select cst.year,
                                                ((case when cst.year in (yw.begin_year, yw.end_year) then cst.category_catch_sum 
                                                       else avg(cst.category_catch_sum) over(order by cst.year rows between 1 preceding and 1 following) 
                                                   end)*100.0/sc.year_catch_sum)::numeric(8,2) as val
                                           from catch_sum_tally cst
                                           join stock_count sc on (sc.year = cst.year)
                                          where cst.category_id = c.category_id) as v   
                                on (v.year = t.time_business_key)        
                           ) as values
                      from category_lookup c
                      join sum_data sd on (sd.should_be_displayed)
                      join year_window yw on (true)
                     where exists (select 1 from catch_sum_tally cs where cs.category_id = c.category_id limit 1)
                     order by c.category_id) as fd                                               
           ),                    
           'nss',
           (select json_agg(fd.*)  
              from (select c.category as key,
                           (select array_accum(array[array[t.time_business_key::numeric, coalesce(val, 0.0)]] order by t.time_business_key)
                              from web.time t
                              left join (select cz.year, (count(*)*100.0/sc.year_taxon_count)::numeric(8,2) val
                                           from categorized cz
                                           join stock_count sc on (sc.year = cz.year) 
                                          where cz.category_id = c.category_id
                                          group by cz.year, sc.year_taxon_count) as v
                                on (v.year = t.time_business_key)        
                           ) as values
                      from category_lookup c
                      join sum_data sd on sd.should_be_displayed
                     where exists (select 1 from catch_sum_tally cs where cs.category_id = c.category_id limit 1)
                     order by c.category_id) as fd 
           ),
           'summary',
           json_build_object('n', (select (case when should_be_displayed then taxa_count else 0 end)::int from sum_data))
         )                                                             
  );
end
$body$
language plpgsql;

create or replace function web.f_stock_status_csv(
  i_entity_id int[], 
  i_entity_layer_id int default 1, 
  i_sub_area_id int[] default null::int[],
  i_other_params json default null                                                                       
)
returns setof text 
as
$body$
declare
  COLLAPSED constant smallint := 1; 
  OVER_EXPLOITED constant smallint := 2; 
  EXPLOITED constant smallint := 3; 
  DEVELOPING constant smallint := 4; 
  REBUILDING constant smallint := 5;
  UNKNOWN constant smallint := 6;
begin
  return query
  with categorized as (
    select t.year, t.taxon, t.catch_sum,
           (case 
            when (t.peak_year = t.final_year) or ((t.year <= t.peak_year) and (t.catch_sum <= (t.peak_catch_sum * .50))) then DEVELOPING
            when t.catch_sum > (t.peak_catch_sum * .50) then EXPLOITED
            when (t.catch_sum > (t.peak_catch_sum * .10)) and (t.catch_sum < (t.peak_catch_sum * .50)) and (t.post_peak_min_catch_sum < (t.peak_catch_sum * 0.1)) and (t.year > t.post_peak_min_year) then REBUILDING
            when (t.catch_sum > (t.peak_catch_sum * .10)) and (t.catch_sum < (t.peak_catch_sum * .50)) and (t.year > t.peak_year) then OVER_EXPLOITED
            when (t.catch_sum <= (t.peak_catch_sum * .10)) and (t.year > t.peak_year) then COLLAPSED
            else UNKNOWN
             end) as category_id
      from web.get_data_for_stock_status(i_entity_id, i_entity_layer_id, i_sub_area_id, i_other_params) t
  ),
  catch_sum_tally(category_id, year, category_catch_sum) as (
    select t.category_id, t.year, sum(t.catch_sum)  
      from categorized t
     where t.category_id != UNKNOWN
     group by t.category_id, t.year
  ),
  stock_count(year, year_taxon_count, year_catch_sum) as (
    select t.year, count(distinct taxon), sum(t.catch_sum) 
      from categorized t
     where t.category_id != UNKNOWN
     group by t.year
  ),
  year_window(begin_year, end_year) as ( 
    select min(t.year), max(t.year) 
      from categorized t
     where t.category_id != UNKNOWN
  ),                
  sum_data(taxa_count, should_be_displayed) as (
    select taxa_count,
           case when i_entity_layer_id = 1 then case when t.cellCount > 30 and t.taxa_count > 10 then true else false end else true end 
      from (select (select count(distinct taxon)::int from categorized) as taxa_count,
                   (select sum(a.number_of_cells) from web.area a where a.main_area_id = any(i_entity_id) and a.marine_layer_id = i_entity_layer_id and coalesce(a.sub_area_id = any(i_sub_area_id), true)) as cellCount) as t
  ),                                                                                                                 
  category_lookup as (
    select u.category, u.ordinality as category_id
      from unnest(web.f_stock_status_category_heading()) with ordinality as u(category)
  )
  (select array_to_string(array['Data_Set', 'Year'] || web.f_stock_status_category_heading(), ','))
  union all
  (select array_to_string(array['css', t.time_business_key::text] ||
                          array(select coalesce(v.val, 0.0)
                             from category_lookup cl
                             left join (select cst.category_id,
                                               ((case when cst.year in (yw.begin_year, yw.end_year) then cst.category_catch_sum 
                                                 else avg(cst.category_catch_sum) over(order by cst.year rows between 1 preceding and 1 following) 
                                                  end)*100.0/sc.year_catch_sum)::numeric(8,2) as val
                                          from catch_sum_tally cst  
                                          join stock_count sc on (sc.year = cst.year)
                                         where cst.year = t.time_business_key) as v
                                    on (v.category_id = cl.category_id)
                                 order by cl.category_id   
                          )::text[],
                          ','
                         ) as values
     from web.time t
     join year_window yw on (true)
     join sum_data sd on (sd.should_be_displayed)
  )
  union all
  (select array_to_string(array['nss', t.time_business_key::text] ||
                          array(select coalesce(v.val, 0.0)
                             from category_lookup cl
                             left join (select cz.category_id, (count(*)*100.0/sc.year_taxon_count)::numeric(8,2) val
                                          from categorized cz
                                          join stock_count sc on (sc.year = cz.year) 
                                         where cz.year = t.time_business_key  
                                         group by cz.category_id, sc.year_taxon_count) as v
                                    on (v.category_id = cl.category_id)
                                 order by cl.category_id   
                          )::text[],
                          ','
                         ) as values
     from web.time t
     join sum_data sd on (sd.should_be_displayed)
  )
  /*
  union all 
  (select 'nss',
     from (select c.category as key,
                  (select array_accum(array[array[t.time_business_key::numeric, coalesce(val, 0.0)]] order by t.time_business_key)
                     from web.time t
                     left join (select cz.year, (count(*)*100.0/sc.year_taxon_count)::numeric(8,2) val
                                  from categorized cz
                                  join stock_count sc on (sc.year = cz.year) 
                                 where cz.category_id = c.category_id
                                 group by cz.year, sc.year_taxon_count) as v
                       on (v.year = t.time_business_key)        
                  ) as values
             from category_lookup c
             join sum_data sd on sd.should_be_displayed
            where exists (select 1 from catch_sum_tally cs where cs.category_id = c.category_id limit 1)
            order by c.category_id) as fd 
  )
  */
  ;
end
$body$
language plpgsql;

/* 
    f_multinational_footprint 
*/
create or replace function web.f_multinational_footprint_query 
(
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_other_params json default null
)
returns table(fishing_entity_id int, year int, ppf numeric(7, 4)) as
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
    'select f.fishing_entity_id::int, f.year, sum(case when a.primary_production = 0 then 0 else f.primary_production_required / a.primary_production end)::numeric(7,4)
       from web.v_fact_data f 
       join web.v_dim_area a on (f.area_key = a.area_key)' ||
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' f.marine_layer_id = ' || i_entity_layer_id || ' and f.main_area_id = any($1) and'
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    when i_entity_layer_id = 300 then ' f.taxon_key = any($1) and'
    else ''
     end ||
    case when i_entity_layer_id in (100, 300, 500, 600, 700, 800) then ' f.marine_layer_id in (1, 2) and' else '' end ||
    ' (case when array_length(coalesce($2, ''{}''::int[]), 1) is null then true else f.sub_area_id = any($2) end)' ||
    ' group by f.fishing_entity_id, f.year';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_multinational_footprint 
(
  i_entity_id int[],
  i_entity_layer_id int = 1,
  i_sub_area_id int[] default null::int[],
  i_top_count_per_main_areaq int = 11,
  i_other_params json default null
)
returns table(year varchar(100), fishing_entity varchar(100), primary_production_fraction numeric, grand_total numeric, maximum_fraction numeric) as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  home_fishing_entity_id smallint := (select e.is_home_eez_of_fishing_entity_id from web.eez e where e.eez_id = i_entity_id[1] and i_entity_layer_id = 1);
begin
  return query
  with catch(fishing_entity_id, year, primary_production_fraction) as (
    select * from web.f_multinational_footprint_query(i_entity_id, i_sub_area_id, i_entity_layer_id, area_bucket_id_layer, i_other_params)
  ),
  top(fishing_entity_id, catch_rank) as (
    select t.fishing_entity_id, t.row_num 
      from (select c.fishing_entity_id, row_number() over(order by case when i_entity_layer_id = 1 then (c.fishing_entity_id = home_fishing_entity_id) else false end desc, sum(c.primary_production_fraction) desc) row_num 
              from catch c
             group by c.fishing_entity_id) as t 
     where t.row_num <= coalesce(i_top_count_per_main_areaq, 11)
  ),
  total(year, total, mixed_total) as (
    select c.year, sum(c.primary_production_fraction), sum(case when t.fishing_entity_id is null then c.primary_production_fraction else 0 end)
      from catch c
      left join top t on (t.fishing_entity_id = c.fishing_entity_id)
     group by c.year
  )
  select ud.year::varchar, ud.name, 
         ud.primary_production_fraction,
         ud.total,
         ud.maximum_fraction
    from (select tot.year::varchar as year, fe.name, 
                 c.primary_production_fraction,
                 case when tot.total = 0 then null else tot.total end as total,
                 mf.maximum_fraction,
                 top.catch_rank
            from catch c
            join total tot on (tot.year = c.year)
            join web.v_dim_fishing_entity fe on (fe.fishing_entity_id = c.fishing_entity_id)
            join (select avg(tt2.total) as maximum_fraction from (select tt.total from total tt order by tt.total desc limit 5) as tt2) mf on (true)
            left join top on (top.fishing_entity_id = c.fishing_entity_id)
           where top.catch_rank is not null
          union all
          select tot.year::varchar, 'Others', 
                 tot.mixed_total,
                 case when tot.total = 0 then null else tot.total end,
                 mf.maximum_fraction,
                 coalesce(i_top_count_per_main_areaq, 11) + 1
            from total tot
            join (select avg(tt2.total) as maximum_fraction from (select tt.total from total tt order by tt.total desc limit 5) as tt2) mf on (true)
           ) as ud
   order by ud.year, ud.catch_rank;
end
$body$
language plpgsql;

create or replace function web.f_multinational_footprint_json 
(
  i_entity_id int[],
  i_entity_layer_id int = 1,
  i_sub_area_id int[] default null::int[],
  i_top_count_per_main_areaq int = 11,
  i_other_params json default null
)
returns json as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  home_fishing_entity_id smallint := (select e.is_home_eez_of_fishing_entity_id from web.eez e where e.eez_id = i_entity_id[1] and i_entity_layer_id = 1);
begin
  return (
  with catch(fishing_entity_id, year, primary_production_fraction) as (
    select f.* from web.f_multinational_footprint_query(i_entity_id, i_sub_area_id, i_entity_layer_id, area_bucket_id_layer, i_other_params) f
  ),
  top(fishing_entity_id, catch_rank) as (
    select t.fishing_entity_id, t.row_num 
      from (select c.fishing_entity_id, 
                   row_number() over(order by case when i_entity_layer_id = 1 then (c.fishing_entity_id = home_fishing_entity_id) else false end desc, 
                                              sum(c.primary_production_fraction) desc) row_num 
              from catch c
             group by c.fishing_entity_id) as t 
     where t.row_num <= coalesce(i_top_count_per_main_areaq, 11)
  ),
  topwithyear(fishing_entity_id, year, catch_rank) as (
    select tp.fishing_entity_id, tm.time_business_key, tp.catch_rank
      from top tp, web.time tm
  ),
  total(year, total, mixed_total) as (
    select c.year, sum(c.primary_production_fraction), sum(case when t.fishing_entity_id is null then c.primary_production_fraction else 0 end)
      from catch c
      left join top t on (t.fishing_entity_id = c.fishing_entity_id)
     group by c.year
  )
  select json_build_object(
           'countries',
           (select json_agg(fd.*) 
              from (select ud.name AS key,
                           array_accum(array[array[t.time_business_key::numeric, ud.primary_production_fraction]] order by t.time_business_key) AS values
                      from web.time t
                      left join (select fe.name, 
                                        top.year as year, 
                                        c.primary_production_fraction,
                                        top.catch_rank
                                   from topwithyear top 
                                   join web.v_dim_fishing_entity fe on (fe.fishing_entity_id = top.fishing_entity_id)
                                   left join catch c on (c.fishing_entity_id = top.fishing_entity_id and c.year = top.year)
                                  where top.catch_rank is not null
                                 union all
                                 select 'Others', 
                                        tm.time_business_key, 
                                        tot.mixed_total,
                                        coalesce(i_top_count_per_main_areaq, 11) + 1
                                   from web.time tm
                                   left join total tot on (tot.year = tm.time_business_key)
                                ) as ud
                        on (t.time_business_key = ud.year)
                     group by ud.name, ud.catch_rank
                     order by ud.catch_rank) as fd
           ),
           'maximum_fraction',
           (select avg(tt2.total) as maximum_fraction from (select tt.total from total tt order by tt.total desc limit 5) as tt2)
         )
  );
end
$body$
language plpgsql;

create or replace function web.f_multinational_footprint_csv 
(
  i_entity_id int[],
  i_entity_layer_id int = 1,
  i_sub_area_id int[] default null::int[],
  i_top_count_per_main_areaq int = 11,
  i_other_params json default null
)
returns setof text as
$body$
declare
  area_bucket_id_layer int := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
  home_fishing_entity_id smallint := (select e.is_home_eez_of_fishing_entity_id from web.eez e where e.eez_id = i_entity_id[1] and i_entity_layer_id = 1);
begin
  return query
  with catch(fishing_entity_id, year, primary_production_fraction) as (
    select f.* from web.f_multinational_footprint_query(i_entity_id, i_sub_area_id, i_entity_layer_id, area_bucket_id_layer, i_other_params) f
  ),
  top(fishing_entity_id, catch_rank) as (
    select t.fishing_entity_id, t.row_num 
      from (select c.fishing_entity_id, 
                   row_number() over(order by case when i_entity_layer_id = 1 then (c.fishing_entity_id = home_fishing_entity_id) else false end desc, 
                                              sum(c.primary_production_fraction) desc) row_num 
              from catch c
             group by c.fishing_entity_id) as t 
     where t.row_num <= coalesce(i_top_count_per_main_areaq, 11)
  ),
  topwithyear(fishing_entity_id, year, catch_rank) as (
    select tp.fishing_entity_id, tm.time_business_key, tp.catch_rank
      from top tp, web.time tm
  ),
  total(year, total, mixed_total) as (
    select c.year, sum(c.primary_production_fraction), sum(case when t.fishing_entity_id is null then c.primary_production_fraction else 0 end)
      from catch c      
      left join top t on (t.fishing_entity_id = c.fishing_entity_id)
     group by c.year
  )
  (select array_to_string(array['year'] || array_agg('"' || fe.name || '"' order by t.catch_rank) || array['Others'], ',')
    from top t
    join web.fishing_entity fe using (fishing_entity_id))
  union all
  (select array_to_string(
            tm.time_business_key::text ||
            (select array_agg(coalesce(c.primary_production_fraction::text, '') order by ty.catch_rank)
               from topwithyear ty
               left join catch c using(year, fishing_entity_id)
              where ty.year = tm.time_business_key) ||
            (select coalesce(tot.mixed_total::text, '')
               from total tot
              where tot.year = tm.time_business_key),
          ',')
     from web.time as tm);
end
$body$
language plpgsql;
