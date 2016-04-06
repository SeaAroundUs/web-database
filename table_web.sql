CREATE TABLE web.area(      
  area_key serial PRIMARY KEY,                                                                             
  marine_layer_id int NOT NULL,
  main_area_id int NOT NULL,
  sub_area_id int NOT NULL,
  area decimal(50,20) NULL,
  shelf_area decimal(50,20) NULL,
  ifa decimal(50,20) NULL,
  coral_reefs decimal(50,20) NULL,                 
  sea_mounts decimal(50,20) NULL,
  ppr decimal(50,20) NULL,
  number_of_cells int DEFAULT 0 NOT NULL,
  date_updated timestamp DEFAULT current_timestamp NULL
);


CREATE TABLE web.area_invisible(
  area_invisible_id serial PRIMARY KEY,
  marine_layer_id int NOT NULL,
  main_area_id int NOT NULL,
  sub_area_id int NOT NULL
);


CREATE TABLE web.commercial_groups(
  commercial_group_id smallint PRIMARY KEY,
  name varchar(100) NOT NULL
);

CREATE TABLE web.country(
  c_number int PRIMARY KEY,
  count_code varchar(4) NOT NULL,
  un_name varchar(10) NULL,
  admin varchar(4) NULL,
  fish_base varchar(4) NULL,
  a_code varchar(4) NULL,
  cia varchar(2) NULL,
  fao_fisheries varchar(4) NULL,
  country varchar(50) NULL,
  eez_area decimal(50,20) NULL,
  sea_mount decimal(50,20) NULL,
  per_sea_mount decimal(50,20) NULL,
  area_reef decimal(50,20) NULL,
  per_reef decimal(50,20) NULL,
  shelf_area decimal(50,20) NULL,
  avg_pprate decimal(50,20) NULL,
  eez_ppr bigint NULL,
  has_estuary smallint NULL,
  has_mpa smallint NULL,
  has_survey smallint NULL,
  territory smallint NULL,
  has_saup_profile smallint NULL,
  fao_profile_url_direct_link varchar(100) NULL,
  is_active boolean NOT NULL,
  fao_profile_url_v1 varchar(255) NULL,
  fao_profile_url varchar(255) NULL,
  fao_code varchar(50) NULL,
  admin_c_number int NULL
);

CREATE TABLE web.catch_type(
  catch_type_id smallint primary key,
  name varchar(50) not null                        
);

CREATE TABLE web.sector_type(
  sector_type_id smallint primary key,
  name varchar(50) not null
);

CREATE TABLE web.taxon_level(
  taxon_level_id int PRIMARY KEY,
  name VARCHAR(100),
  description TEXT
);

CREATE TABLE web.taxon_group(
  taxon_group_id int PRIMARY KEY,
  name VARCHAR(100),
  description TEXT
);

CREATE TABLE web.cube_dim_taxon(
  taxon_key int PRIMARY KEY,
  scientific_name varchar(255) NOT NULL,
  common_name varchar(255),
  phylum varchar(255),
  genus varchar(255),
  species varchar(255),
  comments_names text,
  is_retired boolean not null default false,
  taxon_group_id int,
  taxon_level_id int,
  functional_group_id smallint NOT NULL,
  commercial_group_id smallint NOT NULL,
  commercial smallint,
  isscaap_id int,
  cell_id int,
  super_target smallint,
  fb_spec_code int,
  slb_spec_code int,  
  cla_code int,
  ord_code int,
  fam_code int,
  gen_code int,
  spe_code int,
  slb_cla_code int,
  slb_ord_code int,
  slb_fam_code int,
  slb_gen_code int,
  is_use boolean,
  is_taxa_used boolean,
  is_mariculture_only boolean,
  is_baltic_only boolean NOT NULL,
  sl_max float,
  slbl_max_type varchar(10),	  
  sl_max_2 float,
  comments_sl_max text,
  tl float,
  se_tl float,
  comments_tl text,
  lat_north int,
  lat_south int,                                        
  min_depth int,
  max_depth int,
  loo float,
  woo float,
  k float,
  a float,
  b float,
  comments_growth text,
  has_habitat_index boolean NOT NULL,
  has_map boolean NOT NULL,
  map_year smallint,
  vulnerability	text,
  resilience text,
  updated_by varchar(255),
  date_updated date,
  x_min int,
  x_max int,
  y_min int,
  y_max int,
  lineage ltree
);

CREATE TABLE web.rare_taxon(
  taxon_key int PRIMARY KEY,
  scientific_name varchar(255) NOT NULL,
  common_name varchar(255) NOT NULL,
  created timestamp not null default now()
);

