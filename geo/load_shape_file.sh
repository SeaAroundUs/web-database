#!/bin/sh

if [ -z "$1" ]; then
  echo -n "Enter input shape file name: "
  read ShapeFile
else
  ShapeFile=$1
fi

if [ -z "$2" ]; then
  echo -n "Enter db table: "
  read TableName
else
  TableName=$2
fi

if [ -z "$3" ]; then
  DbServer=localhost
else
  DbServer=$3
fi

if [ -z "$4" ]; then
  UpdateMode=-c
else
  UpdateMode=$4
fi

shp2pgsql -s 4326 $UpdateMode -D $ShapeFile $TableName | psql -d sau -U sau -h "$DbServer"

