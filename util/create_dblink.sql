CREATE OR REPLACE FUNCTION public.create_sau_dblink(i_server_name_or_ip TEXT, i_user TEXT, i_password TEXT) 
RETURNS VOID 
AS
$body$
DECLARE
BEGIN
  PERFORM dblink_connect('dbname=sau host=' || i_server_name_or_ip || ' user=' || i_user || ' password=' || i_password);
END;
$body$ 
LANGUAGE plpgsql;

