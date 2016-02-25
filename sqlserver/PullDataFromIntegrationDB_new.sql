SELECT  'Pulling down AgreementRaw...'; 
TRUNCATE TABLE AgreementRaw;
\copy AgreementRaw(ID,FishingEntityID,EEZID,Title,OriginalAreaCode,FishingAccess,AccessType,AgreementType,StartYear,EndYear,FunctionalGroupID) from 'access_agreement.dat'

/* dbo.AllocationYear */
SELECT  'Pulling down AllocationYear...'; 
DELETE FROM AllocationYear;
\copy AllocationYear(YearID, Name) from 'AllocationYear.dat'

/* dbo.CatchType */                                           
SELECT  'Pulling down CatchType...'; 
DELETE FROM CatchType;
\copy CatchType(CatchTypeID, Name) from 'CatchType.dat'

/* dbo.InputType */
SELECT  'Pulling down InputType...'; 
DELETE FROM InputType;
\copy InputType(InputTypeID, Name) from 'InputType.dat'
  
/* dbo.Layer */
SELECT  'Pulling down Layer...'; 
DELETE FROM Layer;
\copy Layer(LayerID, Name) from 'Layer.dat'
  
/* dbo.AllocationAreaType */
SELECT  'Pulling down AllocationAreaType...'; 
DELETE FROM AllocationAreaType;
\copy AllocationAreaType(AllocationAreaTypeID,Name,Remarks) from 'AllocationAreaType.dat'
  
/* dbo.Cube_DimTaxon */
SELECT  'Pulling down Cube_DimTaxon...'; 
DELETE FROM Cube_DimTaxon;
\copy Cube_DimTaxon(TaxonKey,Scientific_Name,Common_Name,CommercialGroupID,FunctionalGroupID,SLmax,TL,TaxonLevelID,TaxonGroupID,ISSCAAP_ID) from 'Cube_DimTaxon.dat'   
 
/* dbo.EEZ */
SELECT  'Pulling down EEZ...'; 
DELETE FROM EEZ;
\copy EEZ(EEZID,Name,AlternateName,GeoEntityID,AreaStatusID,Legacy_CNumber,Legacy_CountCode,FishbaseID,Coords,CanBeDisplayedOnWeb,IsCurrentlyUsedForWeb,IsCurrentlyUsedForReconstruction,DeclarationYear,EarliestAccessAgreementDate,IsHomeEEZOfFishingEntityID,AllowsCoastalFishingForLayer2Data) from 'EEZ.dat'

/* dbo.FaoArea */              
SELECT  'Pulling down FaoArea...'; 
DELETE FROM FaoArea;
\copy FaoArea(FaoAreaID,Name,AlternateName) from 'FaoArea.dat'
  
/* dbo.FishingEntity */
SELECT  'Pulling down FishingEntity...'; 
DELETE FROM FishingEntity;
\copy FishingEntity(FishingEntityID,Name,GeoEntityID,DateAllowedToFishOtherEEZs,DateAllowedToFishHighSeas,Legacy_Cnumber,IsCurrentlyUsedForWeb,IsCurrentlyUsedForReconstruction,IsAllowedToFishPreEEZByDefault,Remarks) from 'FishingEntity.dat'

/* dbo.FunctionalGroup */                  
SELECT  'Pulling down FunctionalGroup...'; 
DELETE FROM FunctionalGroup; 
\copy FunctionalGroup(FunctionalGroupID,TargetGrp,Name,Description,IncludeInDepthAdjustmentFunction) from 'FunctionalGroup.dat'
  
/* dbo.GeoEntity */
SELECT  'Pulling down GeoEntity...'; 
DELETE FROM GeoEntity; 
\copy GeoEntity(GeoEntityID,Name,AdminGeoEntityID,JurisdictionID,StartedEEZAt,Legacy_cnumber,Legacy_Admin_cnumber) from 'GeoEntity.dat'
  
/* dbo.HighSea */
SELECT  'Pulling down HighSea...'; 
DELETE FROM HighSea;
\copy HighSea(FAOAreaID) from 'HighSea.dat'
  
/* dbo.ICES_Area */
SELECT  'Pulling down ICES_Area...'; 
DELETE FROM ICES_Area;
\copy ICES_Area(ICESdivision, ICESSubdivision, ICES_AreaID) from 'ICES_Area.dat'
                                                                                                                                          
/* dbo.IFA */
SELECT  'Pulling down IFA...'; 
DELETE FROM IFA;
\copy IFA(eez_id, FAO_area_id) from 'IFA.dat'

/* dbo.LME */
SELECT  'Pulling down LME...'; 
DELETE FROM LME;
\copy LME(LMEID,Name,ProfileUrl) from 'LME.dat'
  
/* dbo.MarineLayer */
SELECT  'Pulling down MarineLayer...'; 
DELETE FROM MarineLayer;
\copy MarineLayer(MarineLayerID,Remarks,Name,BreadCrumbName,ShowSubAreas,LastReportYear) from 'MarineLayer.dat'
  
/* dbo.SectorType */
SELECT  'Pulling down SectorType...'; 
DELETE FROM SectorType;
\copy SectorType(SectorTypeID,Name) from 'SectorType.dat'
  
