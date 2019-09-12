-- raw id input file
CREATE TABLE cmsy.raw_id_input (
	region varchar not null,
	subregion varchar null,
	stock_name varchar not null,
	stock_id varchar null,
	stock_desc varchar not null,
	functional_group varchar not null,
	common_name varchar not null,
	scientific_name varchar not null,
	stock_source varchar null,
	min_of_year int4 not null,
	max_of_year int4 not null,
	start_year int4 not null,
	end_year int4 not null,
	flim float8 NULL,
	fpa float8 NULL,
	blim float8 NULL,
	bpa float8 NULL,
	fmsy float8 NULL,
	msy_btrigger float8 NULL,
	b40 float8 NULL,
	m float8 NULL,
	fofl float8 NULL,
	last_f float8 NULL,
	resilience varchar NULL,
	resilience_expert varchar NULL,
	r_low float8 NULL,
	r_hi float8 NULL,
	r_low_source varchar NULL,
	r_high_source varchar null,
	stb_low float8 NULL,
	stb_hi float8 NULL,
	stb_low_source varchar NULL,
	stb_hi_source varchar NULL,
	int_year int4 NULL,
	intb_low float8 NULL,
	intb_hi float8 NULL,
	int_low_source varchar NULL,
	int_high_source varchar NULL,
	endb_low float8 NULL,
	endb_hi float8 NULL,
	endb_low_source varchar NULL,
	endb_hi_source varchar NULL,
	q_start int4 NULL,
	q_end int4 NULL,
	q_start_source varchar NULL,
	q_end_source varchar NULL,
	e_creep int4 NULL,
	e_creep_source varchar null,
	btype varchar NULL,
	force_fmsy varchar NULL,
	comments varchar null,
	notes varchar null,
	unreliable_trend bool null,
	carry_forward_questionable bool null,
	cpue_required bool null,
	low_catches bool null,
	flagged_for_verification bool null
	)

--stock_id table
CREATE TABLE cmsy.stock_id (
	stock_id_area varchar primary key,
	stock_id varchar,
	stock_num int4,
	taxon_key int4,
	scientific_name varchar,
	common_name varchar,
	functional_group varchar,
	marine_layer_id int4,
	marine_layer varchar,
	stradling_or_not bool,
	area_id int4,
	area varchar,
	stock_status varchar,
	date_modified int4,
	ref_id int4,
	date_entered int4,
	"comments" text
);


--stock_id_strad table
create table cmsy.stock_id_strad (
	stock_id_area varchar primary key,
	stock_id_me varchar,
	stock_id varchar,
	stock_num int4,
	taxon_key int4,
	scientific_name varchar,
	common_name varchar,
	functional_group varchar,
	marine_layer_id int4,
	marine_layer varchar,
	stradling_or_not bool,
	area_id int4,
	area varchar,
	meow_id int4,
	stock_status varchar,
	date_modified int4,
	ref_id int4,
	date_entered int4,
	"comments" text 
);


--relative biomass table
create table cmsy.rel_biom (
	rel_biom_id serial primary key,
	rel_biom_meta_id int4,
	stock_id varchar,
	"year" int4,
	value float8,
	midlength float8
);



--relative biomass meta data table
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



--relative reference table
create table cmsy.reference (
	ref_id int4 primary key,
	author varchar,
	"year" int4,
	title text,
	"source" varchar,
	short_citation varchar,
	journal int4,
	"language" varchar,
	ref_type varchar,
	author_address text,
	pdf_file varchar,
	pdf_url text
);


	
--relative ref_content table
create table cmsy.ref_content (
	ref_content_id serial primary key,
	ref_id int4,
	stock_id varchar,
	page varchar,
	sci_name varchar,
	info_format varchar,
	info_drawn varchar
);



