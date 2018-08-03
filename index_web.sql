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
CREATE INDEX v_rfmo_catch_idx ON web.v_rfmo_catch(id);