------
------ Foreign Keys
------
--ALTER TABLE allocation.search_result ADD CONSTRAINT query_id_fk
--FOREIGN KEY (query_id) REFERENCES allocation.query(id) ON DELETE CASCADE;
-----
ALTER TABLE allocation.allocation_data ADD CONSTRAINT catch_type_id_fk
FOREIGN KEY (catch_type_id) REFERENCES web.catch_type(catch_type_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_data ADD CONSTRAINT reporting_status_id_fk
FOREIGN KEY (reporting_status_id) REFERENCES web.reporting_status(reporting_status_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_data ADD CONSTRAINT sector_type_id_fk
FOREIGN KEY (sector_type_id) REFERENCES web.sector_type(sector_type_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_data ADD CONSTRAINT allocation_area_type_id_fk
FOREIGN KEY (allocation_area_type_id) REFERENCES allocation.allocation_area_type(allocation_area_type_id) ON DELETE CASCADE;
-----
ALTER TABLE allocation.allocation_result ADD CONSTRAINT universal_data_id_fk
FOREIGN KEY (universal_data_id) REFERENCES allocation.allocation_data(universal_data_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_result ADD CONSTRAINT cell_id_fk
FOREIGN KEY (cell_id) REFERENCES allocation.cell(cell_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_result ADD CONSTRAINT allocation_simple_area_id_fk
FOREIGN KEY (allocation_simple_area_id) REFERENCES allocation.allocation_simple_area(allocation_simple_area_id) ON DELETE CASCADE;
-----
ALTER TABLE allocation.allocation_simple_area ADD CONSTRAINT inherited_att_belongs_to_reconstruction_eez_id_fk
FOREIGN KEY (inherited_att_belongs_to_reconstruction_eez_id) REFERENCES web.eez(eez_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_simple_area ADD CONSTRAINT allocation_simple_area_fao_area_id_fk
FOREIGN KEY (fao_area_id) REFERENCES web.fao_area(fao_area_id) ON DELETE CASCADE;

ALTER TABLE allocation.allocation_simple_area ADD CONSTRAINT allocation_simple_area_marine_layer_id_fk
FOREIGN KEY (marine_layer_id) REFERENCES web.marine_layer(marine_layer_id) ON DELETE CASCADE;
-----
ALTER TABLE allocation.simple_area_cell_assignment_raw ADD CONSTRAINT simple_area_cell_assignment_raw_cell_id_fk
FOREIGN KEY (cell_id) REFERENCES allocation.cell(cell_id) ON DELETE CASCADE;

ALTER TABLE allocation.simple_area_cell_assignment_raw ADD CONSTRAINT simple_area_cell_assignment_raw_fao_area_id_fk
FOREIGN KEY (fao_area_id) REFERENCES web.fao_area(fao_area_id) ON DELETE CASCADE;

ALTER TABLE allocation.simple_area_cell_assignment_raw ADD CONSTRAINT simple_area_cell_assignment_raw_marine_layer_id_fk
FOREIGN KEY (marine_layer_id) REFERENCES web.marine_layer(marine_layer_id) ON DELETE CASCADE;
