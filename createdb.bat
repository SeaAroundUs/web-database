@ECHO OFF
SET CurrentDir=%~dp0
PUSHD %CurrentDir%

SET DATABASE_NAME=sau
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Process command line parameter(s)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET DbHost=%1
SET DbPort=%2
SET RestoreThreadCount=%3
SET RestoreCellCatch=%4

IF /i "%DbHost%"=="" SET DbHost=localhost
IF /i "%DbPort%"=="" SET DbPort=5432
IF /i "%RestoreThreadCount%"=="" SET RestoreThreadCount=8
IF /i "%RestoreCellCatch%"=="" SET RestoreCellCatch=false

:::::::::::::::::::::::::
:: Deleting any previous log files
:::::::::::::::::::::::::
IF EXIST log GOTO LogDirExists
mkdir log

:LogDirExists
IF EXIST log\*.log del /Q .\log\*.log

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Check if there's already a "sau" database present. 
::   If not, create the "sau" database and the requisite db users, then proceed to invoke the initialize.sql script.
::   If yes, proceed to invoke initialize.sql script only.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
FOR /F "tokens=1 delims=| " %%A IN ('"psql -h %DbHost% -p %DbPort% -U postgres -A -t -c "select datname from pg_database""') DO (
  IF /i "%%A"=="%DATABASE_NAME%" GOTO CreateSauUsers
)

psql -h %DbHost% -p %DbPort% -U postgres -c "CREATE DATABASE sau"
IF ERRORLEVEL 1 GOTO ErrorLabel

:CreateSauUsers
SET SQLINPUTFILE=create_user
psql -h %DbHost% -p %DbPort% -U postgres -f %SQLINPUTFILE%.sql -L .\log\%SQLINPUTFILE%.log
IF ERRORLEVEL 1 GOTO ErrorLabel
               
SET SQLINPUTFILE=set_users_search_path
psql -h %DbHost% -p %DbPort% -U postgres -f %SQLINPUTFILE%.sql -L .\log\%SQLINPUTFILE%.log
IF ERRORLEVEL 1 GOTO ErrorLabel

SET SQLINPUTFILE=initialize
psql -h %DbHost% -p %DbPort% -d %DATABASE_NAME% -U postgres -f %SQLINPUTFILE%.sql -L .\log\%SQLINPUTFILE%.log
IF ERRORLEVEL 1 GOTO ErrorLabel

:: Check if we are creating a database in an RDS environment, then reconfigure the postgis package appropriately for user access
FOR /F "tokens=1 delims=| " %%A IN ('"psql -h %DbHost% -p %DbPort% -U postgres -A -t -c "select usename from pg_user""') DO (
  IF /i "%%A"=="rdsadmin" GOTO ConfigureForRDS
)
GOTO InitializeSauSchema

:ConfigureForRDS
ECHO Amazon RDS environment detected. Re-configuring postgis environment appropriately...
SET SQLINPUTFILE=rds_postgis_setup
psql -h %DbHost% -p %DbPort% -d %DATABASE_NAME% -U postgres -f %SQLINPUTFILE%.sql -L .\log\%SQLINPUTFILE%.log
IF ERRORLEVEL 1 GOTO ErrorLabel

:: Initialize tables with data
:InitializeSauSchema
set schemas[0]="admin.schema"
set schemas[1]="web.schema"
set schemas[2]="geo.schema"
set schemas[3]="feru.schema"
set schemas[4]="expedition.schema"
set schemas[5]="fao.schema"
set schemas[7]="allocation.schema"
set schemas[8]="distribution.schema"

FOR /F "tokens=2 delims==" %%s in ('set schemas[') DO (
  ECHO Restoring %%s schema. Please enter password for user sau
  IF EXIST data_dump/%%s pg_restore -h %DbHost% -p %DbPort% -d %DATABASE_NAME% -Fc -a -j %RestoreThreadCount% -U sau data_dump/%%s
  IF ERRORLEVEL 1 GOTO ErrorLabel
)

IF /i NOT "%RestoreCellCatch%"=="true" GOTO SkipCellCatch
ECHO Restoring web_partition schema. Please enter password for user sau
IF EXIST data_dump/web_partition.schema pg_restore -h %DbHost% -p %DbPort% -d %DATABASE_NAME% -Fc -a -j %RestoreThreadCount% -U sau data_dump/web_partition.schema
IF ERRORLEVEL 1 GOTO ErrorLabel
:SkipCellCatch

:: Clear previous content or create anew
ECHO vacuum analyze; > rmv.sql
ECHO select update_all_sequence('sau'::text); >> rmv.sql
ECHO select * from web_partition.maintain_cell_catch_partition(); >> rmv.sql

:: Adding foreign keys
type index_web.sql >> rmv.sql
type foreign_key_web.sql >> rmv.sql

type index_geo.sql >> rmv.sql
type foreign_key_geo.sql >> rmv.sql

type index_allocation.sql >> rmv.sql
type foreign_key_allocation.sql >> rmv.sql

type index_feru.sql >> rmv.sql
type index_expedition.sql >> rmv.sql
type index_admin.sql >> rmv.sql

type update_fao_area_key.sql >> rmv.sql

:: Adding commands to refresh materialized views 
psql -h %DbHost% -p %DbPort% -d %DATABASE_NAME% -U sau -t -f refresh_mv.sql >> rmv.sql 
IF ERRORLEVEL 1 GOTO ErrorLabel

psql -h %DbHost% -p %DbPort% -d %DATABASE_NAME% -U sau -f rmv.sql
IF ERRORLEVEL 1 GOTO ErrorLabel

GOTO Success

:Success
ECHO.
CD %CurrentDir%
ECHO #####
ECHO Successfully created %DATABASE_NAME% database
ECHO #####
GOTO End

:ErrorLabel
CD %CurrentDir%
ECHO "######"
ECHO Error encountered trying to create %DATABASE_NAME% db.
ECHO See .\log\%SQLINPUTFILE%.log for more details...
ECHO #####
GOTO End

:End
SET DbHost=
SET DbPort=
POPD
GOTO:EOF
         