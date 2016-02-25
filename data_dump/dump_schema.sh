#!/bin/sh

if [ -z "$2" ]; then
  DbHost=localhost
else
  DbHost=$2
fi

if [ -z "$3" ]; then
  DbPort=5432
else
  DbPort=$3
fi
echo Password for user sau
pg_dump -h $DbHost -p $DbPort -f $1.schema -T web.django_migrations -Fc -a -E UTF8 -U sau -n $1 sau
