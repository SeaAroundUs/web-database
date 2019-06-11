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