CREATE TABLE web.eez(
  eez_id int PRIMARY KEY,
  name varchar(50) NOT NULL,
  alternate_name varchar(500) NULL,
  geo_entity_id int NOT NULL,
  area_status_id int DEFAULT 2 NOT NULL,
  legacy_c_number int NOT NULL,
  legacy_count_code varchar(4) NOT NULL,
  fishbase_id varchar(4) NOT NULL,
  coords varchar(400) NULL,
  can_be_displayed_on_web boolean DEFAULT true NOT NULL,
  is_currently_used_for_web boolean DEFAULT false NOT NULL,
  is_currently_used_for_reconstruction boolean DEFAULT false NOT NULL,
  declaration_year int DEFAULT 1982 NOT NULL,
  earliest_access_agreement_date int NULL,
  is_home_eez_of_fishing_entity_id smallint NOT NULL,
  allows_coastal_fishing_for_layer2_data boolean DEFAULT true NOT NULL,
  ohi_link VARCHAR(400),
  is_retired BOOLEAN NOT NULL DEFAULT false
);

COMMENT ON COLUMN web.eez.alternate_name IS 'semicolon separated: alt_name1;alt_name2;alt_name3';
COMMENT ON COLUMN web.eez.coords IS 'coords of the map on this page: http://www.seaaroundus.org/eez/';


CREATE TABLE web.fao_area(
  fao_area_id int PRIMARY KEY,
  name varchar(50) NOT NULL,
  alternate_name varchar(50) NOT NULL,
  area_key int[]
);

CREATE SEQUENCE web.fishing_entity_fishing_entity_id_seq START 1 MAXVALUE 32767;

CREATE TABLE web.fishing_entity(
  fishing_entity_id smallint DEFAULT nextval('web.fishing_entity_fishing_entity_id_seq') PRIMARY KEY,
  name varchar(100) NOT NULL,
  geo_entity_id int NULL,
  date_allowed_to_fish_other_eEZs int NOT NULL,
  date_allowed_to_fish_high_seas int NOT NULL,
  legacy_c_number int NULL,
  is_currently_used_for_web boolean DEFAULT true NOT NULL,
  is_currently_used_for_reconstruction boolean DEFAULT true NOT NULL,
  is_allowed_to_fish_pre_eez_by_default boolean DEFAULT true NOT NULL,
  remarks varchar(50) NULL
);

ALTER SEQUENCE web.fishing_entity_fishing_entity_id_seq OWNED BY web.fishing_entity.fishing_entity_iD;

/*
CREATE TABLE web.fishing_entity_used_in_allocation_niu(
  fishing_entity_id smallint PRIMARY KEY
);
*/

CREATE TABLE web.functional_groups(
  functional_group_id smallint PRIMARY KEY,
  target_grp int NULL,
  name varchar(20) NULL,
  description varchar(50) NULL,
  include_in_depth_adjustment_function BOOLEAN NOT NULL,
  size_range numrange
);

CREATE TABLE web.gear(
  gear_id smallint PRIMARY KEY,
  name varchar(50) NOT NULL,
  super_code varchar(20) NOT NULL                              
);

CREATE TABLE web.geo_entity(
  geo_entity_id int PRIMARY KEY,      
  name varchar(50) NOT NULL,
  admin_geo_entity_id int NOT NULL,             
  jurisdiction_id int NULL,
  started_eez_at varchar(50) NULL,
  Legacy_c_number int NOT NULL,
  legacy_admin_c_number int NOT NULL
);


CREATE TABLE web.jurisdiction(
  jurisdiction_id int PRIMARY KEY,
  name varchar(50) NOT NULL,
  legacy_c_number int NOT NULL
);

CREATE TABLE web.lme(
  lme_id int PRIMARY KEY,
  name varchar(50) NOT NULL,
  profile_url varchar(255) DEFAULT 'http://www.lme.noaa.gov/' NOT NULL
);


CREATE TABLE web.mariculture_entity(
  mariculture_entity_id serial PRIMARY KEY,
  name varchar(50) NOT NULL,
  legacy_c_number int NOT NULL,
  fao_link varchar(255) NULL
);

CREATE TABLE web.mariculture_sub_entity(
  mariculture_sub_entity_id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  mariculture_entity_id int NOT NULL
);

CREATE TABLE web.mariculture_data(
  row_id serial PRIMARY KEY,
  mariculture_sub_entity_id int NOT NULL,
  taxon_key int NOT NULL,
  year int NOT NULL,
  production decimal(50,20) NOT NULL
);

