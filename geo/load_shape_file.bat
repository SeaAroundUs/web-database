IF [%1]==[] (
  set /p ShapeFile=Enter shape file name: 
) else (
  SET ShapeFile=%1
)

IF [%2]==[] ( 
  set /p TableName=Enter db table: 
) else (
  SET TableName=%2
)

IF [%3]==[] ( 
  set /p DbServer=Enter db host ip or name: 
) else (
  set DbServer=%3
)

IF [%4]==[] ( 
  set UpdateMode=-c
) else (
  set UpdateMode=%4
)

shp2pgsql -s 4326 %UpdateMode% -D %ShapeFile% %TableName% | psql -d sau -U sau -h %DbServer%