/* dbo.TaxonDistribution */
SELECT  'Pulling down TaxonDistribution...'; 
TRUNCATE TABLE TaxonDistribution;
\copy TaxonDistribution(TaxonDistributionID, TaxonKey, CellID, RelativeAbundance) from 'TaxonDistribution.dat'

/* dbo.TaxonDistributionSubstitute */
SELECT  'Pulling down TaxonDistributionSubstitute...'; 
TRUNCATE TABLE TaxonDistributionSubstitute;
\copy TaxonDistributionSubstitute(OriginalTaxonKey,UseThisTaxonKeyInstead) from 'TaxonDistributionSubstitute.dat'
  
/*
 GIS-related tables 
*/

/* dbo.Cell */
SELECT  'Pulling down Cell...'; 
DELETE FROM Cell;
\copy Cell(CellID, TotalArea, WaterArea) from 'Cell.dat'

/* dbo.BigCellType */
SELECT  'Pulling down BigCellType...'; 
TRUNCATE TABLE BigCellType;
\copy BigCellType(BigCellTypeID, TypeDesc) from 'BigCellType.dat'

/* dbo.BigCell */
SELECT  'Pulling down BigCell...'; 
TRUNCATE TABLE BigCell;
\copy BigCell(BigCellID,BigCellTypeID,x,y,IsLandlocked,IsInMed,IsInPacific,IsInIndian) from 'BigCell.dat'

/* dbo.CellIsCoastal */
SELECT  'Pulling down CellIsCoastal...'; 
TRUNCATE TABLE CellIsCoastal;
\copy CellIsCoastal(CellID) from 'CellIsCoastal.dat'
                        
/* dbo.CellIsCoastal */
SELECT  'Pulling down DepthAdjustmentRowCell...'; 
TRUNCATE TABLE DepthAdjustmentRowCell;
\copy DepthAdjustmentRowCell(LocalDepthAdjustmenRowID,EEZID,CellID) from 'DepthAdjustmentRowCell.dat'
    
/* dbo.EEZ_BigCell_Combo */
SELECT  'Pulling down EEZ_BigCell_Combo...'; 
TRUNCATE TABLE EEZ_BigCell_Combo;
\copy EEZ_BigCell_Combo(EEZ_BigCell_ComboID,EEZID,FAOAreaID,BigCellID,IsIFA) from 'EEZ_BigCell_Combo.dat'
            
/* dbo.EEZ_CCAMLR_Combo */
SELECT  'Pulling down EEZ_CCAMLR_Combo...'; 
TRUNCATE TABLE EEZ_CCAMLR_Combo;
\copy EEZ_CCAMLR_Combo(EEZ_CCAMLAR_ComboID,EEZID,FAOAreaID,CCAMLR_AreaID,IsIFA) from 'EEZ_CCAMLR_Combo.dat'
            
/* dbo.EEZ_FAO_Combo */
SELECT  'Pulling down EEZ_FAO_Combo...'; 
TRUNCATE TABLE EEZ_FAO_Combo;
\copy EEZ_FAO_Combo(EEZFAOAreaID,ReconstructionEEZID,FAOAreaID) from 'EEZ_FAO_Combo.dat'

/* dbo.EEZ_ICES_Combo */
SELECT  'Pulling down EEZ_ICES_Combo...'; 
TRUNCATE TABLE EEZ_ICES_Combo;
\copy EEZ_ICES_Combo(EEZ_ICES_ComboID,EEZID,FAOAreaID,ICES_AreaID,IsIFA) from 'EEZ_ICES_Combo.dat'

/* dbo.EEZ_NAFO_Combo */
SELECT  'Pulling down EEZ_NAFO_Combo...'; 
TRUNCATE TABLE EEZ_NAFO_Combo;
\copy EEZ_NAFO_Combo(EEZ_NAFO_ComboID,EEZID,FAOAreaID,NAFODivision,IsIFA) from 'EEZ_NAFO_Combo.dat'
            
/* dbo.FAOCell */
SELECT  'Pulling down FAOCell...'; 
TRUNCATE TABLE FAOCell;
\copy FAOCell(FAOAreaID,CellID) from 'FAOCell.dat'
                 
/* dbo.FAOMap */
SELECT  'Pulling down FAOMap...'; 
TRUNCATE TABLE FAOMap;
\copy FAOMap(FAOAreaID,UpperLeftCell_CellID,Scale) from 'FAOMap.dat'
  
/* dbo.SimpleAreaCellAssignmentRaw */
SELECT  'Pulling down SimpleAreaCellAssignmentRaw...'; 
TRUNCATE TABLE SimpleAreaCellAssignmentRaw;
\copy SimpleAreaCellAssignmentRaw(ID,MarineLayerID,AreaID,FAOAreaID,CellID,WaterArea) from 'SimpleAreaCellAssignmentRaw.dat'

/* dbo.DataRaw */
SELECT  'Pulling down DataRaw...'; 
TRUNCATE TABLE DataRaw;
\copy DataRaw(ExternalDataRowID,DataLayerID,FishingEntityID,EEZID,FAOArea,Year,TaxonKey,CatchAmount,Sector,CatchTypeID,Input,ICES_AreaID,CCAMLRArea,NAFODivision) from 'DataRaw.dat'
