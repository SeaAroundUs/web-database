vacuum analyze; 
select update_all_sequence('sau'::text); 
select * from web_partition.maintain_cell_catch_partition(); 
/* Table indexes */
CREATE UNIQUE INDEX area_ak_cl ON web.area
(
	marine_layer_id ASC,
	main_area_id ASC,
	sub_area_id ASC
);

CREATE UNIQUE INDEX time_ak_cl ON web.Time(time_business_key ASC);

CREATE INDEX cell_fao_area_id_idx ON web.cell(fao_area_id);
CREATE INDEX cell_lme_id_idx ON web.cell(lme_id);
CREATE INDEX cell_meow_id_idx ON web.cell(meow_id);

CREATE UNIQUE INDEX nc_unique ON web.geo_entity_mariculture_entity_mapping
(
	geo_entity_id ASC,
	mariculture_entity_id ASC,
	mariculture_sub_entity_id ASC
);

CREATE INDEX c_number_idx ON web.estuary(c_number);

CREATE INDEX country_count_code_idx ON web.country(count_code);

CREATE INDEX country_ngo_count_code_idx ON web.country_ngo(count_code);

CREATE INDEX country_fishery_profile_count_code_idx ON web.country_fishery_profile(count_code);

CREATE INDEX mariculture_data_mariculture_sub_entity_id_idx ON web.mariculture_data(mariculture_sub_entity_id);
CREATE INDEX mariculture_entity_legacy_c_number_idx ON web.mariculture_entity(legacy_c_number);
CREATE INDEX mariculture_sub_entity_mariculture_entity_id_idx ON web.mariculture_sub_entity(mariculture_entity_id);
CREATE INDEX lme_fishbase_link_lme_id_idx ON web.lme_fishbase_link(lme_id);

CREATE INDEX v_fact_data_taxon_key_idx ON web.v_fact_data(taxon_key);
CREATE INDEX v_fact_data_area_key_idx ON web.v_fact_data(area_key);
CREATE INDEX v_fact_data_time_key_idx ON web.v_fact_data(time_key);
CREATE INDEX v_fact_data_catch_type_id_idx ON web.v_fact_data(catch_type_id);
CREATE INDEX v_fact_data_reporting_status_id_idx ON web.v_fact_data(reporting_status_id);
CREATE INDEX v_fact_data_sector_type_id_idx ON web.v_fact_data(sector_type_id);
CREATE INDEX v_fact_data_main_area_id_marine_layer_id_idx ON web.v_fact_data(main_area_id, marine_layer_id);
CREATE INDEX v_fact_data_fishing_entity_id_idx ON web.v_fact_data(fishing_entity_id);
CREATE INDEX v_fact_data_marine_layer_id_idx ON web.v_fact_data(marine_layer_id);
CREATE INDEX v_fact_data_taxon_key_marine_layer_id_idx ON web.v_fact_data(taxon_key, marine_layer_id);

/* Materialized view indexes */

CREATE UNIQUE INDEX v_web_taxon_taxon_key_uk ON web.v_web_taxon(taxon_key);
CREATE INDEX v_web_taxon_commercial_group_id_idx ON web.v_web_taxon(commercial_group_id);
CREATE INDEX v_web_taxon_functional_group_id_idx ON web.v_web_taxon(functional_group_id);

CREATE UNIQUE INDEX v_dim_area_area_key_uk ON web.v_dim_area(area_key);

CREATE UNIQUE INDEX dictionary_word_idx ON web.dictionary(word);
CREATE UNIQUE INDEX dictionary_word_ops_idx ON web.dictionary(word varchar_pattern_ops);

CREATE INDEX v_eez_catch_idx ON web.v_eez_catch(id);
CREATE INDEX v_meow_catch_idx ON web.v_meow_catch(id);
CREATE INDEX v_lme_catch_idx ON web.v_lme_catch(id);
CREATE INDEX v_rfmo_catch_idx ON web.v_rfmo_catch(id);------
------ Foreign Keys
------

--ALTER TABLE  ADD CONSTRAINT _fk
--FOREIGN KEY () REFERENCES () ON DELETE CASCADE;

-- web.cube_dim_taxon
ALTER TABLE web.cube_dim_taxon ADD CONSTRAINT commercial_group_id_fk
FOREIGN KEY (commercial_group_id) REFERENCES web.commercial_groups(commercial_group_id) ON DELETE CASCADE;

ALTER TABLE web.cube_dim_taxon ADD CONSTRAINT functional_group_id_fk
FOREIGN KEY (functional_group_id) REFERENCES web.functional_groups(functional_group_id) ON DELETE CASCADE;

