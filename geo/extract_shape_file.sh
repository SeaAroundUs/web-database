#!/bin/sh

if [ -z "$1" ]; then
  echo -n "Enter output shape file name: "
  read ShapeFile
else
  ShapeFile=$1
fi

if [ -z "$2" ]; then
  echo -n "Enter db table or query in quotes: "
  read TableOrQuery
else
  TableOrQuery=$2
fi

if [ -z "$3" ]; then
  DbServer=localhost
else
  DbServer=$3
fi

pgsql2shp -f "$ShapeFile" -u sau -h "$DbServer" -P sau sau "$TableOrQuery"

