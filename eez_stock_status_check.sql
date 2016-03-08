update admin.eez_stock_status s 
   set cell_count = (select sum(a.number_of_cells) 
  from web.area a 
 where a.marine_layer_id=1 and a.main_area_id = s.eez_id);

with dat(eez_id, taxon_count, catch_sum) as (
  select s.eez_id, count(distinct f.taxon_key), sum(f.catch_sum)
    from web.v_fact_data f
    join admin.eez_stock_status s on (s.eez_id = f.main_area_id)
   where f.marine_layer_id=1
     and f.taxon_key != all(array[100000, 100011, 100025, 100039, 100047, 100058, 100077, 100139, 100239, 100339])
   group by s.eez_id 
)
update admin.eez_stock_status s 
   set taxon_count = d.taxon_count,
       total_catch_sum = d.catch_sum
  from dat d
 where s.eez_id = d.eez_id;
