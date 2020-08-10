CREATE TABLE cmsy.assessment_summary (
	eez_id int4 NULL,
	eez varchar(50) NULL,
	nei_count int8 NULL,
	nei_catch numeric NULL,
	family_order_class_count int8 NULL,
	family_order_class_catch numeric NULL,
	genera_count int8 NULL,
	genera_catch numeric NULL,
	species_total_count int8 NULL,
	species_total_catch numeric NULL,
	top_90_species_count int8 NULL,
	top_90_species_catch numeric NULL,
	excluded_discard_species_count int8 NULL,
	straddling_stocks_count int8 NULL,
	straddling_stocks_catch numeric NULL,
	local_stocks_count int8 NULL,
	local_stocks_catch numeric NULL,
	total_assessed_count int8 NULL,
	total_assessed_catch numeric NULL,
	b_prime_unweighted_3yr float8 NULL,
	b_prime_unweighted_1yr float8 NULL,
	b_prime_weighted_3yr float8 NULL,
	b_prime_weighted_1yr float8 NULL
);

CREATE TABLE cmsy.oceana_stocks (
	oceana_countries varchar NULL,
	eez_id int2 NULL,
	eez_name varchar NULL,
	meow_id int2 NULL,
	meow_name varchar NULL,
	stock_name varchar NULL,
	scientific_name varchar NULL,
	common_name varchar NULL
);

CREATE TABLE cmsy.raw_biomass_window (
	stock_description varchar(32767) NULL,
	"year" int4 NULL,
	biomass_window float8 NULL
);

CREATE TABLE cmsy.raw_catch_id (
	ref_id varchar(32767) NULL,
	stock_name varchar(32767) NULL,
	"year" int4 NULL,
	catch varchar(32767) NULL,
	biomass varchar(32767) NULL,
	date_ref date NULL
);

CREATE TABLE cmsy.raw_outputfile (
	"Group" varchar(32767) NULL,
	region varchar(32767) NULL,
	subregion varchar(32767) NULL,
	"Name" varchar(32767) NULL,
	sciname varchar(32767) NULL,
	stock varchar(32767) NULL,
	"start.yr" varchar(32767) NULL,
	"end.yr" varchar(32767) NULL,
	btype varchar(32767) NULL,
	maxcatch varchar(32767) NULL,
	lastcatch varchar(32767) NULL,
	msy_bsm varchar(32767) NULL,
	msy_bsm_lcl varchar(32767) NULL,
	msy_bsm_ucl varchar(32767) NULL,
	r_bsm varchar(32767) NULL,
	r_bsm_lcl varchar(32767) NULL,
	r_bsm_ucl varchar(32767) NULL,
	k_bsm varchar(32767) NULL,
	k_bsm_lcl varchar(32767) NULL,
	k_bsm_ucl varchar(32767) NULL,
	q_bsm varchar(32767) NULL,
	q_bsm_lcl varchar(32767) NULL,
	q_bsm_ucl varchar(32767) NULL,
	rel_b_bsm varchar(32767) NULL,
	rel_b_bsm_lcl varchar(32767) NULL,
	rel_b_bsm_ucl varchar(32767) NULL,
	rel_f_bsm varchar(32767) NULL,
	r_cmsy varchar(32767) NULL,
	r_cmsy_lcl varchar(32767) NULL,
	r_cmsy_ucl varchar(32767) NULL,
	k_cmsy varchar(32767) NULL,
	k_cmsy_lcl varchar(32767) NULL,
	k_cmsy_ucl varchar(32767) NULL,
	msy_cmsy varchar(32767) NULL,
	msy_cmsy_lcl varchar(32767) NULL,
	msy_cmsy_ucl varchar(32767) NULL,
	rel_b_cmsy varchar(32767) NULL,
	"2.5th" varchar(32767) NULL,
	"97.5th" varchar(32767) NULL,
	rel_f_cmsy varchar(32767) NULL,
	f_msy varchar(32767) NULL,
	f_msy_lcl varchar(32767) NULL,
	f_msy_ucl varchar(32767) NULL,
	curf_msy varchar(32767) NULL,
	curf_msy_lcl varchar(32767) NULL,
	curf_msy_ucl varchar(32767) NULL,
	msy varchar(32767) NULL,
	msy_lcl varchar(32767) NULL,
	msy_ucl varchar(32767) NULL,
	bmsy float8 NULL,
	bmsy_lcl varchar(32767) NULL,
	bmsy_ucl varchar(32767) NULL,
	b varchar(32767) NULL,
	b_lcl varchar(32767) NULL,
	b_ucl varchar(32767) NULL,
	b_bmsy varchar(32767) NULL,
	b_bmsy_lcl varchar(32767) NULL,
	b_bmsy_ucl varchar(32767) NULL,
	f varchar(32767) NULL,
	f_lcl varchar(32767) NULL,
	f_ucl varchar(32767) NULL,
	f_fmsy varchar(32767) NULL,
	f_fmsy_lcl varchar(32767) NULL,
	f_fmsy_ucl varchar(32767) NULL,
	sel_b varchar(32767) NULL,
	sel_b_bmsy varchar(32767) NULL,
	sel_f varchar(32767) NULL,
	sel_f_fmsy varchar(32767) NULL,
	"year" int4 NULL,
	catch varchar(32767) NULL,
	biomass_management float8 NULL,
	bm_lcl float8 NULL,
	bm_ucl float8 NULL,
	biomass_analysis float8 NULL,
	ba_lcl float8 NULL,
	ba_ucl float8 NULL,
	cpue_biomass float8 NULL,
	cpue_lcl float8 NULL,
	cpue_ucl float8 NULL,
	cpue_creep float8 NULL,
	f_fmsy_management float8 NULL,
	f_fm_lcl float8 NULL,
	f_fm_ucl float8 NULL,
	cpue_fmsy float8 NULL
);

