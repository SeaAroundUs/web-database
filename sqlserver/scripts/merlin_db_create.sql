USE [master]
GO
/****** Object:  Database [Merlin]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE DATABASE [Merlin]
GO
ALTER DATABASE [Merlin] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Merlin].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Merlin] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Merlin] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Merlin] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Merlin] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Merlin] SET ARITHABORT OFF 
GO
ALTER DATABASE [Merlin] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Merlin] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Merlin] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Merlin] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Merlin] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Merlin] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Merlin] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Merlin] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Merlin] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Merlin] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Merlin] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Merlin] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Merlin] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Merlin] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Merlin] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Merlin] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Merlin] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Merlin] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Merlin] SET  MULTI_USER 
GO
ALTER DATABASE [Merlin] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Merlin] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Merlin] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Merlin] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [Merlin] SET DELAYED_DURABILITY = DISABLED 
GO
USE [Merlin]
GO
/****** Object:  User [merlinwww]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE USER [merlinwww] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [merlinwuser]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE USER [merlinwuser] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[db_datareader]
GO
/****** Object:  User [merlin_mainapp2014]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE USER [merlin_mainapp2014] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_securityadmin] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_datareader] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [merlinwww]
GO
ALTER ROLE [db_owner] ADD MEMBER [merlin_mainapp2014]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [merlin_mainapp2014]
GO
ALTER ROLE [db_securityadmin] ADD MEMBER [merlin_mainapp2014]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [merlin_mainapp2014]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [merlin_mainapp2014]
GO
ALTER ROLE [db_datareader] ADD MEMBER [merlin_mainapp2014]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [merlin_mainapp2014]
GO
/****** Object:  Schema [archive]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE SCHEMA [archive]
GO
/****** Object:  Schema [input]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE SCHEMA [input]
GO
/****** Object:  Schema [summary]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE SCHEMA [summary]
GO
/****** Object:  UserDefinedFunction [dbo].[GetCellsForGenericArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[GetCellsForGenericArea]
(
	 @UniversalDataID_usedForLogging int,
     @AllocationAreaTypeID tinyint,
     @GenericAreaID int,
     @DataLayerID tinyint
)
RETURNS 
@result TABLE(AllocationSimpleAreaID int 
					  ,CellID int
					  ,WaterArea float)
AS
BEGIN

					  
IF @AllocationAreaTypeID = 1
	   insert into @result
	   select AllocationSimpleAreaID,CellID,WaterArea
	   from SimpleAreaCellAssignment 
	   where AllocationSimpleAreaID = @GenericAreaID
 
IF @AllocationAreaTypeID = 2
	   -- this was when we  used the tblAutoGen_HybridAreaCellMapper, the reason we stopped using it was that 1) it craeted a large table, 2) it timed out to create it
	   --  insert into @result
	   --select AllocationSimpleAreaID,CellID,WaterArea
	   --from dbo.AutoGen_HybridAreaCellMapper a
	   --where a.HybridAreaID = @GenericAreaID
	  insert into @result
	  SELECT c.AllocationSimpleAreaID, c.CellID, c.WaterArea
      FROM [Merlin].[dbo].[AutoGen_HybridToSimpleAreaMapper] a 
	  inner join dbo.SimpleAreaCellAssignment c on
	  a.ContainsAllocationSimpleAreaID = c.AllocationSimpleAreaID
	  where  a.HybridAreaID = @GenericAreaID
	  
----------------------------------------------------------------------------------------------------------------
-- factor in if the cosstal cells need to be removed from the cell set: done differntly for layer 2 and 3
IF (@DataLayerID = 2 )
-- for this layer some EEZs allow, some dont.
		BEGIN
		--refactor: this means, if there is overlapping claims on a cell, if one of the countires is not allowing coastal fishing, that would be suffienct reson to remove that cell
		DECLARE @forbiddenCoastalCells TABLE(CellID int)	
	
			insert into @forbiddenCoastalCells
			select r.cellid
			from @result r inner join CellIsCoastal c on r.cellid = c.cellid
			where r.AllocationSimpleAreaID in (select distinct AllocationSimpleAreaID from dbo.vwAllocationSimpleArea where InheritedAtt_AllowsCoastalFishingForLayer2Data = 0 )		  

			DELETE from @result
			where  CellID  in (Select cellID from @forbiddenCoastalCells)

		END


--IF (@DataLayerID = 3 )
---- for this layer, coastal cells are never allowed
--		BEGIN
--			DELETE from @result
--			where  CellID  in (Select cellID from CellIsCoastal)

--		END
-----------------------------------------------------------

DECLARE @Cellsrowcount int
			set @Cellsrowcount = (select count(*) from @result)
			if (@Cellsrowcount = 0 and @UniversalDataID_usedForLogging > 0)
			BEGIN
				Exec dbo.Log_CreateEntry_InternalProcess 'Func_dbo.GetCellsForGenericArea', @UniversalDataID_usedForLogging , 'ERROR: This combo yielded zero cells (possible cause: subtraction of coastal cells)'
			END
    return 
END

GO
/****** Object:  UserDefinedFunction [dbo].[internal_generate_AllocationSimpleAreaTable]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[internal_generate_AllocationSimpleAreaTable] 
(
	
)
RETURNS 
@result TABLE(
	AllocationSimpleAreaID [int] IDENTITY(1,1) NOT NULL,
	MarineLayerID [tinyint] NOT NULL,
	AreaID [int] NOT NULL,
	FaoAreaID [tinyint] NOT NULL,
	IsActive [bit] NOT NULL ,
	InheritedAtt_BelongsToReconstructionEEZID [int] NOT NULL,
	InheritedAtt_IsIFA [bit] NOT NULL,
	InheritedAtt_AllowsCoastalFishingForLayer2Data [bit] NOT NULL,
	UNIQUE NONCLUSTERED ([MarineLayerID],[AreaID],[FaoAreaID])
)
AS
BEGIN

DECLARE @ActiveEEZs TABLE(EEZID [int])
insert into @ActiveEEZs
select distinct EEZID
from Arash.DW.DBO.EEZ
where [IsCurrentlyUsedForReconstruction] = 1


--------------------------------------------------------------------
--EEZs
--------------------------------------------------------------------
insert into @result
select 12 As MarineLayerID
	   , [ReconstructionEEZID] as AreaID
	   , FAOAreaID
	   , 1 as Active 
	   , [ReconstructionEEZID] as InheritedAtt_BelongsToReconstructionEEZID
	   , 0 as InheritedAtt_IsIFA
	   , (Select top 1 [AllowsCoastalFishingForLayer2Data] from Arash.DW.DBO.EEZ e where e.EEZID = c.[ReconstructionEEZID]) as InheritedAtt_AllowsCoastalFishingForLayer2Data
  from EEZ_FAO_Combo c
  where [ReconstructionEEZID] in (select EEZID from @ActiveEEZs)


--------------------------------------------------------------------
--IFAs
--------------------------------------------------------------------
insert into @result
Select 14 As MarineLayerID
      ,[EEZID] As AreaID
      ,[IFA is located in this FAO] As FAOAreaID
      , 1 as IsActive
	  , EEZID as InheritedAtt_BelongsToReconstructionEEZID
	  , 1 as InheritedAtt_IsIFA
	  , 0 as [AllowsCoastalFishingForLayer2Data]
  FROM [Merlin].[dbo].[IFA]
where EEZID in (select EEZID from @ActiveEEZs)


--------------------------------------------------------------------
--High Seas
--------------------------------------------------------------------
insert into @result
Select 2 As MarineLayerID
      ,FAOAreaID As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , 0 as InheritedAtt_BelongsToReconstructionEEZID
	  , 0 as InheritedAtt_IsIFA
	  , 1 as [AllowsCoastalFishingForLayer2Data]
  FROM [Merlin].[dbo].[HighSea]

--------------------------------------------------------------------
--ICES (High Seas)
--------------------------------------------------------------------
insert into @result
Select 15 As MarineLayerID
      ,[EEZ_ICES_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , 0 as InheritedAtt_BelongsToReconstructionEEZID
	  , 0 as InheritedAtt_IsIFA
	  , 1 as [AllowsCoastalFishingForLayer2Data]
  FROM [dbo].[EEZ_ICES_Combo]
  where EEZID = 0

--------------------------------------------------------------------
--ICES (IFA)
--------------------------------------------------------------------
insert into @result
Select 15 As MarineLayerID
      ,[EEZ_ICES_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , EEZID as InheritedAtt_BelongsToReconstructionEEZID
	  , [IsIFA] as InheritedAtt_IsIFA
	  , 0 as [AllowsCoastalFishingForLayer2Data]
  FROM [dbo].[EEZ_ICES_Combo]
  where isIFA = 1 and EEZID in (select EEZID from @ActiveEEZs)


--------------------------------------------------------------------
--ICES (EEZ)
--------------------------------------------------------------------
insert into @result
Select 15 As MarineLayerID
      ,[EEZ_ICES_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , EEZID as InheritedAtt_BelongsToReconstructionEEZID
	  , [IsIFA] as InheritedAtt_IsIFA
	  , (Select top 1 [AllowsCoastalFishingForLayer2Data] from Arash.DW.DBO.EEZ e where e.EEZID = c.EEZID) as [AllowsCoastalFishingForLayer2Data]
  FROM [dbo].[EEZ_ICES_Combo] c
  where isIFA = 0 and EEZID > 0  and EEZID in (select EEZID from @ActiveEEZs)


--------------------------------------------------------------------
--BigCells (EEZs and HighSeas)
--------------------------------------------------------------------
insert into @result
Select 16 As MarineLayerID
      ,[EEZ_BigCell_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , EEZID as InheritedAtt_BelongsToReconstructionEEZID
	  , 0 as InheritedAtt_IsIFA
	  , 1 as [AllowsCoastalFishingForLayer2Data] -- redundant
  FROM [dbo].[EEZ_BigCell_Combo] c
  where  EEZID = 0  or EEZID in (select EEZID from @ActiveEEZs)

--------------------------------------------------------------------
--CCAMLR (High Seas)
--------------------------------------------------------------------
insert into @result
Select 17 As MarineLayerID
      ,[EEZ_CCAMLAR_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , 0 as InheritedAtt_BelongsToReconstructionEEZID
	  , 0 as InheritedAtt_IsIFA
	  , 1 as [AllowsCoastalFishingForLayer2Data]
  FROM [dbo].[EEZ_CCAMLR_Combo]
  where EEZID = 0

--------------------------------------------------------------------
--CCAMLR (EEZ)
--------------------------------------------------------------------
insert into @result
Select 17 As MarineLayerID
      ,[EEZ_CCAMLAR_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , EEZID as InheritedAtt_BelongsToReconstructionEEZID
	  , [IsIFA] as InheritedAtt_IsIFA
	  , (Select top 1 [AllowsCoastalFishingForLayer2Data] from Arash.DW.DBO.EEZ e where e.EEZID = c.EEZID) as [AllowsCoastalFishingForLayer2Data]
  FROM [dbo].[EEZ_CCAMLR_Combo] c
  where isIFA = 0 and EEZID > 0  and EEZID in (select EEZID from @ActiveEEZs)


--------------------------------------------------------------------
--CCAMLR (IFA)
--------------------------------------------------------------------
insert into @result
Select 17 As MarineLayerID
      ,[EEZ_CCAMLAR_ComboID] As AreaID
      ,FAOAreaID As FAOAreaID
      , 1 as IsActive
	  , EEZID as InheritedAtt_BelongsToReconstructionEEZID
	  , [IsIFA] as InheritedAtt_IsIFA
	  , 0 as [AllowsCoastalFishingForLayer2Data]
  FROM [dbo].[EEZ_CCAMLR_Combo]
  where isIFA = 1 and EEZID in (select EEZID from @ActiveEEZs)

	RETURN 
END



GO
/****** Object:  UserDefinedFunction [dbo].[Price_fill_blanks_layer1]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Price_fill_blanks_layer1]
(
	@fishingEntityID int,
	@year int,
	@taxonKey int
)
RETURNS float
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result float

set @result= (	select top 1 [price]
	from price_genesis
	where [FishingEntityID] = @fishingEntityID 
	and [Year] <= @year
	and [Taxonkey] = @taxonKey
	order by [year] desc)


if (@result is null)
set @result= (	select top 1 [price]
	from price_genesis
	where [FishingEntityID] = @fishingEntityID 
	and [Taxonkey] = @taxonKey
	and [year] > @year
	order by [YEAR] asc)


	RETURN @result

END

GO
/****** Object:  Table [dbo].[AccessAgreement]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessAgreement](
	[AccessAgreementID] [int] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[EEZIDs] [nvarchar](255) NOT NULL,
	[StartYear] [int] NOT NULL,
	[EndYear] [int] NOT NULL,
	[FunctionalGroupIDs] [nvarchar](255) NULL,
 CONSTRAINT [PK_AccessAgreement] PRIMARY KEY CLUSTERED 
(
	[AccessAgreementID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AccessAgreementEEZ]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessAgreementEEZ](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[AccessAgreementID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
 CONSTRAINT [PK_AccessAgreemenEEZ] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AgreementRaw]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgreementRaw](
	[ID] [float] NOT NULL,
	[FishingEntityID] [float] NULL,
	[EEZID] [nvarchar](255) NULL,
	[Title] [nvarchar](255) NULL,
	[OriginalAreaCode] [nvarchar](255) NULL,
	[FishingAccess] [nvarchar](255) NULL,
	[AccessType] [float] NULL,
	[AgreementType] [float] NULL,
	[StartYear] [float] NULL,
	[EndYear] [float] NULL,
	[FunctionalGroupID] [nvarchar](255) NULL,
 CONSTRAINT [PK_AgreementRaw_1] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AllocationAreaType]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllocationAreaType](
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Remarks] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Table_1] PRIMARY KEY CLUSTERED 
(
	[AllocationAreaTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AllocationBatch]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllocationBatch](
	[AllocationBatchName] [nvarchar](50) NOT NULL,
	[Desc] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_AllocationBatch] PRIMARY KEY CLUSTERED 
(
	[AllocationBatchName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AllocationHybridArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllocationHybridArea](
	[AllocationHybridAreaID] [int] IDENTITY(1,1) NOT NULL,
	[FaoAreaID] [tinyint] NOT NULL,
	[MarineLayerID1] [tinyint] NOT NULL,
	[AreaIDs1] [nvarchar](255) NOT NULL,
	[MarineLayerID2] [tinyint] NOT NULL,
	[AreaIDs2] [nvarchar](255) NOT NULL,
	[internalAudit_hasAgreementEEZs] [nvarchar](255) NOT NULL,
	[internalAudit_unDeclaredEEZs] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_AllocationHybridArea] PRIMARY KEY CLUSTERED 
(
	[AllocationHybridAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AllocationResult]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllocationResult](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[UniversalDataID] [int] NOT NULL,
	[AllocationSimpleAreaID] [int] NOT NULL,
	[CellID] [int] NOT NULL,
	[AllocatedCatch] [float] NOT NULL,
 CONSTRAINT [PK_AllocationResults] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AllocationSimpleArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllocationSimpleArea](
	[AllocationSimpleAreaID] [int] NOT NULL,
	[MarineLayerID] [tinyint] NOT NULL,
	[AreaID] [int] NOT NULL,
	[FaoAreaID] [tinyint] NOT NULL,
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_AllocationSimpleArea_IsActive_AutoGen]  DEFAULT ((1)),
	[InheritedAtt_BelongsToReconstructionEEZID] [int] NOT NULL CONSTRAINT [DF_AllocationAreaToken_BelongsTo_ReconstructionEEZID]  DEFAULT ((1)),
	[InheritedAtt_IsIFA] [bit] NOT NULL CONSTRAINT [DF_AllocationSimpleArea_InheritedAtt_IsIFA]  DEFAULT ((0)),
	[InheritedAtt_AllowsCoastalFishingForLayer2Data] [bit] NOT NULL CONSTRAINT [DF_AllocationSimpleArea_InheritedAtt_AllowsCoastalFishingForLayer2Data]  DEFAULT ((1)),
 CONSTRAINT [PK_AllocationAreaToken] PRIMARY KEY CLUSTERED 
(
	[AllocationSimpleAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AllocationYear]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllocationYear](
	[YearID] [tinyint] NOT NULL,
	[Name] [int] NOT NULL,
 CONSTRAINT [PK_AllocationYear] PRIMARY KEY CLUSTERED 
(
	[YearID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AutoGen_AllocationAllProcess_UniqueArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoGen_AllocationAllProcess_UniqueArea](
	[UniqueAreaID] [int] IDENTITY(1,1) NOT NULL,
	[DataLayerID] [tinyint] NOT NULL,
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[GenericAllocationAreaID] [int] NOT NULL,
 CONSTRAINT [PK_AutoGen_AllocationAllProcess_UniqueArea] PRIMARY KEY CLUSTERED 
(
	[UniqueAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AutoGen_AllocationAllProcess_UniqueAreaCell]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoGen_AllocationAllProcess_UniqueAreaCell](
	[UniqueAreaID] [int] NOT NULL,
	[AllocationSimpleAreaID] [int] NULL,
	[CellID] [int] NULL,
	[WaterArea] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Index [ClusteredIndex-20150605-135634]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-20150605-135634] ON [dbo].[AutoGen_AllocationAllProcess_UniqueAreaCell]
(
	[UniqueAreaID] ASC,
	[AllocationSimpleAreaID] ASC,
	[CellID] ASC,
	[WaterArea] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AutoGen_HybridToSimpleAreaMapper]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoGen_HybridToSimpleAreaMapper](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[HybridAreaID] [int] NOT NULL,
	[ContainsAllocationSimpleAreaID] [int] NOT NULL,
 CONSTRAINT [PK_AutoGen_HybridToSimpleAreaMapping] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BigCell]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BigCell](
	[BigCellID] [int] IDENTITY(1,1) NOT NULL,
	[BigCellTypeID] [int] NOT NULL,
	[x] [float] NOT NULL,
	[y] [float] NOT NULL,
	[IsLandlocked] [bit] NOT NULL CONSTRAINT [DF_BigCell_IsLandlocked]  DEFAULT ((0)),
	[IsInMed] [bit] NOT NULL CONSTRAINT [DF_BigCell_IsInMed]  DEFAULT ((0)),
	[IsInPacific] [bit] NOT NULL CONSTRAINT [DF_BigCell_IsInPacific]  DEFAULT ((0)),
	[IsInIndian] [bit] NOT NULL CONSTRAINT [DF_BigCell_IsInIndian]  DEFAULT ((0)),
 CONSTRAINT [PK_BigCell] PRIMARY KEY CLUSTERED 
(
	[BigCellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BigCellType]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BigCellType](
	[BigCellTypeID] [int] NOT NULL,
	[TypeDesc] [nvarchar](255) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CatchType]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CatchType](
	[CatchTypeID] [tinyint] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_CatchType] PRIMARY KEY CLUSTERED 
(
	[CatchTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Cell]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cell](
	[CellID] [int] NOT NULL,
	[TotalArea] [float] NOT NULL,
	[WaterArea] [float] NOT NULL,
 CONSTRAINT [PK_Cell] PRIMARY KEY CLUSTERED 
(
	[CellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CellIsCoastal]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CellIsCoastal](
	[CellID] [int] NOT NULL,
 CONSTRAINT [PK_CellIsCoastal] PRIMARY KEY CLUSTERED 
(
	[CellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CellToDataAreaMapping]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CellToDataAreaMapping](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[DataAreaID] [int] NULL,
	[CellID] [int] NULL,
	[WaterArea] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CellToEEZ]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CellToEEZ](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[Seq] [int] NULL,
	[CNumber] [int] NULL,
	[FAO name] [nvarchar](60) NULL,
	[A_CODE] [int] NULL,
	[Admin_Country] [nvarchar](60) NULL,
	[C_NUM] [int] NULL,
	[C_Name] [nvarchar](60) NULL,
	[A_NUM] [int] NULL,
	[A_Name] [nvarchar](60) NULL,
 CONSTRAINT [PK_CellToEEZ] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Data]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Data](
	[UniversalDataID] [int] NOT NULL,
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[GenericAllocationAreaID] [int] NOT NULL,
	[DataLayerID] [tinyint] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[CatchAmount] [float] NOT NULL,
	[SectorTypeID] [tinyint] NOT NULL,
	[CatchTypeID] [tinyint] NOT NULL,
	[InputTypeID] [tinyint] NOT NULL,
	[UniqueAreaID_AutoGen] [int] NULL,
	[OriginalFishingEntityID] [int] NOT NULL CONSTRAINT [DF_Data__originalFishingEntityID]  DEFAULT ((0)),
 CONSTRAINT [PK_DataImported] PRIMARY KEY CLUSTERED 
(
	[UniversalDataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Data_B4_MMF]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Data_B4_MMF](
	[UniversalDataID] [int] NOT NULL,
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[GenericAllocationAreaID] [int] NOT NULL,
	[DataLayerID] [tinyint] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[CatchAmount] [float] NOT NULL,
	[SectorTypeID] [tinyint] NOT NULL,
	[CatchTypeID] [tinyint] NOT NULL,
	[InputTypeID] [tinyint] NOT NULL,
	[UniqueAreaID_AutoGen] [int] NULL,
	[OriginalFishingEntityID] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Data_verified_layer3_all]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Data_verified_layer3_all](
	[UniversalDataID] [int] NOT NULL,
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[GenericAllocationAreaID] [int] NOT NULL,
	[DataLayerID] [tinyint] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[CatchAmount] [float] NOT NULL,
	[SectorTypeID] [tinyint] NOT NULL,
	[CatchTypeID] [tinyint] NOT NULL,
	[InputTypeID] [tinyint] NOT NULL,
	[UniqueAreaID_AutoGen] [int] NULL,
	[OriginalFishingEntityID] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DataRaw]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataRaw](
	[UniversalDataID] [int] IDENTITY(1,1) NOT NULL,
	[ExternalDataRowID] [int] NOT NULL,
	[DataLayerID] [int] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
	[FAOArea] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[CatchAmount] [float] NOT NULL,
	[Sector] [nvarchar](50) NOT NULL,
	[CatchTypeID] [int] NOT NULL,
	[Input] [nvarchar](50) NOT NULL,
	[ICES_AreaID] [nvarchar](50) NULL,
	[BigCellID] [int] NULL,
	[CCAMLRArea] [nvarchar](50) NULL,
	[NAFODivision] [nvarchar](50) NULL,
 CONSTRAINT [PK_DataRaw] PRIMARY KEY CLUSTERED 
(
	[ExternalDataRowID] ASC,
	[FishingEntityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DataRaw_Layer3]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataRaw_Layer3](
	[RowID] [int] NOT NULL,
	[RFMOID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[Layer3GearID] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[BigCellID] [int] NOT NULL,
	[Catch] [float] NOT NULL,
	[CatchTypeID] [tinyint] NOT NULL,
 CONSTRAINT [PK_DataRaw_Layer3] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DataRaw_Layer3_base_all]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataRaw_Layer3_base_all](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[RFMOID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[FishingEntityID] [int] NULL,
	[Layer3GearID] [int] NULL,
	[TaxonKey] [int] NULL,
	[BigCellID] [int] NULL,
	[Catch] [float] NULL,
	[CatchTypeID] [tinyint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DataRaw_Layer3_discards_only]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataRaw_Layer3_discards_only](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[RFMOID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[FishingEntityID] [int] NULL,
	[Layer3GearID] [int] NULL,
	[TaxonKey] [int] NULL,
	[BigCellID] [int] NULL,
	[Catch] [float] NULL,
	[CatchTypeID] [tinyint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EEZ_BigCell_Combo]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EEZ_BigCell_Combo](
	[EEZ_BigCell_ComboID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
	[FAOAreaID] [int] NOT NULL,
	[BigCellID] [int] NOT NULL,
	[IsIFA] [bit] NOT NULL,
 CONSTRAINT [PK_EEZ_BigCell_Combo] PRIMARY KEY CLUSTERED 
(
	[EEZ_BigCell_ComboID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EEZ_CCAMLR_Combo]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EEZ_CCAMLR_Combo](
	[EEZ_CCAMLAR_ComboID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
	[FAOAreaID] [tinyint] NOT NULL,
	[CCAMLR_AreaID] [nvarchar](50) NOT NULL,
	[IsIFA] [bit] NOT NULL,
 CONSTRAINT [PK_EEZ_CCAMLR_Combo] PRIMARY KEY CLUSTERED 
(
	[EEZ_CCAMLAR_ComboID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EEZ_FAO_Combo]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EEZ_FAO_Combo](
	[EEZFAOAreaID] [int] IDENTITY(1,1) NOT NULL,
	[ReconstructionEEZID] [int] NOT NULL,
	[FAOAreaID] [int] NOT NULL,
 CONSTRAINT [PK_EEZFAOArea] PRIMARY KEY CLUSTERED 
(
	[EEZFAOAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EEZ_ICES_Combo]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EEZ_ICES_Combo](
	[EEZ_ICES_ComboID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
	[FAOAreaID] [tinyint] NOT NULL,
	[ICES_AreaID] [nvarchar](50) NOT NULL,
	[IsIFA] [bit] NOT NULL CONSTRAINT [DF_EEZ_ICES_Combo_IsIFA]  DEFAULT ((0)),
 CONSTRAINT [PK_FAOSpecificArea] PRIMARY KEY CLUSTERED 
(
	[EEZ_ICES_ComboID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EEZ_NAFO_Combo]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EEZ_NAFO_Combo](
	[EEZ_NAFO_ComboID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
	[FAOAreaID] [tinyint] NOT NULL,
	[NAFODivision] [nvarchar](50) NOT NULL,
	[IsIFA] [bit] NOT NULL,
 CONSTRAINT [PK_EEZ_NAFO_Combo] PRIMARY KEY CLUSTERED 
(
	[EEZ_NAFO_ComboID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EEZAMinusEEZBArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EEZAMinusEEZBArea](
	[EEZAMinusEEZBAreaID] [int] NOT NULL,
	[EEZAID] [int] NOT NULL,
	[EEZBID] [int] NOT NULL,
	[FAOAreaID] [int] NOT NULL,
 CONSTRAINT [PK_EEZAMinusEEZBArea] PRIMARY KEY CLUSTERED 
(
	[EEZAMinusEEZBAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FAOCell]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FAOCell](
	[FAOAreaID] [tinyint] NOT NULL,
	[CellID] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FAOMap]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FAOMap](
	[FAOAreaID] [tinyint] NOT NULL,
	[UpperLeftCell_CellID] [int] NOT NULL,
	[Scale] [tinyint] NOT NULL CONSTRAINT [DF_FAOMap_scale]  DEFAULT ((10)),
 CONSTRAINT [PK_FAOMap] PRIMARY KEY CLUSTERED 
(
	[FAOAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FriendlyTaxonCoverageReport]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FriendlyTaxonCoverageReport](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[Version] [int] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[FishingEntityName] [nvarchar](255) NOT NULL,
	[DataLayerID] [tinyint] NOT NULL,
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[GenericAllocationAreaID] [int] NOT NULL,
	[DataRowCount] [int] NOT NULL,
	[TotalCatch] [float] NOT NULL,
	[AreaTypeName] [nvarchar](50) NOT NULL,
	[AreaID] [nvarchar](max) NOT NULL,
	[AreaName] [nvarchar](255) NULL,
	[FaoAreaID] [int] NOT NULL,
	[FaoAreaName] [nvarchar](50) NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[TaxonCommonName] [nvarchar](50) NOT NULL,
	[TaxonSciName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_FriendlyTaxonCoverageReport] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[HighSea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HighSea](
	[FAOAreaID] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[hs]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[hs](
	[OBJECTID] [float] NULL,
	[Division] [nvarchar](255) NULL,
	[Subdiv] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[HybridArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HybridArea](
	[HybridAreaID] [int] IDENTITY(1,1) NOT NULL,
	[FAOID] [int] NOT NULL,
	[EEZs] [nvarchar](255) NOT NULL,
	[DuplicateEEZs] [nvarchar](255) NULL,
	[PureEEZsSorted] [nvarchar](255) NOT NULL,
	[EEZAMinusEEZBAreaIDsSorted] [nvarchar](255) NULL,
 CONSTRAINT [PK_HybridArea] PRIMARY KEY CLUSTERED 
(
	[HybridAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ICES_Area]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ICES_Area](
	[ICESdivision] [nvarchar](255) NULL,
	[ICESSubdivision] [nvarchar](255) NULL,
	[ICES_AreaID] [nvarchar](255) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[IFA]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IFA](
	[EEZID] [float] NULL,
	[IFA is located in this FAO] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InputType]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InputType](
	[InputTypeID] [tinyint] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_InputType] PRIMARY KEY CLUSTERED 
(
	[InputTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Layer]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Layer](
	[LayerID] [tinyint] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Layer] PRIMARY KEY CLUSTERED 
(
	[LayerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Log_Import_Raw]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Log_Import_Raw](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [nvarchar](50) NOT NULL,
	[DataRowID] [int] NOT NULL,
	[OriginalRowID] [int] NOT NULL,
	[LogTime] [datetime] NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_Log_DataRaw_Import] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Log_InternalProcesses]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Log_InternalProcesses](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[ErrorSourceName] [nvarchar](50) NOT NULL,
	[DataRowID] [int] NOT NULL,
	[LogTime] [datetime] NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_Log_InternalProcesses] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Price]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Price](
	[Year] [int] NULL,
	[FishingEntityID] [int] NULL,
	[Taxonkey] [int] NULL,
	[Price] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SectorType]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SectorType](
	[SectorTypeID] [tinyint] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SectorType] PRIMARY KEY CLUSTERED 
(
	[SectorTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SimpleAreaCellAssignment]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SimpleAreaCellAssignment](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[AllocationSimpleAreaID] [int] NOT NULL,
	[CellID] [int] NOT NULL,
	[WaterArea] [float] NOT NULL,
 CONSTRAINT [PK_AreaCell] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SimpleAreaCellAssignmentRaw]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SimpleAreaCellAssignmentRaw](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MarineLayerID] [smallint] NULL,
	[AreaID] [int] NULL,
	[FAOAreaID] [smallint] NULL,
	[CellID] [float] NULL,
	[WaterArea] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TaxonDistribution]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxonDistribution](
	[TaxonKey] [int] NOT NULL,
	[CellID] [int] NOT NULL,
	[RelativeAbundance] [int] NOT NULL,
	[TaxonDistributionID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK__TaxonDis__84EE6D1002C769E9] PRIMARY KEY CLUSTERED 
(
	[TaxonDistributionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TaxonDistributionIsVerified]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxonDistributionIsVerified](
	[TaxonKey] [int] NOT NULL,
	[DateTaggedAsVerified] [datetime] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TaxonDistributionSubstitute]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxonDistributionSubstitute](
	[OriginalTaxonKey] [int] NOT NULL,
	[UseThisTaxonKeyInstead] [int] NOT NULL,
 CONSTRAINT [PK_TaxonDistributionSubstitute] PRIMARY KEY CLUSTERED 
(
	[OriginalTaxonKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[vwAllocationSimpleArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwAllocationSimpleArea]
AS
SELECT AllocationSimpleAreaID, MarineLayerID, AreaID, FaoAreaID, InheritedAtt_BelongsToReconstructionEEZID, InheritedAtt_IsIFA, 
                 InheritedAtt_AllowsCoastalFishingForLayer2Data
FROM    dbo.AllocationSimpleArea
WHERE (IsActive = 1)

GO
/****** Object:  View [dbo].[vwCoastalEEZFAOCombo]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwCoastalEEZFAOCombo]
AS
SELECT        AreaID AS EEZID, FaoAreaID
FROM            dbo.vwAllocationSimpleArea
WHERE        (MarineLayerID = 12) AND (AllocationSimpleAreaID NOT IN
                             (SELECT        AllocationSimpleAreaID
                               FROM            dbo.SimpleAreaCellAssignment
                               WHERE        (CellID NOT IN
                                                             (SELECT        CellID
                                                               FROM            dbo.CellIsCoastal)) AND (AllocationSimpleAreaID IN
                                                             (SELECT        AllocationSimpleAreaID
                                                               FROM            dbo.vwAllocationSimpleArea AS vwAllocationSimpleArea_1
                                                               WHERE        (MarineLayerID = 12)))
                               GROUP BY AllocationSimpleAreaID
                               HAVING         (COUNT(*) > 0)))

GO
/****** Object:  View [dbo].[vwForWeb_FriendlyTaxonCoverageReport_NIU]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwForWeb_FriendlyTaxonCoverageReport_NIU]
AS
SELECT TOP (100) PERCENT RowID, DataRowCount, ROUND(TotalCatch, 0) AS TotalCatch, AreaTypeName, AreaName, FaoAreaName, TaxonCommonName, 
                 TaxonSciName, FishingEntityID
FROM    dbo.FriendlyTaxonCoverageReport
ORDER BY TotalCatch DESC

GO
/****** Object:  View [dbo].[vwTaxonCoverageReport]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwTaxonCoverageReport]
AS
SELECT DISTINCT 
                 TOP (100) PERCENT FishingEntityID, DataLayerID, AllocationAreaTypeID, GenericAllocationAreaID, TaxonKey, COUNT(*) AS DataRowCount, SUM(CatchAmount) 
                 AS TotalCatch
FROM    dbo.Data
WHERE (UniversalDataID NOT IN
                     (SELECT DISTINCT UniversalDataID
                      FROM     dbo.AllocationResult)) AND (UniversalDataID NOT IN
                     (SELECT DISTINCT dbo.Data.UniversalDataID
                      FROM     dbo.Log_Import_Raw)) AND (FishingEntityID IN
                     (SELECT DISTINCT d.FishingEntityID
                      FROM     dbo.Data AS d INNER JOIN
                                       dbo.AllocationResult AS r ON r.UniversalDataID = d.UniversalDataID)) AND (UniversalDataID NOT IN
                     (SELECT DISTINCT dbo.Data.UniversalDataID
                      FROM     dbo.Log_InternalProcesses))
GROUP BY FishingEntityID, DataLayerID, AllocationAreaTypeID, GenericAllocationAreaID, TaxonKey
ORDER BY FishingEntityID

GO
/****** Object:  View [dbo].[vwTaxonCoverageReport_v1]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwTaxonCoverageReport_v1]
AS
SELECT DISTINCT AllocationAreaTypeID, GenericAllocationAreaID, TaxonKey, COUNT(*) AS DataRowCount, SUM(CatchAmount) AS TotalCatch
FROM    dbo.Data
WHERE (DataRawID IN
                     (SELECT DataRawID
                      FROM     dbo.Log_Import_Raw))
GROUP BY AllocationAreaTypeID, GenericAllocationAreaID, TaxonKey

GO
/****** Object:  Index [_dta_index_AccessAgreementEEZ_5_50099219__K3]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE NONCLUSTERED INDEX [_dta_index_AccessAgreementEEZ_5_50099219__K3] ON [dbo].[AccessAgreementEEZ]
(
	[EEZID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [unique_Combo]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [unique_Combo] ON [dbo].[AccessAgreementEEZ]
(
	[EEZID] ASC,
	[AccessAgreementID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [nc_unique]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [nc_unique] ON [dbo].[AllocationResult]
(
	[UniversalDataID] ASC,
	[AllocationSimpleAreaID] ASC,
	[CellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [_dta_index_AllocationSimpleArea_5_1934629935__K5_1_2_3_4_6_7_8]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE NONCLUSTERED INDEX [_dta_index_AllocationSimpleArea_5_1934629935__K5_1_2_3_4_6_7_8] ON [dbo].[AllocationSimpleArea]
(
	[IsActive] ASC
)
INCLUDE ( 	[AllocationSimpleAreaID],
	[MarineLayerID],
	[AreaID],
	[FaoAreaID],
	[InheritedAtt_BelongsToReconstructionEEZID],
	[InheritedAtt_IsIFA],
	[InheritedAtt_AllowsCoastalFishingForLayer2Data]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [_dta_index_AllocationSimpleArea_5_1934629935__K5_K3]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE NONCLUSTERED INDEX [_dta_index_AllocationSimpleArea_5_1934629935__K5_K3] ON [dbo].[AllocationSimpleArea]
(
	[IsActive] ASC,
	[AreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NC_unique]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NC_unique] ON [dbo].[AllocationSimpleArea]
(
	[MarineLayerID] ASC,
	[AreaID] ASC,
	[FaoAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20150605-134638]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20150605-134638] ON [dbo].[AutoGen_AllocationAllProcess_UniqueArea]
(
	[DataLayerID] ASC,
	[AllocationAreaTypeID] ASC,
	[GenericAllocationAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NC_Performance]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE NONCLUSTERED INDEX [NC_Performance] ON [dbo].[AutoGen_HybridToSimpleAreaMapper]
(
	[HybridAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20150605-111730]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20150605-111730] ON [dbo].[Data]
(
	[OriginalFishingEntityID] ASC,
	[AllocationAreaTypeID] ASC,
	[GenericAllocationAreaID] ASC,
	[DataLayerID] ASC,
	[UniqueAreaID_AutoGen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NC_UniversalDataID]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NC_UniversalDataID] ON [dbo].[DataRaw]
(
	[UniversalDataID] ASC
)
INCLUDE ( 	[FishingEntityID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20150226-154457]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20150226-154457] ON [dbo].[EEZ_FAO_Combo]
(
	[ReconstructionEEZID] ASC,
	[FAOAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [nc_unique]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [nc_unique] ON [dbo].[FriendlyTaxonCoverageReport]
(
	[FishingEntityName] ASC,
	[AllocationAreaTypeID] ASC,
	[GenericAllocationAreaID] ASC,
	[TaxonKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NC_unique]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NC_unique] ON [dbo].[SimpleAreaCellAssignment]
(
	[AllocationSimpleAreaID] ASC,
	[CellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [nc_unique]    Script Date: 6/18/2015 10:15:29 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [nc_unique] ON [dbo].[TaxonDistribution]
(
	[TaxonKey] ASC,
	[CellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_AllocationAreaType] FOREIGN KEY([AllocationAreaTypeID])
REFERENCES [dbo].[AllocationAreaType] ([AllocationAreaTypeID])
GO
ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_AllocationAreaType]
GO
ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_CatchType] FOREIGN KEY([CatchTypeID])
REFERENCES [dbo].[CatchType] ([CatchTypeID])
GO
ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_CatchType]
GO
ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_InputType] FOREIGN KEY([InputTypeID])
REFERENCES [dbo].[InputType] ([InputTypeID])
GO
ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_InputType]
GO
ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_Layer] FOREIGN KEY([DataLayerID])
REFERENCES [dbo].[Layer] ([LayerID])
GO
ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_Layer]
GO
ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_SectorType] FOREIGN KEY([SectorTypeID])
REFERENCES [dbo].[SectorType] ([SectorTypeID])
GO
ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_SectorType]
GO
/****** Object:  StoredProcedure [dbo].[ActualAllocationProcess]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ActualAllocationProcess]
	@this_FishingEntityID int
AS
BEGIN


--refactor: when the Layer=1 has the depth adjustment function, it needs its own procedure, as then, the 'bundles' of the cells are into the play, which essetially have a percentage attached to them, for example Bundle1 is for 7% or less of the peak catch, PER TAXON
DECLARE @UniqueArea TABLE (UniqueAreaID int IDENTITY(1,1) Primary KEy, DataLayerID tinyint, AllocationAreaTypeID tinyint, GenericAllocationAreaID int)

insert into @UniqueArea
SELECT distinct 
       DataLayerID, AllocationAreaTypeID, GenericAllocationAreaID

  FROM [Merlin].[dbo].[Data]
  where [OriginalFishingEntityID] = @this_FishingEntityID

-- now propagate back these UniqAreaIDs to dbo.data
update dbo.Data
set UniqueAreaID_AutoGen = UniqueAreaID
from dbo.data d inner join @UniqueArea a on
d.DataLayerID = a.DataLayerID AND d.AllocationAreaTypeID = a.AllocationAreaTypeID AND d.GenericAllocationAreaID = a.GenericAllocationAreaID
where  d. [OriginalFishingEntityID] = @this_FishingEntityID
  
 -- now build the giant cell table for each unique area:
DECLARE @cells TABLE(UniqueAreaID int,
					 AllocationSimpleAreaID int
					  ,CellID int
				  ,WaterArea float)
insert into @cells
SELECT  UniqueAreaID, AllocationSimpleAreaID , CellID, WaterArea
from @UniqueArea
cross apply merlin.dbo.GetCellsForGenericArea(0, AllocationAreaTypeID, GenericAllocationAreaID, DataLayerID) 
 

----------------------------------------
DECLARE @results TABLE( UniversalDataID int,
						UniqueAreaID int,
						AllocationSimpleAreaID int
						,CellID int
						,WaterArea_X_RelativeAbundance float
						, TotalCatch float
						,AllocatedCatch float
						, TaxonKey int)
	


-----------------------------------------------------------------------------------
insert into @results
select d.UniversalDataID, 
		d.UniqueAreaID_AutoGen as UniqueAreaID, 
		c.AllocationSimpleAreaID, 
		c.CellID, 
		c.WaterArea * t.RelativeAbundance As WaterArea_X_RelativeAbundance, 
		d.CatchAmount as TotalCatch, 
		0 as AllocatedCatch, 
		d.TaxonKey as TaxonKey
from (dbo.Data d inner join @cells c
--on d.UniqueAreaID_AutoGen = c.UniqueAreaID)  inner join TaxonDistribution t on d.TaxonKey = t.TaxonKey AND c.CellID = t.CellID
on d.UniqueAreaID_AutoGen = c.UniqueAreaID)  inner join TaxonDistribution t on c.CellID = t.CellID
where  t.TaxonKey =d.TaxonKey 
		AND d.[OriginalFishingEntityID] = @this_FishingEntityID
		--AND d.UniversalDataID in (6051, 6050, 22634)


------------------------------------------------------------------------------------
---Create SumRelativeAbundance look up
DECLARE @SumRelativeAbundance TABLE (UniversalDataID int , SumRelativeAbundance float, PRIMARY KEY (UniversalDataID))
insert into @SumRelativeAbundance
select UniversalDataID, SUM(WaterArea_X_RelativeAbundance) as SumRelativeAbundance
from @results
group by UniversalDataID

--Calculate the allocated catch--------------------------------------------------------------------------------------

update @results
set AllocatedCatch = TotalCatch * WaterArea_X_RelativeAbundance / s.SumRelativeAbundance
from @results r inner join @SumRelativeAbundance s
     on r.UniversalDataID = s.UniversalDataID 
     where s.SumRelativeAbundance > 0



----test--------------------------------------------------
--select *
--from @results

--select *
--from @SumRelativeAbundance

----Output
insert into AllocationResult
select [UniversalDataID]
      ,[AllocationSimpleAreaID]
      ,[CellID]
      ,[AllocatedCatch] 
      from @results

END

GO
/****** Object:  StoredProcedure [dbo].[AllocationResults_Cleanup]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AllocationResults_Cleanup]
	@this_FishingEntityID int
AS
BEGIN

   --remove the index
 --   IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AllocationResult]') AND name = N'nc_unique')
	--DROP INDEX [nc_unique] ON [dbo].[AllocationResult] WITH ( ONLINE = OFF )
	
	-- first delete any stale results
	--refactor -> move this to a process that runs once at the begining, it is time consuming to run each time 
	--DELETE from AllocationResult
	--where UniversalDataID not in (select UniversalDataID from dbo.Data)
	
	DELETE from AllocationResult
	--where UniversalDataID in (select UniversalDataID from dbo.Data where FishingEntityID = @this_FishingEntityID
	--// this change from [Data] to [DataRaw] happened because of the fishingEntityID = 213 transformation which happens in the ETL process from [DataRaw] -> [Data], which means the really unique identifier is the UniversalDataID, as FE_ID = 213 would be present for different FEs, at least in layer 3
	where UniversalDataID in (select UniversalDataID from dbo.DataRaw where FishingEntityID = @this_FishingEntityID)
	
	DELETE from dbo.Log_InternalProcesses
	where DataRowID in (select UniversalDataID from dbo.DataRaw where FishingEntityID = @this_FishingEntityID) 
		
	DBCC SHRINKFILE (Merlin_Log, 1);

END

GO
/****** Object:  StoredProcedure [dbo].[AllocationResults_ReIndex]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AllocationResults_ReIndex]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  

/****** Object:  Index [nc_unique]    Script Date: 09/09/2013 13:30:38 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AllocationResult]') AND name = N'nc_unique')
DROP INDEX [nc_unique] ON [dbo].[AllocationResult] WITH ( ONLINE = OFF )



/****** Object:  Index [nc_unique]    Script Date: 09/09/2013 13:30:39 ******/
CREATE UNIQUE NONCLUSTERED INDEX [nc_unique] ON [dbo].[AllocationResult] 
(
	[UniversalDataID] ASC,
	[AllocationSimpleAreaID] ASC,
	[CellID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]




END

GO
/****** Object:  StoredProcedure [dbo].[GetDistinctCellsForGenericArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetDistinctCellsForGenericArea] 

	@AllocationAreaTypeID tinyint,
	@GenericAreaID int,
	@DataLayerID tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 select distinct CellID
 from dbo.GetCellsForGenericArea(0, 
 @AllocationAreaTypeID,  
 @GenericAreaID,
	@DataLayerID)


END

GO
/****** Object:  StoredProcedure [dbo].[GetLayer2GraphData]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetLayer2GraphData]
	@FishingEntityID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT [AllocationSimpleAreaID], d.Year
      
      ,sum([AllocatedCatch]) As TotalCatch
  FROM [Merlin].[dbo].[AllocationResult] r inner join dbo.Data d on d.UniversalDataID = r.UniversalDataID
  where d.FishingEntityID = @FishingEntityID and d.DataLayerID = 2
  group by AllocationSimpleAreaID, d.Year
  order by AllocationSimpleAreaID, d.Year asc
END

GO
/****** Object:  StoredProcedure [dbo].[Log_CreateEntry_InternalProcess]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Log_CreateEntry_InternalProcess]
	@ErrorSourceName nvarchar(50),
	@DataRowID int,
	@Message nvarchar(255)
AS
BEGIN

INSERT INTO [Merlin].[dbo].[Log_InternalProcesses]
       
           ([ErrorSourceName]
           ,[DataRowID]
           ,[LogTime]
           ,[Message])
     VALUES
           (@ErrorSourceName
           ,@DataRowID
           ,getdate()
           ,@Message)
END


GO
/****** Object:  StoredProcedure [dbo].[Log_CreateEntry_NeedsANewName]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Log_CreateEntry_NeedsANewName]
	@TableName nvarchar(50),
	@DataRowID int,
	@Message nvarchar(255)
AS
BEGIN
INSERT INTO [Merlin].[dbo].[Log_Import_Raw]
       
           ([TableName]
           ,[DataRowID]
           ,[LogTime]
           ,[Message])
     VALUES
           (@TableName
           ,@DataRowID
           ,getdate()
           ,@Message)
END

GO
/****** Object:  StoredProcedure [dbo].[maintenance_Delete_TableData]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[maintenance_Delete_TableData]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
DELETE FROM [dbo].[Data]

DBCC SHRINKFILE (Merlin_Log, 1);
END

GO
/****** Object:  StoredProcedure [dbo].[maintenance_Delete_TableImportLog]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[maintenance_Delete_TableImportLog]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
DELETE FROM [dbo].[Log_Import_Raw]

DBCC SHRINKFILE (Merlin_Log, 1);
END

GO
/****** Object:  StoredProcedure [dbo].[maintenance_DropCreate_TableAllocationResults]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[maintenance_DropCreate_TableAllocationResults]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


/****** Object:  Table [dbo].[AllocationResult]    Script Date: 12/02/2015 1:26:52 PM ******/
DROP TABLE [dbo].[AllocationResult]


/****** Object:  Table [dbo].[AllocationResult]    Script Date: 12/02/2015 1:26:52 PM ******/
SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON


CREATE TABLE [dbo].[AllocationResult](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[UniversalDataID] [int] NOT NULL,
	[AllocationSimpleAreaID] [int] NOT NULL,
	[CellID] [int] NOT NULL,
	[AllocatedCatch] [float] NOT NULL,
 CONSTRAINT [PK_AllocationResults] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



--ALTER TABLE [dbo].[AllocationResult]  WITH CHECK ADD  CONSTRAINT [FK_AllocationResult_Cell] FOREIGN KEY([CellID])
--REFERENCES [dbo].[Cell] ([CellID])


--ALTER TABLE [dbo].[AllocationResult] CHECK CONSTRAINT [FK_AllocationResult_Cell]


--ALTER TABLE [dbo].[AllocationResult]  WITH CHECK ADD  CONSTRAINT [FK_AllocationResult_Data] FOREIGN KEY([UniversalDataID])
--REFERENCES [dbo].[Data] ([UniversalDataID])


--ALTER TABLE [dbo].[AllocationResult] CHECK CONSTRAINT [FK_AllocationResult_Data]




/****** Object:  Index [nc_unique]    Script Date: 12/02/2015 1:27:50 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [nc_unique] ON [dbo].[AllocationResult]
(
	[UniversalDataID] ASC,
	[AllocationSimpleAreaID] ASC,
	[CellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)


DBCC SHRINKFILE (Merlin_Log, 1);
END

GO
/****** Object:  StoredProcedure [dbo].[maintenance_DropCreate_TableData]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[maintenance_DropCreate_TableData]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Data', @level2type=N'COLUMN',@level2name=N'UniqueAreaID_AutoGen'


ALTER TABLE [dbo].[Data] DROP CONSTRAINT [FK_Data_SectorType]
 

ALTER TABLE [dbo].[Data] DROP CONSTRAINT [FK_Data_Layer]
 

ALTER TABLE [dbo].[Data] DROP CONSTRAINT [FK_Data_InputType]
 

ALTER TABLE [dbo].[Data] DROP CONSTRAINT [FK_Data_CatchType]
 

ALTER TABLE [dbo].[Data] DROP CONSTRAINT [FK_Data_AllocationAreaType]
 

/****** Object:  Table [dbo].[Data]    Script Date: 01/04/2015 10:04:48 AM ******/
DROP TABLE [dbo].[Data]
 

/****** Object:  Table [dbo].[Data]    Script Date: 01/04/2015 10:04:48 AM ******/
SET ANSI_NULLS ON
 

SET QUOTED_IDENTIFIER ON
 

CREATE TABLE [dbo].[Data](
	[UniversalDataID] [int] NOT NULL,
	[AllocationAreaTypeID] [tinyint] NOT NULL,
	[GenericAllocationAreaID] [int] NOT NULL,
	[DataLayerID] [tinyint] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[CatchAmount] [float] NOT NULL,
	[SectorTypeID] [tinyint] NOT NULL,
	[CatchTypeID] [tinyint] NOT NULL,
	[InputTypeID] [tinyint] NOT NULL,
	[UniqueAreaID_AutoGen] [int] NULL,
	[OriginalFishingEntityID] [int] NOT NULL CONSTRAINT [DF_Data__originalFishingEntityID]  DEFAULT ((0)),
 CONSTRAINT [PK_DataImported] PRIMARY KEY CLUSTERED 
(
	[UniversalDataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

 

ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_AllocationAreaType] FOREIGN KEY([AllocationAreaTypeID])
REFERENCES [dbo].[AllocationAreaType] ([AllocationAreaTypeID])
 

ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_AllocationAreaType]
 

ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_CatchType] FOREIGN KEY([CatchTypeID])
REFERENCES [dbo].[CatchType] ([CatchTypeID])
 

ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_CatchType]
 

ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_InputType] FOREIGN KEY([InputTypeID])
REFERENCES [dbo].[InputType] ([InputTypeID])
 

ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_InputType]
 

ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_Layer] FOREIGN KEY([DataLayerID])
REFERENCES [dbo].[Layer] ([LayerID])
 

ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_Layer]
 

