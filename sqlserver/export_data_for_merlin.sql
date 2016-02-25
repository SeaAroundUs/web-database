\copy (SELECT id, fishing_entity_id, eez_id, title_of_agreement, NULL::varchar AS original_area_code, generate_simple_acronym(access_category) AS fishing_access, access_type_id, agreement_type_id, start_year, end_year, functional_group_id FROM master.access_agreement) to 'access_agreement.dat'

\copy (SELECT time_key, year FROM master.time) to 'AllocationYear.dat'

\copy (SELECT catch_type_id, name FROM master.catch_type) to 'CatchType.dat'

\copy (SELECT input_type_id, name FROM master.input_type) to 'InputType.dat'

\copy (SELECT layer_id, name FROM allocation.layer) to 'Layer.dat'

\copy (SELECT allocation_area_type_id, name, remarks FROM allocation.allocation_area_type) to 'AllocationAreaType.dat'
                                            
\copy (SELECT taxon_key,scientific_name,common_name,commercial_group_id,functional_group_id,sl_max,tl,taxon_level_id,taxon_group_id,isscaap_id FROM master.taxon WHERE NOT is_retired) to 'Cube_DimTaxon.dat'

\copy (SELECT * FROM log.v_merlin_eez) to 'EEZ.dat'

\copy (SELECT fao_area_id, name, alternate_name FROM master.fao_area) to 'FaoArea.dat'
                        
\copy (SELECT * FROM log.v_merlin_fishing_entity) to 'FishingEntity.dat'

\copy (SELECT functional_group_id,target_grp,name,description,include_in_depth_adjustment_function::int as include_in_depth_adjustment_function FROM master.functional_groups) to 'FunctionalGroup.dat'
  
\copy (SELECT geo_entity_id,name,admin_geo_entity_id,jurisdiction_id,started_eez_at,legacy_c_number,legacy_admin_c_number FROM master.geo_entity WHERE geo_entity_id != 0) to 'GeoEntity.dat'

\copy (SELECT fao_area_id FROM master.high_seas) to 'HighSea.dat'

\copy (SELECT ices_division,ices_subdivision,ices_area_id FROM allocation.ices_area) to 'ICES_Area.dat'

\copy (SELECT eez_id, ifa_is_located_in_this_fao FROM allocation.ifa) to 'IFA.dat'

\copy (SELECT lme_id,name,profile_url FROM master.lme) to 'LME.dat'
  
\copy (SELECT marine_layer_id,remarks,name,bread_crumb_name,show_sub_areas::int as show_sub_areas,last_report_year FROM master.marine_layer) to 'MarineLayer.dat'
       
\copy (SELECT sector_type_id, name FROM master.sector_type) to 'SectorType.dat'

\copy (SELECT taxon_distribution_id, taxon_key, cell_id, relative_abundance FROM allocation.taxon_distribution) to 'TaxonDistribution.dat'

\copy (SELECT original_taxon_key, use_this_taxon_key_instead FROM distribution.taxon_distribution_substitute) to 'TaxonDistributionSubstitute.dat'

\copy (SELECT * FROM log.v_merlin_data_raw) to 'DataRaw.dat'

\copy (SELECT cell_id, total_area, water_area FROM geo.cell WHERE water_area > 0) to 'Cell.dat'

\copy (SELECT big_cell_type_id,type_desc FROM geo.big_cell_type) to 'BigCellType.dat'

\copy (SELECT big_cell_id,big_cell_type_id,x,y,is_land_locked::int as ll,is_in_med::int as med,is_in_pacific::int as pac,is_in_indian::int as ind FROM geo.big_cell) to 'BigCell.dat'

\copy (SELECT cell_id FROM geo.cell_is_coastal) to 'CellIsCoastal.dat'

\copy (SELECT local_depth_adjustment_row_id,eez_id,cell_id FROM geo.depth_adjustment_row_cell) to 'DepthAdjustmentRowCell.dat'

\copy (SELECT eez_big_cell_combo_id,eez_id,fao_area_id,big_cell_id,is_ifa::int as ifa FROM geo.eez_big_cell_combo) to 'EEZ_BigCell_Combo.dat'

\copy (SELECT eez_ccamlar_combo_id,eez_id,fao_area_id,ccamlr_area_id,is_ifa::int as ifa  FROM geo.eez_ccamlr_combo) to 'EEZ_CCAMLR_Combo.dat'

\copy (SELECT eez_fao_area_id,reconstruction_eez_id,fao_area_id FROM geo.eez_fao_combo) to 'EEZ_FAO_Combo.dat'

\copy (SELECT eez_ices_combo_id,eez_id,fao_area_id,ices_area_id,is_ifa::int as ifa FROM geo.eez_ices_combo) to 'EEZ_ICES_Combo.dat'

\copy (SELECT eez_nafo_combo_id,eez_id,fao_area_id,nafo_division,is_ifa::int as ifa FROM geo.eez_nafo_combo) to 'EEZ_NAFO_Combo.dat'

\copy (SELECT fao_area_id,cell_id FROM geo.fao_cell) to 'FAOCell.dat'

\copy (SELECT fao_area_id,upper_left_cell_cell_id,scale FROM geo.fao_map) to 'FAOMap.dat'
                                                                                                                                
\copy (SELECT id,marine_layer_id,area_id,fao_area_id,cell_id,water_area FROM geo.simple_area_cell_assignment_raw) to 'SimpleAreaCellAssignmentRaw.dat'