CREATE TABLE cmsy.raw_stock_id (
	region varchar(32767) NULL,
	subregion varchar(32767) NULL,
	stock_name varchar(32767) NULL,
	"group" varchar(32767) NULL,
	stock_description varchar(32767) NULL,
	englishname varchar(32767) NULL,
	scientific_name varchar(32767) NULL,
	resilience_source varchar(32767) NULL,
	r_source varchar(32767) NULL,
	cpue_source varchar(32767) NULL,
	biomass_window_source varchar(32767) NULL,
	stock_resource varchar(32767) NULL,
	minofyear varchar(32767) NULL,
	maxofyear varchar(32767) NULL,
	startyear varchar(32767) NULL,
	endyear varchar(32767) NULL,
	resilience varchar(32767) NULL,
	r_low varchar(32767) NULL,
	r_hi varchar(32767) NULL,
	stb_low varchar(32767) NULL,
	stb_hi varchar(32767) NULL,
	int_yr varchar(32767) NULL,
	intb_low varchar(32767) NULL,
	intb_hi varchar(32767) NULL,
	endb_low varchar(32767) NULL,
	endb_hi varchar(32767) NULL,
	q_start varchar(32767) NULL,
	q_end varchar(32767) NULL,
	btype varchar(32767) NULL,
	e_creep varchar(32767) NULL,
	force_cmsy varchar(32767) NULL,
	"comment" varchar(32767) NULL,
	notes varchar(32767) NULL,
	date_ref date NULL
);

CREATE TABLE cmsy.ref_content (
	ref_content_id serial NOT NULL,
	ref_id int4 NULL,
	stock_id varchar NULL,
	page varchar NULL,
	sci_name varchar NULL,
	info_format varchar NULL,
	info_drawn varchar NULL
);

CREATE TABLE cmsy.reference (
	ref_id int4 NOT NULL,
	author varchar NULL,
	"year" int4 NULL,
	title text NULL,
	"source" varchar NULL,
	short_citation varchar NULL,
	journal int4 NULL,
	"language" varchar NULL,
	ref_type varchar NULL,
	author_address text NULL,
	pdf_file varchar NULL,
	pdf_url text NULL
);

CREATE TABLE cmsy.rel_biom (
	rel_biom_id serial NOT NULL,
	rel_biom_meta_id int4 NULL,
	stock_id varchar NULL,
	"year" int4 NULL,
	value float8 NULL,
	midlength float8 NULL
);

CREATE TABLE cmsy.rel_biom_meta (
	rel_biom_meta_id serial NOT NULL,
	stock_id varchar NULL,
	data_type varchar NULL,
	units varchar NULL,
	year_start int4 NULL,
	year_end int4 NULL,
	years_missing varchar NULL,
	region_description varchar NULL,
	gear_type_id int4 NULL,
	gear_type varchar NULL,
	ref_id int4 NULL,
	"comments" text NULL
);

CREATE TABLE cmsy.stock (
	stock_id varchar NOT NULL,
	stock_name varchar NOT NULL,
	stock_description varchar NULL,
	stock_num int4 NULL,
	taxon_key int4 NULL,
	is_stradling bool NULL,
	is_active bool NULL,
	date_modified timestamptz NULL DEFAULT now()
);

CREATE TABLE cmsy.stock_marine_area (
	stock_id varchar NULL,
	stock_name varchar NULL,
	marine_layer_id int4 NULL,
	main_area_id int4 NULL,
	meow_id int2 NULL
);

CREATE TABLE cmsy.stock_meow_reference (
	stock_id varchar(300) NULL,
	stock_name varchar NULL,
	cmsy_graph_id text NULL,
	region varchar(300) NULL,
	subregion varchar(500) NULL,
	group_type varchar NULL,
	marine_layer_id int4 NULL,
	meow_id int4 NULL,
	pdf_url varchar(500) NULL,
	graph_url varchar(500) NULL
);