/* CellID */
/*
USE [Merlin_qa]
GO
TRUNCATE TABLE dbo.AllocationResult_By_Cell
GO
INSERT INTO dbo.AllocationResult_By_Cell
SELECT d.[DataLayerID], r.[CellID], SUM(r.AllocatedCatch) AllocatedCatchSum
  FROM [Merlin].[dbo].[AllocationResult] AS r
  JOIN [Merlin].[dbo].[Data] AS d ON (d.UniversalDataID = r.UniversalDataID) 
GROUP BY d.[DataLayerID], r.[CellID]
GO
TRUNCATE TABLE dbo.AllocationResult_By_Cell_qa
GO
INSERT INTO dbo.AllocationResult_By_Cell_qa
SELECT d.[DataLayerID], r.[CellID], SUM(r.AllocatedCatch) AllocatedCatchSum
  FROM [Merlin_qa].[dbo].[AllocationResult] AS r
  JOIN [Merlin_qa].[dbo].[Data] AS d ON (d.UniversalDataID = r.UniversalDataID) 
GROUP BY d.[DataLayerID], r.[CellID]
GO
SELECT ac.DataLayerID, ac.CellID, ac.AllocatedCatchSum AS MerlinAllocatedCS, qa.AllocatedCatchSum AS MerlinQAAllocatedCS, abs(ac.AllocatedCatchSum - qa.AllocatedCatchSum) AS diff
  FROM dbo.AllocationResult_By_Cell AS ac
  JOIN dbo.AllocationResult_By_Cell_qa AS qa ON (qa.CellID = ac.CellID AND qa.DataLayerID = ac.DataLayerID)
 ORDER BY diff DESC, ac.DataLayerID, ac.CellID;
GO
*/

/* Data
USE [Merlin_qa]
GO
SELECT [DataLayerID]
      ,[FishingEntityID]
      ,SUM(CatchAmount) AS CatchSum
  INTO dbo.Data_By_FishingEntity 
  FROM [Merlin].[dbo].[Data]
 GROUP BY [DataLayerID],[FishingEntityID]
GO
SELECT [DataLayerID]
      ,[FishingEntityID]
      ,SUM(CatchAmount) AS CatchSum
  INTO dbo.Data_By_FishingEntity_qa 
  FROM [Merlin_qa].[dbo].[Data]
 GROUP BY [DataLayerID],[FishingEntityID]
GO
SELECT [DataLayerID]
      ,[TaxonKey]
      ,SUM(CatchAmount) AS CatchSum
  INTO dbo.Data_By_Taxon 
  FROM [Merlin].[dbo].[Data]
 GROUP BY [DataLayerID],[TaxonKey]
GO
SELECT [DataLayerID]
      ,[TaxonKey]
      ,SUM(CatchAmount) AS CatchSum
  INTO dbo.Data_By_Taxon_qa 
  FROM [Merlin_qa].[dbo].[Data]
 GROUP BY [DataLayerID],[TaxonKey]
GO
SELECT [DataLayerID]
      ,[Year]
      ,SUM(CatchAmount) AS CatchSum
  INTO dbo.Data_By_Year
  FROM [Merlin].[dbo].[Data]
 GROUP BY [DataLayerID],[Year]
GO
SELECT [DataLayerID]
      ,[Year]
      ,SUM(CatchAmount) AS CatchSum
  INTO dbo.Data_By_Year_qa 
  FROM [Merlin_qa].[dbo].[Data]
 GROUP BY [DataLayerID],[Year]
GO
SELECT * FROM dbo.Data_By_FishingEntity EXCEPT SELECT * FROM dbo.Data_By_FishingEntity_qa ORDER BY 1, 2
GO
SELECT * FROM dbo.Data_By_Taxon EXCEPT SELECT * FROM dbo.Data_By_Taxon_qa ORDER BY 1, 2
GO
SELECT * FROM dbo.Data_By_Year EXCEPT SELECT * FROM dbo.Data_By_Year_qa ORDER BY 1, 2
GO

SELECT f.[DataLayerID], f.[FishingEntityID], f.[CatchSum], fa.[DataLayerID], fa.[FishingEntityID], fa.[CatchSum] 
  FROM dbo.Data_By_FishingEntity f FULL JOIN dbo.Data_By_FishingEntity_qa fa ON (f.[DataLayerID]=fa.[DataLayerID] AND f.[FishingEntityID]=fa.[FishingEntityID])
 WHERE f.[DataLayerID] IS NULL OR fa.[DataLayerID] IS NULL OR f.[FishingEntityID] IS NULL OR fa.[FishingEntityID] IS NULL
 ORDER BY 1, 2
GO
SELECT f.[DataLayerID], f.[TaxonKey], f.[CatchSum], fa.[DataLayerID], fa.[TaxonKey], fa.[CatchSum] 
  FROM dbo.Data_By_Taxon f FULL JOIN dbo.Data_By_Taxon_qa fa ON (f.[DataLayerID]=fa.[DataLayerID] AND f.[TaxonKey]=fa.[TaxonKey])
 WHERE f.[DataLayerID] IS NULL OR fa.[DataLayerID] IS NULL OR f.[TaxonKey] IS NULL OR fa.[TaxonKey] IS NULL
 ORDER BY 1, 2
GO
SELECT f.[DataLayerID], f.[Year], f.[CatchSum], fa.[DataLayerID], fa.[Year], fa.[CatchSum] 
  FROM dbo.Data_By_Year f FULL JOIN dbo.Data_By_Year fa ON (f.[DataLayerID]=fa.[DataLayerID] AND f.[Year]=fa.[Year])
 WHERE f.[DataLayerID] IS NULL OR fa.[DataLayerID] IS NULL OR f.[Year] IS NULL OR fa.[Year] IS NULL
 ORDER BY 1, 2
GO
*/