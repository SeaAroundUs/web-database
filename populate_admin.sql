TRUNCATE TABLE admin.datatransfer_tables;
ALTER SEQUENCE admin.datatransfer_tables_id_seq RESTART;

--INSERT INTO admin.datatransfer_tables(source_database_name, source_table_name, source_where_clause, target_schema_name, target_table_name, target_excluded_columns)
--VALUES
--('Merlin', 'AllocationAreaType', NULL, 'allocation', 'allocation_area_type', '{}'::TEXT[])
--;

-- Below are tables to be processed with multiple threads each due to their size
INSERT INTO admin.datatransfer_tables(source_database_name, source_table_name, source_where_clause, target_schema_name, target_table_name, target_excluded_columns, source_key_column, number_of_threads)
VALUES
 ('Merlin', 'SimpleAreaCellAssignmentRaw', 'WHERE MarineLayerID IS NOT NULL', 'allocation', 'simple_area_cell_assignment_raw', '{}'::TEXT[], 'ID', 9)
,('Merlin', 'AllocationSimpleArea', NULL, 'allocation', 'allocation_simple_area', '{}'::TEXT[], 'AllocationSimpleAreaID', 9)
,('Merlin', 'Cell', NULL, 'allocation', 'cell', '{}'::TEXT[], NULL, 1)
,('Merlin', 'Data', NULL, 'allocation', 'allocation_data', ARRAY['unit_price']::TEXT[], 'UniversalDataID', 9)
,('Merlin', 'AllocationResult', NULL, 'allocation', 'allocation_result', '{}'::TEXT[], 'RowID', 9)
;

INSERT INTO admin.datatransfer_tables(source_database_name, source_table_name, source_where_clause, target_schema_name, target_table_name, target_excluded_columns)
VALUES                    
 ('sau_int', 'master.commercial_groups', NULL, 'web', 'commercial_groups', '{}'::TEXT[]) 
,('sau_int', 'master.country', NULL, 'web', 'country', '{}'::TEXT[])
,('sau_int', 'master.catch_type', NULL, 'web', 'catch_type', '{}'::TEXT[])
,('sau_int', 'master.sector_type', NULL, 'web', 'sector_type', '{}'::TEXT[])
,('sau_int', 'master.taxon_level', NULL, 'web', 'taxon_level', '{}'::TEXT[])
,('sau_int', 'master.taxon_group', NULL, 'web', 'taxon_group', '{}'::TEXT[])
,('sau_int', 'master.cell', NULL, 'web', 'cell', '{}'::TEXT[])
,('sau_int', 'master.taxon', 'where not is_retired', 'web', 'cube_dim_taxon', '{}'::TEXT[])
,('sau_int', 'master.rare_taxon', NULL, 'web', 'rare_taxon', '{}'::TEXT[])
,('sau_int', 'master.eez', 'where not is_retired', 'web', 'eez', '{}'::TEXT[])
,('sau_int', 'master.fao_area', NULL, 'web', 'fao_area', ARRAY['area_key']::TEXT[])  --(web has the extra column area_key int[] that needs to be populated by a function)
,('sau_int', 'master.fishing_entity', 'WHERE is_currently_used_for_reconstruction', 'web', 'fishing_entity', '{}'::TEXT[])
,('sau_int', 'master.functional_groups', NULL, 'web', 'functional_groups', '{}'::TEXT[])
,('sau_int', 'master.gear', NULL, 'web', 'gear', '{}'::TEXT[])
,('sau_int', 'master.geo_entity', NULL, 'web', 'geo_entity', '{}'::TEXT[])
,('sau_int', 'master.jurisdiction', NULL, 'web', 'jurisdiction', '{}'::TEXT[])
,('sau_int', 'master.lme', NULL, 'web', 'lme', '{}'::TEXT[])
,('sau_int', 'master.mariculture_entity', NULL, 'web', 'mariculture_entity', '{}'::TEXT[])
,('sau_int', 'master.mariculture_sub_entity', NULL, 'web', 'mariculture_sub_entity', '{}'::TEXT[])
,('sau_int', 'master.marine_layer', NULL, 'web', 'marine_layer', '{}'::TEXT[])
,('sau_int', 'master.rfmo', NULL, 'web', 'rfmo', '{}'::TEXT[])
,('sau_int', 'master.rfmo_managed_taxon', NULL, 'web', 'rfmo_managed_taxon', '{}'::TEXT[])
,('sau_int', 'master.rfmo_procedure_and_outcome', NULL, 'web', 'rfmo_procedure_and_outcome', '{}'::TEXT[])
,('sau_int', 'master.sub_geo_entity', NULL, 'web', 'sub_geo_entity', '{}'::TEXT[])
,('sau_int', 'master.time', NULL, 'web', 'time', '{}'::TEXT[])
,('sau_int', 'master.access_type', NULL, 'web', 'access_type', '{}'::TEXT[])
,('sau_int', 'master.agreement_type', NULL, 'web', 'agreement_type', '{}'::TEXT[])
,('sau_int', 'master.access_agreement', NULL, 'web', 'access_agreement', '{}'::TEXT[])
,('sau_int', 'master.habitat_index', NULL, 'web', 'habitat_index', '{}'::TEXT[])      --(note this is a view in the int db)
,('sau_int', 'master.data_layer', NULL, 'web', 'data_layer', '{}'::TEXT[])
,('sau_int', 'master.uncertainty_time_period', NULL, 'web', 'uncertainty_time_period', '{}'::TEXT[])
,('sau_int', 'master.uncertainty_score', NULL, 'web', 'uncertainty_score', '{}'::TEXT[])
,('sau_int', 'master.uncertainty_eez', 'u, master.sector_type s where u.sector = s.name', 'web', 'uncertainty_eez', '{}'::TEXT[])
,('sau_int', 'master.area_invisible', NULL, 'web', 'area_invisible', '{}'::TEXT[])
,('sau_int', 'distribution.taxon_distribution', NULL, 'distribution', 'taxon_distribution', '{}'::TEXT[])
;