CREATE TABLE web.geo_entity_mariculture_entity_mapping(
  mapping_id serial PRIMARY KEY,
  geo_entity_id int NOT NULL,
  mariculture_entity_id int NOT NULL,
  mariculture_sub_entity_id int NOT NULL
);

CREATE TABLE web.marine_layer(
  marine_layer_id serial PRIMARY KEY,
  remarks varchar(50) NOT NULL,
  name varchar(50) NOT NULL,
  bread_crumb_name varchar(50) NOT NULL,
  show_sub_areas boolean DEFAULT false NOT NULL,
  last_report_year int NOT NULL
);


CREATE TABLE web.reconstruction_paper(
  reconstruction_paper_id serial PRIMARY KEY,
  file_name varchar(255) NOT NULL,
  type int DEFAULT 1 NOT NULL
);


CREATE TABLE web.rfmo(
  rfmo_id int PRIMARY KEY,
  name varchar(50) NOT NULL,
  long_name varchar(255) NOT NULL,
  profile_url varchar(255) NULL
);

CREATE TABLE web.rfmo_managed_taxon(
  rfmo_id int PRIMARY KEY,
  primary_taxon_keys int[],
  secondary_taxon_keys int[],
  taxon_check_required boolean default true,
  modified timestamp NOT NULL DEFAULT now()
);

CREATE TABLE web.rfmo_procedure_and_outcome ( 
  rfmo_id INTEGER PRIMARY KEY, 
  name CHARACTER VARYING(50) NOT NULL, 
  contracting_parties TEXT NOT NULL, 
  area TEXT NOT NULL, 
  date_entered_into_force int, 
  fao_association BOOLEAN NOT NULL, 
  fao_statistical_area CHARACTER VARYING(50), 
  objectives TEXT NOT NULL, 
  primary_species TEXT NOT NULL, 
  content TEXT NOT NULL
);

CREATE TABLE web.sub_geo_entity(
  sub_geo_entity_id serial PRIMARY KEY,
  c_number int NOT NULL,
  name varchar(255) NOT NULL,
  geo_entity_id int NOT NULL
);


CREATE TABLE web.time(
  time_key int PRIMARY KEY,
  time_business_key int NOT NULL
);

CREATE TABLE web.estuary(
  id_number int NOT NULL,
  label varchar(100) NULL,
  code varchar(12) NULL,
  country varchar(60) NULL,
  admin_code int NULL,
  c_number int NULL,
  continent varchar(50) NULL,
  discharge decimal(50,20) NULL,
  river_sys varchar(100) NULL,
  input_lat decimal(50,20) NULL,
  input_lon decimal(50,20) NULL,
  ref1 int NULL,
  ref2 int NULL,
  year_start int NULL,
  year_end int NULL,
  year_pub int NULL,
  sub smallint,
  eez_id int,
  geo_entity_id int,
  geom geometry(MultiPolygon,4326)
);

CREATE TABLE web.area_bucket_type(      
  area_bucket_type_id serial primary key,                                                                             
  marine_layer_id int not null,
  name varchar(100) not null,
  area_id_type varchar(100) not null,
  description text
);

CREATE TABLE web.area_bucket(
  area_bucket_id serial primary key,
  area_bucket_type_id int not null,
  name varchar(100) not null,
  area_id_bucket int[] not null,
  area_id_reference int default null
);

CREATE TABLE web.subsidy_definition(
  definition_id varchar(2) NOT NULL,
  title varchar(100) NULL,
  description text NOT NULL
);

CREATE TABLE web.subsidy_ref_definition(
  reference_id int PRIMARY KEY,
  url varchar(255) NULL,
  link_text varchar(60) NOT NULL,
  author varchar(255) NULL,
  year decimal(50,20) NULL,
  title varchar(255) NULL,
  source varchar(255) NULL
);

CREATE TABLE web.subsidy_ref_mapping(
  geo_entity_id int NOT NULL,
  a1 int NULL,
  a2 int NULL,
  a3 int NULL,
  b1 int NULL,
  b2 int NULL,
  b3 int NULL,
  b4 int NULL,
  b5 int NULL,
  b6 int NULL,                                                         
  b7 int NULL,
  c1 int NULL,
  c2 int NULL,
  c3 int NULL
);

