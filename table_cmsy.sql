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

--relative biomass table
create sequence rel_biom_seq start 1;
create table cmsy.rel_biom (
	rel_biom_id int4 not null default nextval('rel_biom_seq'::regclass),
	rel_biom_meta_id int4,
	stock_id varchar,
	"year" int4,
	value float8,
	midlength float8
);

--relative biomass meta data table
create sequence rel_biom_meta_seq start 1;
create table cmsy.rel_biom_meta (
	rel_biom_meta_id int4 not null default nextval('rel_biom_meta_seq'::regclass),
	stock_id varchar,
	data_type varchar,
	units varchar,
	year_start int4,
	year_end int4,
	years_missing int4,
	region_description varchar,
	gear_type_id int4,
	gear_type varchar,
	ref_id int4,
	"comments" text
);

--reference table
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
	
--ref_content table
create sequence ref_content_seq start 1;
create table cmsy.ref_content (
	ref_content_id int4 not null default nextval('ref_content_seq'::regclass),
	ref_id int4,
	stock_id int4,
	page varchar,
	sci_name varchar,
	info_format varchar,
	info_drawn varchar
);

--priors table
create sequence priors_seq start 1;
create table cmsy.priors (
	priors_id int4 not null default nextval('priors_seq'::regclass),
	stock_id varchar,
	min_of_year int4,
	max_of_year int4,
	start_year int4,
	end_year int4,
	main_ref_id int4,
	max_catch float8,
	last_catch float8,
	b_bmsy_last_5_years float8,
	flim float8,
	fpa float8,
	blim float8,
	bpa float8,
	fmsy float8,
	msy_btrigger float8,
	b40 float8,
	m float8,
	fofl float8,
	last_f float8,
	resilience varchar,
	resilience_expert int4,
	r_low float8,
	r_hi float8,
	r_expert int4,
	r_modeled int4,
	r_source varchar,
	stb_low float8,
	stb_hi float8,
	stb_expert int4,
	stb_modeled int4,
	int_year int4,
	intb_low float8,
	intb_hi float8,
	int_expert int4,
	int_modeled int4,
	endb_low float8,
	endb_hi float8,
	endb_expert int4,
	endb_modeled int4,
	q_start int4,
	q_end int4,
	q_expert int4,
	q_modeled int4,
	e_creep int4,
	btype varchar,
	force_fmsy varchar,
	msy_bsm float8,
	msy_bsm_lcl float8,
	msy_bsm_ucl float8,
	r_bsm float8,
	r_bsm_lcl float8,
	r_bsm_ucl float8,
	k_bsm float8,
	k_bsm_lcl float8,
	k_bsm_ucl float8,
	q_bsm float8,
	q_bsm_lcl float8,
	q_bsm_ucl float8,
	rel_b_bsm float8,
	rel_b_bsm_lcl float8,
	rel_b_bsm_ucl float8,
	rel_f_bsm float8,
	r_cmsy float8,
	r_cmsy_lcl float8,
	r_cmsy_ucl float8,
	k_cmsy float8,
	k_cmsy_lcl float8,
	k_cmsy_ucl float8,
	msy_cmsy float8,
	msy_cmsy_lcl float8,
	msy_cmsy_ucl float8,
	rel_b_cmsy float8,
	rel_b_cmsy_lcl float8,
	rel_b_cmsy_ucl float8,
	rel_f_cmsy float8,
	f_msy float8,
	f_msy_lcl float8,
	f_msy_ucl float8,
	curf_msy float8,
	curf_msy_lcl float8,
	curf_msy_ucl float8,
	msy float8,
	msy_lcl float8,
	msy_ucl float8,
	bmsy float8,
	bmsy_lcl float8,
	bmsy_ucl float8,
	b float8,
	b_lcl float8,
	b_ucl float8,
	b_bmsy float8,
	b_bmsy_lcl float8,
	b_bmsy_ucl float8,
	f float8,
	f_lcl float8,
	f_ucl float8,
	f_fmsy float8,
	f_fmsy_lcl float8,
	f_fmsy_ucl float8,
	sel_b float8,
	sel_b_bmsy float8,
	sel_f float8,
	sel_f_fmsy float8,
	input_date date not null default date,
	comments varchar,
	questionable bool not null,
	to_be_used bool not null
);
	
--catch_input table
create sequence catch_input_seq start 1;
create table cmsy.catch_input (
	catch_input_id int4 not null default nextval('catch_input_seq'::regclass),
	stock_id varchar,
	"year" int4,
	ct int4,
	bt int4
);

--meow_oceans_combo
create table geo.meow_oceans_combo (
	meow_ocean_combo_id serial primary key,
	meow_id int4,
	meow varchar,
	fao_area_id int4,
	"name" varchar
);