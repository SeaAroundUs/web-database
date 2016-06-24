#!/bin/sh

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

if [ -d db_dump ]; then
  if [ -f db_dump/toc.dat ]; then
    rm -f db_dump/*
  fi
else
  mkdir db_dump
fi

echo Password for user sau
pg_dump -h $DbHost -p $DbPort -f db_dump -T web.django_migrations -T admin.django_migrations -Fd -E UTF8 -j 8 -O --no-unlogged-table-data -U sau -n web -n web_cache -n fao -n geo -n feru -n expedition -n distribution -n admin sau
