@ECHO OFF
IF [%1]==[] (
  SET DbServer=localhost
) ELSE (
  SET DbServer=%1
)

IF [%2]==[] (
  SET DbPort=5432
) ELSE (
  SET DbPort=%2
)

IF EXIST db_dump GOTO DumpOutDB
mkdir db_dump

:DumpOutDB
IF EXIST db_dump\toc.dat DEL db_dump\*

echo Password for user sau
pg_dump -h %DbServer% -p %DbPort% -f db_dump -T web.django_migrations -T admin.django_migrations -Fd -E UTF8 -j 8 -O --no-unlogged-table-data -U sau -n web -n web_cache -n fao -n geo -n feru -n expedition -n distribution -n admin -n web_partition sau

@ECHO OFF

