create or replace function csv_escape(i_string text) 
returns text
as
$body$
  select '"' || replace(i_string, '"', '""') || '"';
$body$
language sql;
