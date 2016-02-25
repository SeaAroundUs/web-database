@ECHO OFF
IF [%1]==[] (
  SET /p ShapeFile=Enter output shape file name:
) ELSE (
  SET ShapeFile=%1
)

IF [%2]==[] (
  SET /p TableOrQuery=Enter db table or query in quotes:
) ELSE (
  SET TableOrQuery=%2
)

IF [%3]==[] (
  SET /p DbServer=Enter db host name/ip:
) ELSE (
  SET DbServer=%3
)

IF [%4]==[] (
  SET /p DbPass=Enter password/ip:
) ELSE (
  SET DbPass=%4
)

pgsql2shp -f %ShapeFile% -u web -h %DbServer% -P %DbPass% sau %TableOrQuery%
@ECHO ON