ALTER TABLE web.cube_dim_taxon ADD CONSTRAINT taxon_group_id_fk
FOREIGN KEY (taxon_group_id) REFERENCES web.taxon_group(taxon_group_id) ON DELETE CASCADE;

ALTER TABLE web.cube_dim_taxon ADD CONSTRAINT taxon_level_id_fk
FOREIGN KEY (taxon_level_id) REFERENCES web.taxon_level(taxon_level_id) ON DELETE CASCADE;

-- web.geo_entity
ALTER TABLE web.geo_entity ADD CONSTRAINT jurisdiction_id_fk
FOREIGN KEY (jurisdiction_id) REFERENCES web.jurisdiction(jurisdiction_id) ON DELETE CASCADE;

ALTER TABLE web.geo_entity ADD CONSTRAINT admin_geo_entity_id_fk
FOREIGN KEY (admin_geo_entity_id) REFERENCES web.geo_entity(geo_entity_id) ON DELETE CASCADE;

-- web.sub_geo_entity 
ALTER TABLE web.sub_geo_entity ADD CONSTRAINT geo_entity_id_fk
FOREIGN KEY (geo_entity_id) REFERENCES web.geo_entity(geo_entity_id) ON DELETE CASCADE;

-- web.mariculture_data
ALTER TABLE web.mariculture_data ADD CONSTRAINT mariculture_sub_entity_id_fk
FOREIGN KEY (mariculture_sub_entity_id) REFERENCES web.mariculture_sub_entity(mariculture_sub_entity_id) ON DELETE CASCADE;

--Temporary only due to taxon is_retired issues
--ALTER TABLE web.mariculture_data ADD CONSTRAINT taxon_key_fk
--FOREIGN KEY (taxon_key) REFERENCES web.cube_dim_taxon(taxon_key) ON DELETE CASCADE;

