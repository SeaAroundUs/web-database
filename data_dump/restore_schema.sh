#!/bin/sh

if [ -z "$1" ]; then
  echo -n "Enter schema dump file name: "
  read DumpFile
else
  DumpFile=$1
fi

if [ -z "$2" ]; then
  DbHost=localhost
else
  DbHost=$2
fi

if [ -z "$3" ]; then
  Threads=4
else
  Threads=$3
fi

STIME=$(date '+%s')
echo Password for user sau
pg_restore -h $DbHost -Fc -j $Threads -a -d sau -U sau $DumpFile
ETIME=$(date '+%s')
echo "Data dump $DumpFile restored in $(($ETIME - $STIME)) seconds"
