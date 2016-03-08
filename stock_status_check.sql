create or replace function web.f_stock_status_temp(
  i_entity_id int[],
  i_entity_layer_id int default 1,
  i_sub_area_id int[] default null::int[],
  i_other_params json default null
)
returns table(taxa_count int, should_be_displayed BOOLEAN)
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
  )
    select taxa_count,
           case when i_entity_layer_id = 1 then case when t.cellCount > 30 and t.taxa_count > 10 then true else false end else true end
      from (select (select count(distinct taxon)::int from categorized) as taxa_count,
                   (select sum(a.number_of_cells) from web.area a where a.main_area_id = any(i_entity_id) and a.marine_layer_id = i_entity_layer_id and coalesce(a.sub_area_id = any(i_sub_area_id), true)) as cellCount) as t)
    ;

end
$body$
language plpgsql;