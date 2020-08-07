CREATE TABLE fishing_effort.fishing_effort(      
  case_number varchar(50),                                                                             
  fishing_entity_id int NOT NULL,
  eez_id int NOT NULL,
  subregional_area text NULL,
  sector_type_id text NOT NULL,
  year int NOT NULL,                 
  effort_gear varchar(20) NULL,
  effort_sector text NULL,
  length_code int NULL,
  length decimal(50,20) NULL,
  m_um text NULL,
  motorisation int NULL,
  estimated_gt decimal(50,20) NULL,
  kw_boat decimal(50,20) NULL,
  number_boats decimal(50,20) NULL,
  days_fished decimal(50,20) NULL,
  effort decimal(50,20) NULL,
  fe_qs int NULL,
  gear_qs int NULL,
  length_qs int NULL,
  number_boats_qs int NULL,
  seadays_qs int NULL,
  data_description text NULL,
  source text NULL,
  notes text NULL
);

CREATE TABLE fishing_effort.length_class (
  length_class_id int4 NULL,
  length_class_range varchar(32767) NULL
);

CREATE TABLE fishing_effort.fuel_coeff (
  "﻿year" int4 NULL,
  fuel_coeff float8 NULL
);

CREATE TABLE fishing_effort.fishing_effort_gear (
  gear_id int4 NULL,
  gear_name varchar(32767) NULL,
  sector_type varchar(32767) NULL,
  effort_gear_id varchar(32767) NULL,
  effort_gear_name varchar(32767) NULL
);


--Additional tables
--M.Nevado
--8.7.2020


CREATE TABLE fishing_effort.bait_amt_sector_boat (
	bait_sector_boat_code varchar(12) NOT NULL DEFAULT '0.00.0.0.0.0'::character varying,
	bait_amt float8 NOT NULL DEFAULT 0,
	CONSTRAINT bait_amt_sector_boat_pk PRIMARY KEY (bait_sector_boat_code)
);
CREATE UNIQUE INDEX fishing_entity_bait_amt_fishing_entity_idx ON fishing_effort.bait_amt_sector_boat USING btree (bait_sector_boat_code);

CREATE TABLE fishing_effort.bait_catch_byfishent (
	fishing_entity_id int2 NULL,
	"year" int2 NULL,
	sector_type_id int2 NULL,
	gear_type_id int2 NULL,
	catch_sum float8 NULL
);

CREATE TABLE fishing_effort.bait_fishent_otheruse (
	fishing_entity_id int2 NULL,
	"year" int4 NULL,
	otheruse float8 NULL
);

CREATE TABLE fishing_effort.bait_gear_codes (
	effort_gear_cfk varchar(6) NOT NULL DEFAULT '00.0.0'::character varying,
	effort_gear_name varchar(40) NOT NULL DEFAULT 'N/A'::character varying,
	bait_gear_cfk varchar(1) NOT NULL DEFAULT 'u'::character varying,
	bait_gear_name varchar(7) NOT NULL DEFAULT 'Unknown'::character varying
);

CREATE TABLE fishing_effort.bait_gears (
	bait_gear_code varchar(6) NOT NULL,
	bait_gear_name varchar(7) NOT NULL
);

CREATE TABLE fishing_effort.zfe_subregion_corrections (
	dosname varchar(50) NULL,
	utfname varchar(50) NULL
);



