DROP PROCEDURE [dbo].[PullDataFromIntegrationDB];
GO
CREATE PROCEDURE [dbo].[PullDataFromIntegrationDB]
AS
BEGIN
  DECLARE @msg NVARCHAR(256);
  DECLARE @MaxUniversalDataID INT;
  
  /* dbo.AgreementRaw */
  SET @msg = char(10) + 'Pulling down AgreementRaw...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[AgreementRaw];
  INSERT INTO [dbo].[AgreementRaw](
	[ID],
	[FishingEntityID],
	[EEZID],
	[Title],
	[OriginalAreaCode], 
	[FishingAccess],
	[AccessType],
	[AgreementType],
	[StartYear],
	[EndYear],
	[FunctionalGroupID])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT id, fishing_entity_id, eez_id, title_of_agreement, NULL::varchar AS original_area_code, generate_simple_acronym(access_category) AS fishing_access, access_type_id, agreement_type_id, start_year, end_year, functional_group_id
              FROM master.access_agreement');
  ALTER INDEX ALL ON [dbo].[AgreementRaw] REORGANIZE;
	
  /* dbo.Cube_DimTaxon */
  SET @msg = char(10) + 'Pulling down Cube_DimTaxon...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[Cube_DimTaxon];
  INSERT INTO [dbo].[Cube_DimTaxon](
       [TaxonKey]
      ,[Scientific Name]
      ,[Common Name]
      ,[CommercialGroupID]
      ,[FunctionalGroupID]
      ,[SLmax]
      ,[TL]
      ,[TaxonLevelID]
      ,[TaxonGroupID]
      ,[ISSCAAP_ID]
      ,[LatNorth]
      ,[LatSouth]
      ,[MinDepth]
      ,[MaxDepth]
      ,[Loo]
      ,[Woo]
      ,[K]
      ,[XMin]
      ,[XMax]
      ,[YMin]
      ,[YMax]
      ,[HasHabitatIndex]
      ,[HasMap]
      ,[IsBalticOnly])   
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT taxon_key,scientific_name,common_name,commercial_group_id,functional_group_id,
                   sl_max,tl,taxon_level_id,taxon_group_id,isscaap_id,lat_north,lat_south,min_depth,max_depth,
                   loo,woo,k,x_min,x_max,y_min,y_max,has_habitat_index::int as has_habitat_index,has_map::int as has_map,is_baltic_only::int as is_baltic_only
              FROM master.taxon
             WHERE NOT is_retired');
  ALTER INDEX ALL ON [dbo].[Cube_DimTaxon] REORGANIZE;
   
  /* dbo.TaxonDistribution */
  SET @msg = char(10) + 'Pulling down TaxonDistribution...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[TaxonDistribution];
  SET IDENTITY_INSERT [dbo].[TaxonDistribution] ON;
  INSERT INTO [dbo].[TaxonDistribution](TaxonDistributionID, TaxonKey, CellID, RelativeAbundance)
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT taxon_distribution_id, taxon_key, cell_id, relative_abundance
              FROM distribution.taxon_distribution');
  SET IDENTITY_INSERT [dbo].[TaxonDistribution] OFF;
  ALTER INDEX ALL ON [dbo].[TaxonDistribution] REORGANIZE;
  
  /* dbo.AllocationYear */
  SET @msg = char(10) + 'Pulling down AllocationYear...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[AllocationYear];
  INSERT INTO [dbo].[AllocationYear](YearID, Name)
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT time_key, year 
	          FROM master.time');
  ALTER INDEX ALL ON [dbo].[AllocationYear] REORGANIZE;
  
  /* dbo.CatchType */
  SET @msg = char(10) + 'Pulling down CatchType...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[CatchType];
  INSERT INTO [dbo].[CatchType](CatchTypeID, Name)
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT catch_type_id, name
	          FROM master.catch_type');
  ALTER INDEX ALL ON [dbo].[CatchType] REORGANIZE;
	
  /* dbo.InputType */
  SET @msg = char(10) + 'Pulling down InputType...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[InputType];
  INSERT INTO [dbo].[InputType]([InputTypeID], [Name])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT input_type_id, name
              FROM master.input_type');
  ALTER INDEX ALL ON [dbo].[InputType] REORGANIZE;
    
  /* dbo.Layer */
  SET @msg = char(10) + 'Pulling down Layer...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[Layer];
  INSERT INTO [dbo].[Layer]([LayerID], [Name])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT layer_id, name
              FROM allocation.layer');
  ALTER INDEX ALL ON [dbo].[Layer] REORGANIZE;
    
  /* dbo.AllocationAreaType */
  SET @msg = char(10) + 'Pulling down AllocationAreaType...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[AllocationAreaType];                                         
  INSERT INTO [dbo].[AllocationAreaType]([AllocationAreaTypeID],[Name],[Remarks])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT allocation_area_type_id, name, remarks
              FROM allocation.allocation_area_type');
  ALTER INDEX ALL ON [dbo].[AllocationAreaType] REORGANIZE;
    
  /* dbo.EEZ */
  SET @msg = char(10) + 'Pulling down EEZ...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[EEZ];
  INSERT INTO [dbo].[EEZ](
       [EEZID]
      ,[Name]
      ,[AlternateName]
      ,[GeoEntityID]
      ,[AreaStatusID]
      ,[Legacy_CNumber]
      ,[Legacy_CountCode]
      ,[FishbaseID]
      ,[Coords]
      ,[CanBeDisplayedOnWeb]
      ,[IsCurrentlyUsedForWeb]
      ,[IsCurrentlyUsedForReconstruction]
      ,[DeclarationYear]
      ,[EarliestAccessAgreementDate]
      ,[IsHomeEEZOfFishingEntityID]
      ,[AllowsCoastalFishingForLayer2Data])
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT eez_id,name,alternate_name,geo_entity_id,area_status_id,legacy_c_number,legacy_count_code,fishbase_id,
                   coords,can_be_displayed_on_web::int as can_be_displayed_on_web,is_currently_used_for_web::int as is_currently_used_for_web,
                   is_currently_used_for_reconstruction::int as is_currently_used_for_reconstruction, declaration_year,earliest_access_agreement_date,
                   is_home_eez_of_fishing_entity_id,allows_coastal_fishing_for_layer2_data::int as allows_coastal_fishing_for_layer2_data
              FROM master.eez
             WHERE eez_id NOT IN (0, 999)');
  ALTER INDEX ALL ON [dbo].[EEZ] REORGANIZE;
  
  /* dbo.FaoArea */
  SET @msg = char(10) + 'Pulling down FaoArea...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[FaoArea];
  INSERT INTO [dbo].[FaoArea]([FaoAreaID],[Name],[AlternateName])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT fao_area_id, name, alternate_name
              FROM master.fao_area');
  ALTER INDEX ALL ON [dbo].[FaoArea] REORGANIZE;
    
  /* dbo.FishingEntity */
  SET @msg = char(10) + 'Pulling down FishingEntity...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[FishingEntity];
  INSERT INTO [dbo].[FishingEntity](
       [FishingEntityID]
      ,[Name]
      ,[GeoEntityID]
      ,[DateAllowedToFishOtherEEZs]
      ,[DateAllowedToFishHighSeas]
      ,[Legacy_Cnumber]
      ,[IsCurrentlyUsedForWeb]
      ,[IsCurrentlyUsedForReconstruction]
      ,[IsAllowedToFishPreEEZByDefault]
      ,[Remarks])
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB,
           'SELECT fishing_entity_id,name,geo_entity_id,date_allowed_to_fish_other_eezs,date_allowed_to_fish_high_seas,
                   legacy_c_number,is_currently_used_for_web::int as is_currently_used_for_web,
                   is_currently_used_for_reconstruction::int as is_currently_used_for_reconstruction,is_allowed_to_fish_pre_eez_by_default::int,remarks
              FROM master.fishing_entity
             WHERE is_currently_used_for_reconstruction');
  ALTER INDEX ALL ON [dbo].[FishingEntity] REORGANIZE;
  
  /* dbo.FunctionalGroup */
  SET @msg = char(10) + 'Pulling down FunctionalGroup...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[FunctionalGroup]; 
  INSERT INTO [dbo].[FunctionalGroup]([FunctionalGroupID],[TargetGrp],[Name],[Description],[IncludeInDepthAdjustmentFunction])
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT functional_group_id,target_grp,name,description,include_in_depth_adjustment_function::int as include_in_depth_adjustment_function 
              FROM master.functional_groups');
  ALTER INDEX ALL ON [dbo].[FunctionalGroup] REORGANIZE;
    
  /* dbo.GeoEntity */
  SET @msg = char(10) + 'Pulling down GeoEntity...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[GeoEntity]; 
  INSERT INTO [dbo].[GeoEntity](
       [GeoEntityID]
      ,[Name]
      ,[AdminGeoEntityID]
      ,[JurisdictionID]
      ,[StartedEEZAt]
      ,[Legacy_cnumber]
      ,[Legacy_Admin_cnumber])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT geo_entity_id,name,admin_geo_entity_id,jurisdiction_id,started_eez_at,legacy_c_number,legacy_admin_c_number
              FROM master.geo_entity
             WHERE geo_entity_id != 0');
  ALTER INDEX ALL ON [dbo].[GeoEntity] REORGANIZE;
    
  /* dbo.HighSea */
  SET @msg = char(10) + 'Pulling down HighSea...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[HighSea];
  INSERT INTO [dbo].[HighSea]([FAOAreaID])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT fao_area_id
              FROM master.high_seas');
  ALTER INDEX ALL ON [dbo].[HighSea] REORGANIZE;
    
  /* dbo.ICES_Area */
  SET @msg = char(10) + 'Pulling down ICES_Area...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[ICES_Area];
  INSERT INTO [dbo].[ICES_Area]([ICESdivision], [ICESSubdivision], [ICES_AreaID])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT ices_division,ices_subdivision,ices_area_id
              FROM allocation.ices_area');
  ALTER INDEX ALL ON [dbo].[ICES_Area] REORGANIZE;
  
  /* dbo.IFA */
  SET @msg = char(10) + 'Pulling down IFA...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[IFA];
  INSERT INTO [dbo].[IFA]([EEZID], [IFA is located in this FAO])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT eez_id, ifa_is_located_in_this_fao
              FROM allocation.ifa');
  ALTER INDEX ALL ON [dbo].[IFA] REORGANIZE;
  
  /* dbo.LME */
  SET @msg = char(10) + 'Pulling down LME...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[LME];
  INSERT INTO [dbo].[LME]([LMEID],[Name],[ProfileUrl])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT lme_id,name,profile_url
              FROM master.lme');
  ALTER INDEX ALL ON [dbo].[LME] REORGANIZE;
    
  /* dbo.MarineLayer */
  SET @msg = char(10) + 'Pulling down MarineLayer...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[MarineLayer];
  INSERT INTO [dbo].[MarineLayer](
       [MarineLayerID]
      ,[Remarks]
      ,[Name]
      ,[BreadCrumbName]
      ,[ShowSubAreas]
      ,[LastReportYear])
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT marine_layer_id,remarks,name,bread_crumb_name,show_sub_areas::int as show_sub_areas,last_report_year 
              FROM master.marine_layer');
  ALTER INDEX ALL ON [dbo].[MarineLayer] REORGANIZE;
    
  /* dbo.SectorType */
  SET @msg = char(10) + 'Pulling down SectorType...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[SectorType];
  INSERT INTO [dbo].[SectorType]([SectorTypeID],[Name])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT sector_type_id, name
              FROM master.sector_type');
  ALTER INDEX ALL ON [dbo].[SectorType] REORGANIZE;
    
  /* dbo.DataRaw */
  SET @msg = char(10) + 'Pulling down DataRaw...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[DataRaw];
  INSERT INTO [dbo].[DataRaw](
	   [ExternalDataRowID]
	  ,[DataLayerID]
	  ,[FishingEntityID]
	  ,[EEZID]
	  ,[FAOArea]
	  ,[Year]
	  ,[TaxonKey]
	  ,[CatchAmount]
	  ,[Sector]
	  ,[CatchTypeID]
	  ,[Input]
	  ,[ICES_AreaID]
	  ,[CCAMLRArea]
	  ,[NAFODivision]
  )
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT c.id,c.layer,c.fishing_entity_id,c.eez_id,c.fao_area_id,c.year,c.taxon_key,c.amount,st.name as sector,c.catch_type_id,it.name as input,ia.ices_area,c.ccamlr_area,na.nafo_division
              FROM recon.catch c
              JOIN master.sector_type st ON (st.sector_type_id = c.sector_type_id)
              JOIN master.input_type it ON (it.input_type_id = c.input_type_id)
              LEFT JOIN recon.ices_area ia ON (ia.ices_area_id = c.ices_area_id)
              LEFT JOIN recon.nafo na ON (na.nafo_division_id = c.nafo_division_id)');
  ALTER INDEX ALL ON [dbo].[DataRaw] REORGANIZE;
  
  /* dbo.TaxonDistributionSubstitute */
  SET @msg = char(10) + 'Pulling down TaxonDistributionSubstitute...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[TaxonDistributionSubstitute];
  INSERT INTO [dbo].[TaxonDistributionSubstitute]([OriginalTaxonKey],[UseThisTaxonKeyInstead])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT original_taxon_key, use_this_taxon_key_instead
              FROM distribution.taxon_distribution_substitute');
  ALTER INDEX ALL ON [dbo].[TaxonDistributionSubstitute] REORGANIZE;
    
  /*
   GIS-related tables 
  */
  
  /* dbo.SimpleAreaCellAssignmentRaw */
  SET @msg = char(10) + 'Pulling down SimpleAreaCellAssignmentRaw...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[SimpleAreaCellAssignmentRaw];
  SET IDENTITY_INSERT [dbo].[SimpleAreaCellAssignmentRaw] ON;
  INSERT INTO [dbo].[SimpleAreaCellAssignmentRaw](
	   [ID]
      ,[MarineLayerID]
      ,[AreaID]
      ,[FAOAreaID]
      ,[CellID]
      ,[WaterArea]
  )
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT id,marine_layer_id,area_id,fao_area_id,cell_id,water_area
              FROM geo.simple_area_cell_assignment_raw');
  SET IDENTITY_INSERT [dbo].[SimpleAreaCellAssignmentRaw] OFF;
  ALTER INDEX ALL ON [dbo].[SimpleAreaCellAssignmentRaw] REORGANIZE;
  
  /* dbo.Cell */
  SET @msg = char(10) + 'Pulling down Cell...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  DELETE FROM [dbo].[Cell];
  INSERT INTO [dbo].[Cell](CellID, TotalArea, WaterArea)
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT cell_id, total_area, water_area
              FROM geo.cell 
             WHERE water_area > 0');
  ALTER INDEX ALL ON [dbo].[Cell] REORGANIZE;
  
  /* dbo.BigCellType */
  SET @msg = char(10) + 'Pulling down BigCellType...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[BigCellType];
  INSERT INTO [dbo].[BigCellType]([BigCellTypeID], [TypeDesc])
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT big_cell_type_id,type_desc
              FROM geo.big_cell_type');
  ALTER INDEX ALL ON [dbo].[BigCellType] REORGANIZE;
  
  /* dbo.BigCell */
  SET @msg = char(10) + 'Pulling down BigCell...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[BigCell];
  SET IDENTITY_INSERT [dbo].[BigCell] ON;
  INSERT INTO [dbo].[BigCell](
       [BigCellID]
      ,[BigCellTypeID]
      ,[x]
      ,[y]
      ,[IsLandlocked]
      ,[IsInMed]
      ,[IsInPacific]
      ,[IsInIndian]
  )
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT big_cell_id,big_cell_type_id,x,y,is_land_locked::int as ll,is_in_med::int as med,is_in_pacific::int as pac,is_in_indian::int as ind
              FROM geo.big_cell');
  SET IDENTITY_INSERT [dbo].[BigCell] OFF;
  ALTER INDEX ALL ON [dbo].[BigCell] REORGANIZE;
  
  /* dbo.CellIsCoastal */
  SET @msg = char(10) + 'Pulling down CellIsCoastal...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[CellIsCoastal];
  INSERT INTO [dbo].[CellIsCoastal]([CellID])
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT cell_id
              FROM geo.cell_is_coastal');
  ALTER INDEX ALL ON [dbo].[CellIsCoastal] REORGANIZE;
                          
  /* dbo.CellIsCoastal */
  SET @msg = char(10) + 'Pulling down DepthAdjustmentRowCell...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[DepthAdjustmentRowCell];
  INSERT INTO [dbo].[DepthAdjustmentRowCell](
  	   [LocalDepthAdjustmenRowID]
      ,[EEZID]
      ,[CellID]
  )
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT local_depth_adjustment_row_id,eez_id,cell_id
              FROM geo.depth_adjustment_row_cell');
  ALTER INDEX ALL ON [dbo].[DepthAdjustmentRowCell] REORGANIZE;
      
  /* dbo.EEZ_BigCell_Combo */
  SET @msg = char(10) + 'Pulling down EEZ_BigCell_Combo...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[EEZ_BigCell_Combo];
  INSERT INTO [dbo].[EEZ_BigCell_Combo](
	   [EEZ_BigCell_ComboID]
	  ,[EEZID]
	  ,[FAOAreaID]
	  ,[BigCellID]
	  ,[IsIFA]
  )
  SELECT *
    FROM openquery(           
           SAU_INTEGRATION_DB, 
           'SELECT eez_big_cell_combo_id,eez_id,fao_area_id,big_cell_id,is_ifa::int as ifa
              FROM geo.eez_big_cell_combo');
  ALTER INDEX ALL ON [dbo].[EEZ_BigCell_Combo] REORGANIZE;
              
  /* dbo.EEZ_CCAMLR_Combo */
  SET @msg = char(10) + 'Pulling down EEZ_CCAMLR_Combo...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[EEZ_CCAMLR_Combo];
  INSERT INTO [dbo].[EEZ_CCAMLR_Combo](
	   [EEZ_CCAMLAR_ComboID]
	  ,[EEZID]
	  ,[FAOAreaID]
	  ,[CCAMLR_AreaID]
	  ,[IsIFA]  
  )
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT eez_ccamlar_combo_id,eez_id,fao_area_id,ccamlr_area_id,is_ifa::int as ifa
              FROM geo.eez_ccamlr_combo');
  ALTER INDEX ALL ON [dbo].[EEZ_CCAMLR_Combo] REORGANIZE;
              
  /* dbo.EEZ_FAO_Combo */
  SET @msg = char(10) + 'Pulling down EEZ_FAO_Combo...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[EEZ_FAO_Combo];
  SET IDENTITY_INSERT [dbo].[EEZ_FAO_Combo] ON;
  INSERT INTO [dbo].[EEZ_FAO_Combo](
	   [EEZFAOAreaID]
	  ,[ReconstructionEEZID]
	  ,[FAOAreaID]
  )
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT eez_fao_area_id,reconstruction_eez_id,fao_area_id
              FROM geo.eez_fao_combo');
  SET IDENTITY_INSERT [dbo].[EEZ_FAO_Combo] OFF;
  ALTER INDEX ALL ON [dbo].[EEZ_FAO_Combo] REORGANIZE;
  
  /* dbo.EEZ_ICES_Combo */
  SET @msg = char(10) + 'Pulling down EEZ_ICES_Combo...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[EEZ_ICES_Combo];
  INSERT INTO [dbo].[EEZ_ICES_Combo](
	   [EEZ_ICES_ComboID]
	  ,[EEZID]
	  ,[FAOAreaID]
	  ,[ICES_AreaID]
	  ,[IsIFA]
  )
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT eez_ices_combo_id,eez_id,fao_area_id,ices_area_id,is_ifa::int as ifa
              FROM geo.eez_ices_combo');
  ALTER INDEX ALL ON [dbo].[EEZ_ICES_Combo] REORGANIZE;
 
  /* dbo.EEZ_NAFO_Combo */
  SET @msg = char(10) + 'Pulling down EEZ_NAFO_Combo...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[EEZ_NAFO_Combo];
  INSERT INTO [dbo].[EEZ_NAFO_Combo](
	   [EEZ_NAFO_ComboID]
      ,[EEZID]
      ,[FAOAreaID]
      ,[NAFODivision]
      ,[IsIFA]
  )
  SELECT *
    FROM openquery(
           SAU_INTEGRATION_DB, 
           'SELECT eez_nafo_combo_id,eez_id,fao_area_id,nafo_division,is_ifa::int as ifa
              FROM geo.eez_nafo_combo');
  ALTER INDEX ALL ON [dbo].[EEZ_NAFO_Combo] REORGANIZE;
              
  /* dbo.FAOCell */
  SET @msg = char(10) + 'Pulling down FAOCell...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[FAOCell];
  INSERT INTO [dbo].[FAOCell](
  	   [FAOAreaID]
      ,[CellID]
  )
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT fao_area_id,cell_id
              FROM geo.fao_cell');
  ALTER INDEX ALL ON [dbo].[FAOCell] REORGANIZE;
  
  /* dbo.FAOMap */
  SET @msg = char(10) + 'Pulling down FAOMap...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[FAOMap];
  INSERT INTO [dbo].[FAOMap](
  	   [FAOAreaID]
      ,[UpperLeftCell_CellID]
      ,[Scale]
  )
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT fao_area_id,upper_left_cell_cell_id,scale
              FROM geo.fao_map');
  ALTER INDEX ALL ON [dbo].[FAOMap] REORGANIZE;
    
  /* dbo.Price */
  /*   
       NOTE: This Price table is not for allocation consumption. 
       It is synced only for occasional reporting purposes where price figures are needed 
  */
  SET @msg = char(10) + 'Pulling down Price...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[Price];
  INSERT INTO [dbo].[Price]([Year],[FishingEntityID],[Taxonkey],[Price])
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT year,fishing_entity_id,taxon_key,price
              FROM master.price');
  ALTER INDEX ALL ON [dbo].[Price] REORGANIZE;
  
  /* dbo.world */
  /*
  SET @msg = char(10) + 'Pulling down world...'; 
  RAISERROR (@msg, 0, 1) WITH NOWAIT;
  TRUNCATE TABLE [dbo].[world];
  INSERT INTO [dbo].[world](
       [Seq]
      ,[Lon]
      ,[Lat]
      ,[Row]
      ,[Col]
      ,[TArea]
      ,[Water_Area]
      ,[PWater]
      ,[EleMin]
      ,[EleMax]
      ,[EleAvg]
      ,[Elevation_Min]
      ,[Elevation_Max]
      ,[Elevation_Mean]
      ,[Bathy_Min]
      ,[Bathy_Max]
      ,[Bathy_Mean]
      ,[BGCP]
      ,[Distance]
      ,[CoastalProp]
      ,[Shelf]
      ,[Slope]
      ,[Abyssal]
      ,[Estuary]
      ,[Mangrove]
      ,[SeamountSAUP]
      ,[Seamount]
      ,[Coral]
      ,[PProd]
      ,[IceCon]
      ,[SST]
      ,[EEZcount]
      ,[SST2001]
      ,[BT2001]
      ,[PP10YrAvg]
      ,[SSTAvg]
      ,[PPAnnual]
  )
  SELECT *                
    FROM openquery(    
           SAU_INTEGRATION_DB, 
	       'SELECT cell_id,lon,lat,row,col,t_area,water_area,p_water,ele_min,ele_max,ele_avg,elevation_min,elevation_max,elevation_mean,bathy_min,bathy_max,bathy_mean,
                   bgcp,distance,coastal_prop,shelf,slope,abyssal,estuary,mangrove,seamount_saup,seamount,coral,p_prod,ice_con,sst,eez_count,sst_2001,bt_2001,pp_10_yr_avg,sst_avg,pp_annual
              FROM geo.world');
  ALTER INDEX ALL ON [dbo].[world] REORGANIZE;
  */
END            

GO