CREATE TABLE web.subsidy(
  geo_entity_id int not null,
  country varchar(255) NOT NULL,
  c_number int NOT NULL,
  landed_value decimal(50,20) NOT NULL,
  a1 decimal(50,20) NOT NULL,
  a2 decimal(50,20) NOT NULL,
  a3 decimal(50,20) NOT NULL,
  b1 decimal(50,20) NOT NULL,
  b2 decimal(50,20) NOT NULL,
  b3 decimal(50,20) NOT NULL,
  b4 decimal(50,20) NOT NULL,
  b5 decimal(50,20) NOT NULL,
  b6 decimal(50,20) NOT NULL,
  b7 decimal(50,20) NOT NULL,
  c1 decimal(50,20) NOT NULL,
  c2 decimal(50,20) NOT NULL,
  c3 decimal(50,20) NOT NULL,
  year int not null default 2000,
  CONSTRAINT subsidy_pkey PRIMARY KEY (geo_entity_id, year)
);

CREATE TABLE web.fishing_agreement(
  code CHAR(2) PRIMARY KEY,
  description TEXT
);

CREATE TABLE web.access_type(
  id INT PRIMARY KEY,
  description TEXT
);

CREATE TABLE web.agreement_type(
  id INT PRIMARY KEY,
  description TEXT
);

CREATE TABLE web.access_agreement(
  id smallserial primary key,  
  fishing_entity_id int not null CHECK(fishing_entity_id > 0 AND fishing_entity_id != 213),
  fishing_entity varchar(255),
  eez_id int not null,
  eez_name varchar(255),
  title_of_agreement varchar(255),
  access_category varchar(255) not null,
  access_type_id int not null,
  agreement_type_id int not null,
  start_year int not null,
  end_year int not null,
  duration_type varchar(255),
  duration_details varchar(255),
  functional_group_id varchar(255),
  functional_group_details varchar(255),
  fees varchar(255),
  quotas varchar(255),
  other_restrictions varchar(255),
  notes_on_agreement text,
  ref_id int,
  source_link text,
  pdf varchar(255),
  correct_pdf varchar(255),
  verified varchar(255),
  farisis_cd_agreement varchar(255),
  reference_original varchar(255),
  location_reference_original varchar(255),
  reference varchar(255),
  title_of_reference varchar(255),
  location_reference varchar(255),
  reference_type varchar(255),
  pages varchar(255),
  number_of_boats varchar(255),
  gear varchar(255),
  notes_on_the_references text,
  change_log text,
  checked_by_vl varchar(255),
  status_of_the_records varchar(255),
  old_id int,
  old_source_id int,
  old_c_number int,
  old_area_code varchar(255),
  old_start_year int,
  old_end_year int,
  old_target_grp_sum bigint,
  old_ref_id varchar(255),
  old_source varchar(255),
  old_assumed_end boolean,
  old_use boolean,
  old_reason_not_used varchar(255)
);

CREATE TABLE web.country_ngo(
  country_ngo_id serial primary key,
  count_code varchar(4) NULL,
  country_name varchar(50) NULL,
  international smallint NULL,
  ngo_name varchar(255) NULL,
  address varchar(255) NULL,
  tel_number varchar(50) NULL,
  fax varchar(50) NULL,
  email varchar(100) NULL,
  website varchar(255) NULL
);

CREATE TABLE web.country_fishery_profile(
  profile_id serial PRIMARY KEY,
  c_number int NULL,
  count_code varchar(4) NOT NULL,
  country_name varchar(50) NULL,
  fish_mgt_plan varchar(255) NULL,
  url_fish_mgt_plan varchar(255) NULL,
  gov_marine_fish varchar(255) NULL,
  major_law_plan varchar(255) NULL,
  url_major_law_plan varchar(255) NULL,
  gov_protect_marine_env varchar(255) NULL,
  url_gov_protect_marine_env varchar(255) NULL
);

CREATE TABLE web.habitat_index(
  taxon_key serial PRIMARY KEY,
  taxon_name varchar(50) NULL,
  common_name varchar(50) NULL,
  sl_max float NULL,
  cla_code integer, 
  ord_code integer, 
  fam_code integer, 
  gen_code integer, 
  spe_code integer, 
  habitat_diversity_index decimal(50,20) NULL,
  effective_d decimal(50,20) NULL,
  estuaries decimal(50,20) NULL,
  coral decimal(50,20) NULL,
  seagrass decimal(50,20) NULL,
  seamount decimal(50,20) NULL,
  others decimal(50,20) NULL,
  shelf decimal(50,20) NULL,
  slope decimal(50,20) NULL,
  abyssal decimal(50,20) NULL,
  inshore decimal(50,20) NULL,
  offshore decimal(50,20) NULL
);

