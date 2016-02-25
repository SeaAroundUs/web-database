CREATE PROCEDURE [dbo].[ActualAllocationProcessLinh]
       @this_FishingEntityID int
AS
BEGIN
  with results as (
    select d.UniversalDataID, 
           d.UniqueAreaID_AutoGen as UniqueAreaID, 
           c.AllocationSimpleAreaID, 
           c.CellID, 
           c.WaterArea * t.RelativeAbundance As WaterArea_X_RelativeAbundance, 
           d.CatchAmount as TotalCatch, 
           d.TaxonKey as TaxonKey
      from dbo.Data d 
     inner join [dbo].[AutoGen_AllocationAllProcess_UniqueArea_Cell] c on d.UniqueAreaID_AutoGen = c.UniqueAreaID
     inner join TaxonDistribution t on c.CellID = t.CellID
     where t.TaxonKey =d.TaxonKey 
       AND d.[OriginalFishingEntityID] = @this_FishingEntityID
  ),
  SumRelativeAbundance as (
    select UniversalDataID, SUM(WaterArea_X_RelativeAbundance) as SumRelativeAbundance
      from results
     group by UniversalDataID
  )
  insert into AllocationResult
  select r.[UniversalDataID]
        ,r.[AllocationSimpleAreaID]
        ,r.[CellID]
        ,r.TotalCatch * r.WaterArea_X_RelativeAbundance / s.SumRelativeAbundance 
    from results r 
   inner join SumRelativeAbundance s on r.UniversalDataID = s.UniversalDataID 
   where s.SumRelativeAbundance > 0

DBCC SHRINKFILE (Merlin_Log, 1);
END
