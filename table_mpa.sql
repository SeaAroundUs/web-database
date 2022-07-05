CREATE TABLE mpa.contacts (
	sau_mpa_id int4 NOT NULL,
	contact_type varchar NULL,
	contact_name varchar NULL,
	email varchar NULL,
	extra_email varchar NULL,
	description text NULL,
	sau_comments text NULL,
	fishing_level varchar NULL,
	sent varchar NULL,
	responded varchar NULL,
	response varchar NULL,
	combination varchar NULL,
	number_of_loopings int4 NULL,
	date_sent varchar NULL,
	time_sent varchar NULL,
	date_received varchar NULL,
	time_received varchar NULL,
	total_time float8 NULL
);

CREATE TABLE mpa.location_mpa (
	eez_id int4 NULL,
	eez varchar NULL,
	sau_mpa_id int4 NOT NULL,
	sau_mpa_name varchar NULL,
	sau_mpa_name_contains_dm bool NULL,
	wdpa_id int4 NULL,
	mpatlas_id int4 NULL,
	mpatlas_mpa_name varchar NULL,
	mpatlas_mpa_name_contains_dm bool NULL,
	mpa_name_original_language varchar NULL,
	mpa_name_original_language_contains_dm bool NULL,
	country varchar NULL,
	iso_code varchar NULL,
	notes text NULL
);

CREATE TABLE mpa.management (
	sau_mpa_id int4 NOT NULL,
	management_plan bool NULL,
	official_mpa_mp_name varchar NULL,
	title_in_non_roman_character_script bool NULL,
	english_title varchar NULL,
	english_title_contains_dm bool NULL,
	language_of_mp varchar NULL,
	filename varchar NULL,
	url_mp varchar NULL,
	manager_institution varchar NULL,
	contact_person_email varchar NULL,
	contact_person_description text NULL,
	mpatlas_links varchar NULL,
	protected_planet_links varchar NULL,
	reference_id varchar NULL
);

CREATE TABLE mpa.preception_level_of_protection (
	sau_mpa_id int4 NOT NULL,
	mpa_index varchar NULL,
	mpa_classification varchar NULL,
	mpa_protection_level varchar NULL,
	total_iucn_category varchar NULL,
	most_common_fl varchar NULL,
	most_common_fl_academics varchar NULL,
	most_common_fl_fishers varchar NULL,
	most_common_fl_governments varchar NULL,
	most_common_fl_journalists varchar NULL,
	most_common_fl_ngo varchar NULL
);

CREATE TABLE mpa.reference_key (
	sau_mpa_id int4 NOT NULL,
	reference_id varchar NULL
);

CREATE TABLE mpa."references" (
	reference_id int4 NOT NULL,
	author varchar NULL,
	"year" varchar NULL,
	title varchar NULL,
	"source" varchar NULL,
	url varchar NULL,
	"language" varchar NULL,
	original_language_title varchar NULL,
	original_language_source varchar NULL,
	notes text NULL,
	column1 varchar NULL,
	column2 varchar NULL
);

CREATE TABLE mpa.traits (
	sau_mpa_id int4 NULL,
	year_established int4 NULL,
	total_area float8 NULL,
	no_take_area bool NULL,
	total_no_take_area float8 NULL,
	percentag_total_area float8 NULL,
	number_of_zones int4 NULL,
	reference_id varchar NULL
);