CREATE TABLE web.eez_to_fishbase_url(
  eez_id int primary key,
  eez_name text,
  fao_area_id int,
  fao_area_id2 int,
  c_code text,
  country_fb_note text,
  country_fb_paese text,
  c_code2 text,
  e_code int,
  eco_system_name text,
  e_code2 int,
  eco_system_name2 text,
  eez_id_txt int,
  fb_url text
);

CREATE TABLE web.lme_fishbase_link(
  e_code int primary key,
  eco_system_name text,
  other_names text,
  eco_system_type text,
  ready boolean,
  location text,
  species_count int,
  lme_id int
);

CREATE TABLE web.data_layer (
  data_layer_id smallint DEFAULT 0 PRIMARY KEY,
  name character varying(255) NOT NULL
);

CREATE TABLE web.v_fact_data(
  area_data_key serial primary key, 
  taxon_key integer,
  fishing_entity_id smallint,
  gear_id smallint,
  time_key integer,
  year integer,
  area_key integer,
  main_area_id integer,
  sub_area_id integer,
  data_layer_id smallint,
  marine_layer_id integer,
  catch_type_id smallint,
  catch_status character(1),
  reporting_status character(1),
  sector_type_id smallint,
  catch_sum numeric(50, 20),
  real_value double precision,
  primary_production_required double precision,
  catch_trophic_level numeric,
  catch_max_length numeric
);

CREATE TABLE web.cell(
  cell_id int PRIMARY KEY,
  lon decimal(20,10) NULL,
  lat decimal(20,10) NULL,
  row int NULL,
  col int NULL,
  t_area decimal(50,20) NULL,
  area decimal(50,20) NULL,
  p_water decimal(50,20) NULL,
  ele_min decimal(50,20) NULL,
  ele_max decimal(50,20) NULL,
  ele_avg decimal(50,20) NULL,
  elevation_min decimal(50,20) NULL,
  elevation_max decimal(50,20) NULL,
  elevation_mean decimal(50,20) NULL,
  bathy_min decimal(50,20) NULL,
  bathy_max decimal(50,20) NULL,
  bathy_mean decimal(50,20) NULL,
  fao_area_id int NULL,
  lme_id int NULL,
  bgcp decimal(50,20) NULL,
  distance decimal(50,20) NULL,
  coastal_prop decimal(50,20) NULL,
  shelf decimal(50,20) NULL,
  slope decimal(50,20) NULL,
  abyssal decimal(50,20) NULL,
  estuary decimal(50,20) NULL,
  mangrove decimal(50,20) NULL,
  seamount_saup decimal(50,20) NULL,
  seamount decimal(50,20) NULL,
  coral decimal(50,20) NULL,
  p_prod decimal(50,20) NULL,
  ice_con decimal(50,20) NULL,      
  sst decimal(50,20) NULL,
  eez_count int NULL,
  sst_2001 decimal(50,20) NULL,
  bt_2001 decimal(50,20) NULL,
  pp_10_yr_avg decimal(50,20) NULL,
  sst_avg decimal(50,20) NULL,
  pp_annual decimal(50,20) NULL
);

CREATE TABLE web.entity_layer(
  entity_layer_id serial PRIMARY KEY,
  name varchar(50) NOT NULL
);

/* This is the facade table acting as the parent table to the series of child tables (partition) in the web_partition schema */
CREATE TABLE web.cell_catch(
  fishing_entity_id smallint,
  cell_id int,
  year smallint,
  taxon_key int,
  commercial_group_id smallint,
  functional_group_id smallint,
  catch_status character(1),
  reporting_status character(1),
  sector_type_id smallint,
  catch_sum numeric
);

CREATE TABLE web.cell_catch_global_cache(
  year smallint primary key,
  result json
);

CREATE TABLE web.dictionary ( 
  dictionary_id SERIAL PRIMARY KEY, 
  word VARCHAR(100) NOT NULL, 
  definition TEXT NOT NULL
);

CREATE TABLE web.catch_data_in_csv_cache(
  entity_layer_id smallint,
  entity_id int,
  csv_data text,
  seq serial primary key
);

CREATE TABLE web.uncertainty_time_period(
  period_id smallint primary key,
  year_range int4range not null
);

CREATE TABLE web.uncertainty_score(
  score smallint primary key,
  score_name varchar(30),
  tolerance smallint,
  ipcc_criteria text
);

CREATE TABLE web.uncertainty_eez(
    eez_id int not null,
    sector_type_id smallint,
    period_id smallint,
    score smallint,
    CONSTRAINT uncertainty_eez_pkey PRIMARY KEY(eez_id, sector_type_id, period_id)
);