ALTER TABLE [dbo].[Data]  WITH NOCHECK ADD  CONSTRAINT [FK_Data_SectorType] FOREIGN KEY([SectorTypeID])
REFERENCES [dbo].[SectorType] ([SectorTypeID])
 

ALTER TABLE [dbo].[Data] CHECK CONSTRAINT [FK_Data_SectorType]
 

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'this is AutoGen.  ing to be used to the internal processes on SQL server' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Data', @level2type=N'COLUMN',@level2name=N'UniqueAreaID_AutoGen'


DBCC SHRINKFILE (Merlin_Log, 1);
END
GO
/****** Object:  StoredProcedure [dbo].[maintenance_DropCreate_TableDataRaw]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[maintenance_DropCreate_TableDataRaw]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DROP TABLE [dbo].[DataRaw]

CREATE TABLE [dbo].[DataRaw](
	[UniversalDataID] [int] IDENTITY(1,1) NOT NULL,
	[ExternalDataRowID] [int] NOT NULL,
	[DataLayerID] [int] NOT NULL,
	[FishingEntityID] [int] NOT NULL,
	[EEZID] [int] NOT NULL,
	[FAOArea] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[TaxonKey] [int] NOT NULL,
	[CatchAmount] [float] NOT NULL,
	[Sector] [nvarchar](50) NOT NULL,
	[CatchTypeID] [int] NOT NULL,
	[Input] [nvarchar](50) NOT NULL,
	[ICES_AreaID] [nvarchar](50) NULL,
	[BigCellID] [int] NULL,
	[CCAMLRArea] [nvarchar](50) NULL,
	[NAFODivision] [nvarchar](50) NULL,
 CONSTRAINT [PK_DataRaw] PRIMARY KEY CLUSTERED 
(
	[ExternalDataRowID] ASC,
	[FishingEntityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


/****** Object:  Index [NC_UniversalDataID]    Script Date: 10/04/2015 8:55:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NC_UniversalDataID] ON [dbo].[DataRaw]
(
	[UniversalDataID] ASC
)
INCLUDE ( 	[FishingEntityID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

DBCC SHRINKFILE (Merlin_Log, 1);

SET ANSI_NULLS ON

END
GO
/****** Object:  StoredProcedure [dbo].[maintenance_Regen_TableAllocationSimpleArea_Reset_hybrids]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[maintenance_Regen_TableAllocationSimpleArea_Reset_hybrids]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

EXEC [dbo].[maintenance_DropCreate_TableAllocationResults]  
EXEC [dbo].[maintenance_Delete_TableImportLog]
EXEC [dbo].[maintenance_Delete_TableData] 


 DELETE FROM AllocationSimpleArea
 Insert into AllocationSimpleArea SELECT * FROM [dbo].[internal_generate_AllocationSimpleAreaTable] () 

 DELETE FROM AllocationHybridArea
 DBCC CHECKIDENT('AllocationHybridArea', RESEED, 1);

 DELETE FROM AutoGen_HybridToSimpleAreaMapper
 DBCC CHECKIDENT('AutoGen_HybridToSimpleAreaMapper', RESEED, 1);

 delete FROM [dbo].[SimpleAreaCellAssignment]
 DBCC CHECKIDENT('SimpleAreaCellAssignment', RESEED, 1);
 
 DBCC SHRINKFILE (Merlin_Log, 1);
END

GO
/****** Object:  StoredProcedure [dbo].[sql_Populate_AutoGen_HybridCellMapperTable_NIU]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sql_Populate_AutoGen_HybridCellMapperTable_NIU]
	
AS
BEGIN
	
	SET NOCOUNT ON;
insert into AutoGen_HybridAreaCellMapper
SELECT a.HybridAreaID, c.AllocationSimpleAreaID, c.CellID, c.WaterArea
  FROM [Merlin].[dbo].[AutoGen_HybridToSimpleAreaMapper] a 
  inner join dbo.SimpleAreaCellMapper c on
  a.ContainsAllocationSimpleAreaID = c.AllocationSimpleAreaID
  where  a.HybridAreaID not in (select distinct HybridAreaID from dbo.AutoGen_HybridAreaCellMapper)
order by HybridAreaID asc
END

GO
/****** Object:  StoredProcedure [dbo].[WhichTaxonDistributionDoesNotCoverDataArea]    Script Date: 6/18/2015 10:15:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[WhichTaxonDistributionDoesNotCoverDataArea] 
	@DataAreaID int
AS
BEGIN

	SET NOCOUNT ON;
select distinct taxonkey
from data_layer1 d
where d.dataareaid =@DataAreaID
Except
Select distinct taxonkey
from dbo.TaxonDistribution t inner join dbo.CellToDataAreaMapping m
on t.cellid = m.cellid
where dataareaid =@DataAreaID
END

GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'this is AutoGen.  ing to be used to the internal processes on SQL server' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Data', @level2type=N'COLUMN',@level2name=N'UniqueAreaID_AutoGen'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "AllocationSimpleArea"
            Begin Extent = 
               Top = 7
               Left = 50
               Bottom = 158
               Right = 341
            End
            DisplayFlags = 280
            TopColumn = 4
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 899
         Table = 1175
         Output = 726
         Append = 1400
         NewValue = 1170
         SortType = 1348
         SortOrder = 1405
         GroupBy = 1350
         Filter = 1348
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwAllocationSimpleArea'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwAllocationSimpleArea'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[10] 4[3] 2[18] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "vwAllocationSimpleArea"
            Begin Extent = 
               Top = 7
               Left = 50
               Bottom = 158
               Right = 341
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1155
         Width = 1155
         Width = 1155
         Width = 1155
         Width = 1155
         Width = 1155
         Width = 1155
         Width = 1155
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwCoastalEEZFAOCombo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwCoastalEEZFAOCombo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[8] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "FriendlyTaxonCoverageReport"
            Begin Extent = 
               Top = 7
               Left = 50
               Bottom = 158
               Right = 282
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1152
         Width = 1521
         Width = 1152
         Width = 1498
         Width = 1947
         Width = 1843
         Width = 1659
         Width = 1152
         Width = 1152
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwForWeb_FriendlyTaxonCoverageReport_NIU'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwForWeb_FriendlyTaxonCoverageReport_NIU'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[9] 4[5] 2[46] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Data"
            Begin Extent = 
               Top = 7
               Left = 50
               Bottom = 158
               Right = 299
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 899
         Table = 1175
         Output = 726
         Append = 1400
         NewValue = 1170
         SortType = 1348
         SortOrder = 1405
         GroupBy = 1350
         Filter = 1348
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwTaxonCoverageReport'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwTaxonCoverageReport'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[12] 4[42] 2[34] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Data"
            Begin Extent = 
               Top = 7
               Left = 50
               Bottom = 158
               Right = 282
            End
            DisplayFlags = 280
            TopColumn = 7
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1763
         Width = 1924
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
         Width = 1152
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 899
         Table = 1175
         Output = 726
         Append = 1400
         NewValue = 1170
         SortType = 1348
         SortOrder = 1405
         GroupBy = 1350
         Filter = 1348
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwTaxonCoverageReport_v1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwTaxonCoverageReport_v1'
GO
USE [master]
GO
ALTER DATABASE [Merlin] SET  READ_WRITE 
GO
