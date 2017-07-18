drop view if exists web.v_taxon_habitat_index;

drop table web.habitat_index;

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
  front decimal(50,20) NULL,
  seagrass decimal(50,20) NULL,
  seamount decimal(50,20) NULL,
  others decimal(50,20) NULL,
  shelf decimal(50,20) NULL,
  slope decimal(50,20) NULL,
  abyssal decimal(50,20) NULL,
  inshore decimal(50,20) NULL,
  offshore decimal(50,20) NULL,
  temperature decimal(50,20) NULL
);

create or replace view web.v_taxon_habitat_index
as
  select hi.taxon_key,
         hi.taxon_name,
         hi.common_name as name,
         hi.sl_max,
         hi.cla_code,
         hi.ord_code,
         hi.fam_code,
         hi.gen_code,
         hi.spe_code,
         hi.habitat_diversity_index,
         hi.effective_d as effective_distance,
         hi.estuaries,
         hi.coral,
		 hi.front,
         hi.seagrass,
         hi.seamount,
         hi.others,
         hi.shelf as c_shelf,
         hi.slope as c_slope,
         hi.abyssal,
         hi.inshore,
         hi.offshore,
		 hi.temperature
    from web.habitat_index hi;
	
select admin.grant_access();
