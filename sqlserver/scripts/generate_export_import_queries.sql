select 'echo "Exporting data from source database..."';
select 'echo ' + CHAR(36) + '(date)';

select 'bcp ' + table_catalog + '.' + table_schema + '.' + TABLE_NAME + ' out C:\sau\' + table_name + '.dat -N -T -a 65535'
  from INFORMATION_SCHEMA.TABLES where TABLE_TYPE='BASE TABLE' order by table_name;

select 'echo "Importing data into target RDS database..."';
select 'echo ' + CHAR(36) + '(date)';

select 'bcp ' + i.table_catalog + '.' + i.table_schema + '.' + i.TABLE_NAME + ' in C:\sau\' + i.table_name + '.dat -E -N -h TABLOCK -S sau-merlin-1.ck24jacu2hmg.us-west-2.rds.amazonaws.com -U sau_merlin -P P4tF7KuQz4 -b 100000 -a 65535'
  from INFORMATION_SCHEMA.TABLES i
 where i.TABLE_TYPE = 'BASE TABLE';
