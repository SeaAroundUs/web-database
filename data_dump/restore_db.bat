@ECHO OFF
IF [%1]==[] (
  SET DbHost=localhost
) ELSE (
  SET DbHost=%1
)

IF [%2]==[] (
  SET DbPort=5432
) ELSE (
  SET DbPort=%2
)

IF EXIST db_dump GOTO EmptyDirCheck
ECHO No prior database dump directory exists. Please execute dump_db before executing this script.
GOTO End

:EmptyDirCheck
IF EXIST db_dump\toc.dat GOTO RestoreDB
ECHO Database dump directory (db_dump) is empty. Please execute dump_db before executing this script.
GOTO End

:RestoreDB
ECHO Password for user sau
psql -h %DbHost% -p %DbPort% -c "DROP SCHEMA IF EXISTS web,web_cache,fao,geo,feru,expedition,distribution,admin CASCADE" sau sau
ECHO Password for user sau
pg_restore -h %DbHost% -p %DbPort% -Fd -j 8 -d sau -O --disable-triggers -U sau db_dump

:End
SET DbHost=
SET DbPort=
POPD
GOTO:EOF