-- web.mariculture_entity
ALTER TABLE web.mariculture_entity ADD CONSTRAINT legacy_c_number_fk
FOREIGN KEY (legacy_c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

-- web.mariculture_sub_entity
ALTER TABLE web.mariculture_sub_entity ADD CONSTRAINT mariculture_entity_id_fk
FOREIGN KEY (mariculture_entity_id) REFERENCES web.mariculture_entity(mariculture_entity_id) ON DELETE CASCADE;

-- web.area
ALTER TABLE web.area ADD CONSTRAINT marine_layer_id_fk
FOREIGN KEY (marine_layer_id) REFERENCES web.marine_layer(marine_layer_id) ON DELETE CASCADE;

-- web.area_invisible
ALTER TABLE web.area_invisible ADD CONSTRAINT marine_layer_id_fk
FOREIGN KEY (marine_layer_id) REFERENCES web.marine_layer(marine_layer_id) ON DELETE CASCADE;

-- web.eez 
ALTER TABLE web.eez ADD CONSTRAINT geo_entity_id_fk
FOREIGN KEY (geo_entity_id) REFERENCES web.geo_entity(geo_entity_id) ON DELETE CASCADE;

ALTER TABLE web.eez ADD CONSTRAINT legacy_c_number_fk
FOREIGN KEY (legacy_c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

-- web.fishing_entity 
ALTER TABLE web.fishing_entity ADD CONSTRAINT geo_entity_id_fk
FOREIGN KEY (geo_entity_id) REFERENCES web.geo_entity(geo_entity_id) ON DELETE CASCADE;

ALTER TABLE web.fishing_entity ADD CONSTRAINT legacy_c_number_fk
FOREIGN KEY (legacy_c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

-- web.geo_entity_mariculture_entity_mapping 
ALTER TABLE web.geo_entity_mariculture_entity_mapping ADD CONSTRAINT geo_entity_id_fk
FOREIGN KEY (geo_entity_id) REFERENCES web.geo_entity(geo_entity_id) ON DELETE CASCADE;

-- web.country
ALTER TABLE web.country ADD CONSTRAINT admin_c_number_fk
FOREIGN KEY (admin_c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

-- web.estuary
ALTER TABLE web.estuary ADD CONSTRAINT c_number_fk
FOREIGN KEY (c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

-- web.area_bucket_type
ALTER TABLE web.area_bucket_type ADD CONSTRAINT marine_layer_id_fk
FOREIGN KEY (marine_layer_id) REFERENCES web.marine_layer(marine_layer_id) ON DELETE CASCADE;

-- web.area_bucket
ALTER TABLE web.area_bucket ADD CONSTRAINT area_bucket_type_id_fk
FOREIGN KEY (area_bucket_type_id) REFERENCES web.area_bucket_type(area_bucket_type_id) ON DELETE CASCADE;

-- web.v_fact_data
ALTER TABLE web.v_fact_data ADD CONSTRAINT taxon_key_fk
FOREIGN KEY (taxon_key) REFERENCES web.cube_dim_taxon(taxon_key) ON DELETE CASCADE;

-- Defer this foreign key due to the issue with fishing_entity 223. This particular fe is converted to 213 
-- after records have already been inserted into v_fact_data during aggregation. 
-- So, can't have foreign as that would break aggregation.
--
--ALTER TABLE web.v_fact_data ADD CONSTRAINT fishing_entity_id_fk
--FOREIGN KEY (fishing_entity_id) REFERENCES web.fishing_entity(fishing_entity_id) ON DELETE CASCADE;

--ALTER TABLE web.v_fact_data ADD CONSTRAINT gear_id_fk
--FOREIGN KEY (gear_id) REFERENCES web.gear(gear_id) ON DELETE CASCADE;

ALTER TABLE web.v_fact_data ADD CONSTRAINT time_key_fk
FOREIGN KEY (time_key) REFERENCES web.time(time_key) ON DELETE CASCADE;

ALTER TABLE web.v_fact_data ADD CONSTRAINT area_key_fk
FOREIGN KEY (area_key) REFERENCES web.area(area_key) ON DELETE CASCADE;

ALTER TABLE web.v_fact_data ADD CONSTRAINT marine_layer_id_fk
FOREIGN KEY (marine_layer_id) REFERENCES web.marine_layer(marine_layer_id) ON DELETE CASCADE;

ALTER TABLE web.v_fact_data ADD CONSTRAINT catch_type_id_fk
FOREIGN KEY (catch_type_id) REFERENCES web.catch_type(catch_type_id) ON DELETE CASCADE;

ALTER TABLE web.v_fact_data ADD CONSTRAINT reporting_status_id_fk
FOREIGN KEY (reporting_status_id) REFERENCES web.reporting_status(reporting_status_id) ON DELETE CASCADE;

ALTER TABLE web.v_fact_data ADD CONSTRAINT sector_type_id_fk
FOREIGN KEY (sector_type_id) REFERENCES web.sector_type(sector_type_id) ON DELETE CASCADE;

-- web.access_agreement
ALTER TABLE web.access_agreement ADD CONSTRAINT access_type_id_fk
FOREIGN KEY (access_type_id) REFERENCES web.access_type(id) ON DELETE CASCADE;

ALTER TABLE web.access_agreement ADD CONSTRAINT agreement_type_id_fk
FOREIGN KEY (agreement_type_id) REFERENCES web.agreement_type(id) ON DELETE CASCADE;

-- web.uncertainty_eez
ALTER TABLE web.uncertainty_eez ADD CONSTRAINT uncertainty_eez_eez_id_fk
FOREIGN KEY (eez_id) REFERENCES web.eez(eez_id) ON DELETE CASCADE;

ALTER TABLE web.uncertainty_eez ADD CONSTRAINT uncertainty_eez_sector_type_id_fk
FOREIGN KEY (sector_type_id) REFERENCES web.sector_type(sector_type_id) ON DELETE CASCADE;

ALTER TABLE web.uncertainty_eez ADD CONSTRAINT uncertainty_eez_period_id_fk
FOREIGN KEY (period_id) REFERENCES web.uncertainty_time_period(period_id) ON DELETE CASCADE;

ALTER TABLE web.uncertainty_eez ADD CONSTRAINT uncertainty_eez_score_fk
FOREIGN KEY (score) REFERENCES web.uncertainty_score(score) ON DELETE CASCADE;
CREATE INDEX eez_wkb_geometry_geom_idx ON geo.eez USING gist(wkb_geometry);
CREATE INDEX eez_eez_id_idx ON geo.eez(eez_id);
CREATE UNIQUE INDEX v_eez_id_idx ON geo.v_eez(id);
CREATE INDEX v_eez_fishbase_id_idx ON geo.v_eez(fishbase_id);

CREATE UNIQUE INDEX rfmo_rfmo_id_idx ON geo.rfmo(rfmo_id);
CREATE INDEX rfmo_geom_idx ON geo.rfmo USING gist(geom);
CREATE UNIQUE INDEX v_rfmo_id_idx ON geo.v_rfmo(id);

CREATE INDEX ifa_eez_id_idx ON geo.ifa(eez_id);
CREATE INDEX ifa_geom_idx ON geo.ifa USING gist(geom);
CREATE INDEX v_ifa_eez_id_idx ON geo.v_ifa(eez_id);

CREATE INDEX fao_geom_geom_idx ON geo.fao USING gist(geom);
CREATE INDEX fao_fao_area_id_idx ON geo.fao(fao_area_id);
CREATE UNIQUE INDEX v_fao_fao_area_id_idx ON geo.v_fao(fao_area_id);

CREATE INDEX high_seas_geom_geom_idx ON geo.high_seas USING gist(geom);
CREATE INDEX high_seas_fao_area_id_idx ON geo.high_seas(fao_area_id);
CREATE UNIQUE INDEX v_high_seas_id_idx ON geo.v_high_seas(id);

CREATE INDEX mariculture_entity_eez_id_idx ON geo.mariculture_entity(eez_id);
CREATE INDEX v_mariculture_entity_c_number_idx ON geo.v_mariculture_entity(c_number);
CREATE INDEX v_mariculture_entity_c_iso_code_idx ON geo.v_mariculture_entity(c_iso_code);

CREATE INDEX mariculture_c_number_idx ON geo.mariculture(c_number);
CREATE INDEX mariculture_taxon_key_idx ON geo.mariculture(taxon_key);
CREATE INDEX mariculture_geom_idx ON geo.mariculture USING gist(geom);

CREATE INDEX mariculture_points_c_number_idx on geo.mariculture_points(c_number);
CREATE INDEX mariculture_points_entity_id_idx on geo.mariculture_points(entity_id);
CREATE INDEX mariculture_points_sub_entity_id_idx on geo.mariculture_points(sub_entity_id);

CREATE UNIQUE INDEX area_area_key_idx ON geo.area(area_key);
CREATE UNIQUE INDEX v_area_id_idx ON geo.v_area(id);
CREATE INDEX v_area_marine_layer_id_main_area_id_idx ON geo.v_area(marine_layer_id, main_area_id);

CREATE INDEX cell_grid_geom_idx ON geo.cell_grid USING gist(geom);
------
------ Foreign Keys
------
--ALTER TABLE geo. ADD CONSTRAINT _fk
--FOREIGN KEY () REFERENCES web.() ON DELETE CASCADE;
ALTER TABLE geo.rfmo ADD CONSTRAINT rfmo_rfmo_id_fk
FOREIGN KEY (rfmo_id) REFERENCES web.rfmo(rfmo_id) ON DELETE CASCADE;

ALTER TABLE geo.ifa ADD CONSTRAINT ifa_eez_id_fk
FOREIGN KEY (eez_id) REFERENCES web.eez(eez_id) ON DELETE CASCADE;

ALTER TABLE geo.ne_country ADD CONSTRAINT ne_country_c_number_fk
FOREIGN KEY (c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

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
CREATE INDEX allocation_result_meow_meow_id_idx ON allocation.allocation_result_meow(meow_id);------
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

--ALTER TABLE allocation.allocation_data ADD CONSTRAINT allocation_area_type_id_fk
--FOREIGN KEY (allocation_area_type_id) REFERENCES allocation.allocation_area_type(allocation_area_type_id) ON DELETE CASCADE;
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
CREATE INDEX subsidy_c_number_idx ON feru.subsidy(c_number);

CREATE INDEX indx_expedition_key ON expedition.abundance_by_station(expedition_key);

CREATE INDEX ix_country ON expedition.country(count_code, c_number);

CREATE INDEX ix_vessels_1 ON expedition.vessels(expedition_key, vessel_name);

CREATE INDEX django_session_expire_date_idx ON admin.django_session(expire_date);

CREATE INDEX django_session_session_key_idx ON admin.django_session(session_key varchar_pattern_ops);

CREATE INDEX remora_sauuser_email_idx ON admin.remora_sauuser(email varchar_pattern_ops);
update web.fao_area f
   set area_key = 
       array(select a.area_key from web.area a where a.marine_layer_id = 2 and a.main_area_id = f.fao_area_id
             union all
             select a.area_key from web.area a where a.marine_layer_id = 1 and a.sub_area_id = f.fao_area_id);
 refresh materialized view web.v_all_taxon;
 refresh materialized view web.v_dim_area;
 refresh materialized view web.v_dim_fishing_entity;
 refresh materialized view web.v_dim_gear;
 refresh materialized view web.v_dim_taxon;
 refresh materialized view web.v_dim_time;
 refresh materialized view web.v_functional_group;
 refresh materialized view web.v_rfmo_catch;
 refresh materialized view web.v_saup_jurisdiction;
 refresh materialized view web.v_web_taxon;
 refresh materialized view geo.v_area;
 refresh materialized view geo.v_country;
 refresh materialized view geo.v_eez;
 refresh materialized view geo.v_fao;
 refresh materialized view geo.v_high_seas;
 refresh materialized view geo.v_ifa;
 refresh materialized view geo.v_lme;
 refresh materialized view geo.v_mariculture_entity;
 refresh materialized view geo.v_meow;
 refresh materialized view geo.v_rfmo;
 refresh materialized view geo.v_sub_mariculture_entity;

