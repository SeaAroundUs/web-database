update web.fao_area f
   set area_key = 
       array(select a.area_key from web.area a where a.marine_layer_id = 2 and a.main_area_id = f.fao_area_id
             union all
             select a.area_key from web.area a where a.marine_layer_id = 1 and a.sub_area_id = f.fao_area_id);