--priors table
CREATE TABLE cmsy.priors (
	priors_id serial NOT NULL,
	stock_id varchar NULL,
	min_of_year int4 NULL,
	max_of_year int4 NULL,
	start_year int4 NULL,
	end_year int4 NULL,
	main_ref_id int4 NULL,
	max_catch float8 NULL,
	last_catch float8 NULL,
	b_bmsy_last_5_years float8 NULL,
	flim float8 NULL,
	fpa float8 NULL,
	blim float8 NULL,
	bpa float8 NULL,
	fmsy float8 NULL,
	msy_btrigger float8 NULL,
	b40 float8 NULL,
	m float8 NULL,
	fofl float8 NULL,
	last_f float8 NULL,
	resilience varchar NULL,
	resilience_expert int4 NULL,
	r_low float8 NULL,
	r_hi float8 NULL,
	r_expert int4 NULL,
	r_modeled int4 NULL,
	r_source varchar NULL,
	stb_low float8 NULL,
	stb_hi float8 NULL,
	stb_expert int4 NULL,
	stb_modeled int4 NULL,
	int_year int4 NULL,
	intb_low float8 NULL,
	intb_hi float8 NULL,
	int_expert int4 NULL,
	int_modeled int4 NULL,
	endb_low float8 NULL,
	endb_hi float8 NULL,
	endb_expert int4 NULL,
	endb_modeled int4 NULL,
	q_start int4 NULL,
	q_end int4 NULL,
	q_expert int4 NULL,
	q_modeled int4 NULL,
	e_creep int4 NULL,
	btype varchar NULL,
	force_fmsy varchar NULL,
	msy_bsm float8 NULL,
	msy_bsm_lcl float8 NULL,
	msy_bsm_ucl float8 NULL,
	r_bsm float8 NULL,
	r_bsm_lcl float8 NULL,
	r_bsm_ucl float8 NULL,
	k_bsm float8 NULL,
	k_bsm_lcl float8 NULL,
	k_bsm_ucl float8 NULL,
	q_bsm float8 NULL,
	q_bsm_lcl float8 NULL,
	q_bsm_ucl float8 NULL,
	rel_b_bsm float8 NULL,
	rel_b_bsm_lcl float8 NULL,
	rel_b_bsm_ucl float8 NULL,
	rel_f_bsm float8 NULL,
	r_cmsy float8 NULL,
	r_cmsy_lcl float8 NULL,
	r_cmsy_ucl float8 NULL,
	k_cmsy float8 NULL,
	k_cmsy_lcl float8 NULL,
	k_cmsy_ucl float8 NULL,
	msy_cmsy float8 NULL,
	msy_cmsy_lcl float8 NULL,
	msy_cmsy_ucl float8 NULL,
	rel_b_cmsy float8 NULL,
	rel_b_cmsy_lcl float8 NULL,
	rel_b_cmsy_ucl float8 NULL,
	rel_f_cmsy float8 NULL,
	f_msy float8 NULL,
	f_msy_lcl float8 NULL,
	f_msy_ucl float8 NULL,
	curf_msy float8 NULL,
	curf_msy_lcl float8 NULL,
	curf_msy_ucl float8 NULL,
	msy float8 NULL,
	msy_lcl float8 NULL,
	msy_ucl float8 NULL,
	bmsy float8 NULL,
	bmsy_lcl float8 NULL,
	bmsy_ucl float8 NULL,
	b float8 NULL,
	b_lcl float8 NULL,
	b_ucl float8 NULL,
	b_bmsy float8 NULL,
	b_bmsy_lcl float8 NULL,
	b_bmsy_ucl float8 NULL,
	f float8 NULL,
	f_lcl float8 NULL,
	f_ucl float8 NULL,
	f_fmsy float8 NULL,
	f_fmsy_lcl float8 NULL,
	f_fmsy_ucl float8 NULL,
	sel_b float8 NULL,
	sel_b_bmsy float8 NULL,
	sel_f float8 NULL,
	sel_f_fmsy float8 NULL,
	input_date date NOT NULL DEFAULT 'now'::text::date,
	"comments" varchar NULL,
	questionable bool NOT NULL,
	to_be_used bool NOT NULL
);
	
--catch_input table
create table cmsy.catch_input (
	catch_input_id serial primary key,
	stock_id varchar,
	"year" int4,
	ct int4,
	bt int4
);