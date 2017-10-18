---
--- Indexes
---
--CREATE INDEX _idx ON allocation.();

--CREATE INDEX cell_lme_id_idx ON allocation.cell(lme_id);

CREATE INDEX allocation_result_allocation_simple_area_id_idx ON allocation.allocation_result(allocation_simple_area_id);
CREATE INDEX allocation_result_cell_id_idx ON allocation.allocation_result(cell_id);
CREATE INDEX allocation_result_universal_data_id_idx ON allocation.allocation_result(universal_data_id);

CREATE INDEX simple_area_cell_assignment_raw_marine_layer_id_area_id_idx ON allocation.simple_area_cell_assignment_raw(marine_layer_id, area_id);
CREATE INDEX simple_area_cell_assignment_raw_cell_id_idx ON allocation.simple_area_cell_assignment_raw(cell_id);

CREATE INDEX allocation_data_taxon_key_idx ON allocation.allocation_data(taxon_key);
CREATE INDEX allocation_data_fishing_entity_id_year_idx ON allocation.allocation_data(fishing_entity_id, year);

CREATE INDEX asa_inherited_att_belongs_to_reconstruction_eez_id_idx ON allocation.allocation_simple_area(inherited_att_belongs_to_reconstruction_eez_id);

CREATE INDEX allocation_result_eez_universal_data_id_idx ON allocation.allocation_result_eez(universal_data_id);
CREATE INDEX allocation_result_eez_eez_id_fao_area_id_idx ON allocation.allocation_result_eez(eez_id, fao_area_id);

CREATE INDEX allocation_result_global_universal_data_id_idx ON allocation.allocation_result_global(universal_data_id);
CREATE INDEX allocation_result_gloal_area_id_idx ON allocation.allocation_result_global(area_id);

CREATE INDEX allocation_result_lme_universal_data_id_idx ON allocation.allocation_result_lme(universal_data_id);
CREATE INDEX allocation_result_lme_lme_id_idx ON allocation.allocation_result_lme(lme_id);

CREATE INDEX allocation_result_rfmo_universal_data_id_idx ON allocation.allocation_result_rfmo(universal_data_id);
CREATE INDEX allocation_result_rfmo_rfmo_id_idx ON allocation.allocation_result_rfmo(rfmo_id);

CREATE INDEX allocation_result_meow_universal_data_id_idx ON allocation.allocation_result_meow(universal_data_id);
CREATE INDEX allocation_result_meow_meow_id_idx ON allocation.allocation_result_meow(meow_id);