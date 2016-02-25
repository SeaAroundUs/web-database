create or replace function distribution.establish_foreign_table_linkages(i_web_int_password text) returns void as
$body$
begin
  if not exists (select 1 from pg_foreign_server where srvname = 'sau_int' limit 1) then
    create server sau_int foreign data wrapper postgres_fdw options (host 'localhost', port '5432', dbname 'sau_int');
    execute format('create user mapping for public server sau_int options (user ''web_int'', password ''%s'')', i_web_int_password);
  end if;

  if not exists (select 1 
                   from pg_foreign_table t
                   join pg_foreign_server s on (s.oid = t.ftserver and s.srvname = 'sau_int') 
                  where t.ftoptions = array['schema_name=distribution', 'table_name=taxon_distribution']   
                  limit 1) then
    create foreign table distribution.taxon_distribution(
        taxon_distribution_id int,
        taxon_key integer not null,
        cell_id integer not null,
        relative_abundance double precision not null 
    )
    server sau_int options(schema_name 'distribution', table_name 'taxon_distribution');
  end if;
  
  perform admin.grant_access();
end
$body$
language plpgsql;

--copy into console and add password
--select distribution.establish_foreign_table_linkages('{add password here}');
