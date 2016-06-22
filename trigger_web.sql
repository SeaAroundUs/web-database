---
--- Triggers
---

CREATE OR REPLACE FUNCTION web.fao_area_insert_update_trigger_handler() RETURNS TRIGGER AS
$body$
BEGIN
     NEW.area_key := 
       array(select a.area_key from web.area a where a.marine_layer_id = 2 and a.main_area_id = NEW.fao_area_id
             union all
             select a.area_key from web.area a where a.marine_layer_id = 1 and a.sub_area_id = NEW.fao_area_id);

  RETURN NEW;
END;
$body$
LANGUAGE plpgsql;

CREATE TRIGGER fao_area_before_insert_update_trigger BEFORE UPDATE OR INSERT
            ON web.fao_area
  FOR EACH ROW EXECUTE PROCEDURE web.fao_area_insert_update_trigger_handler();

