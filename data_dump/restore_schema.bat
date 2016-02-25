@ECHO OFF
IF [%1]==[] (
  SET /p DumpFile=Enter schema dump file name:
) ELSE (
  SET DumpFile=%1
)

IF [%2]==[] (
  SET DbHost=localhost
) ELSE (
  SET DbHost=%2
)

IF [%3]==[] (
  SET Threads=4
) ELSE (
  SET Threads=%3
)

echo Password for user sau
pg_restore -h %DbHost% -Fc -j %Threads% -a -d sau -U sau %DumpFile%

