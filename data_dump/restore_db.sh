#!/bin/sh

###########################################################
## Function to call when error is encountered
###########################################################
ExitWithError () {
  echo
  exit 1            
}

if [ -z "$1" ]; then
  DbHost=localhost
else
  DbHost=$1
fi

if [ -z "$2" ]; then
  DbPort=5432
else
  DbPort=$2
fi



echo Password for user sau
psql -h $DbHost -p $DbPort -c "DROP SCHEMA IF EXISTS web,web_cache,fao,geo,feru,expedition,distribution,admin CASCADE" sau sau
echo Password for user sau
pg_restore -h $DbHost -p $DbPort -Fd -j 8 -O --disable-triggers -U sau -d sau db_dump
