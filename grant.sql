--DO NOT assign sau role to app users, if fine-grain access control is desirable
--- Assign sau role to allocation and web users
--GRANT sau TO allocation; 
--GRANT sau TO web;
CREATE OR REPLACE FUNCTION admin.grant_privilege(i_schema text, i_user text, i_is_read_write boolean = false, i_is_delete boolean = false) RETURNS void AS
$body$
BEGIN
  IF is_schema_exists(i_schema) THEN
	  -- For all
	  EXECUTE format('GRANT USAGE ON SCHEMA %s TO %s', i_schema, i_user);
	  
	  IF i_is_read_write THEN
		IF i_is_delete THEN
		  EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE,REFERENCES ON ALL TABLES IN SCHEMA %s TO %s', i_schema, i_user);
		ELSE
		  EXECUTE format('GRANT INSERT,UPDATE,SELECT,REFERENCES ON ALL TABLES IN SCHEMA %s TO %s', i_schema, i_user);
		END IF;
		
		EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %s TO %s', i_schema, i_user);
		EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %s TO %s', i_schema, i_user);
	  ELSE
		EXECUTE format('GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA %s TO %s', i_schema, i_user);
		EXECUTE format('GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA %s TO %s', i_schema, i_user);
		EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %s TO %s', i_schema, i_user);
	  END IF;
  END IF;
  RETURN;
END
$body$
LANGUAGE plpgsql
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin.grant_access() RETURNS void AS
$body$
BEGIN
    -- For user allocation
  PERFORM admin.grant_privilege('admin', 'allocation', false, false);
  PERFORM admin.grant_privilege('allocation', 'allocation', false, false);
  
  -- for user web
  PERFORM admin.grant_privilege('admin', 'web', false, false);
  PERFORM admin.grant_privilege('allocation', 'web', false, false);
  PERFORM admin.grant_privilege('web', 'web', false, false);
  PERFORM admin.grant_privilege('web_partition', 'web', false, false);
  PERFORM admin.grant_privilege('web_cache', 'web', false, false);
  PERFORM admin.grant_privilege('fao', 'web', false, false);
  PERFORM admin.grant_privilege('geo', 'web', false, false);
  PERFORM admin.grant_privilege('feru', 'web', false, false);
  PERFORM admin.grant_privilege('expedition', 'web', false, false);
  PERFORM admin.grant_privilege('distribution', 'web', false, false);
  PERFORM admin.grant_privilege('allocation_partition', 'web', false, false);
  PERFORM admin.grant_privilege('allocation_data_partition', 'web', false, false);
  PERFORM admin.grant_privilege('cmsy', 'web', false, false);
  
   IF is_schema_exists('admin') THEN
   /* Writeable grants to specific tables in the admin schema to the web user */
    GRANT ALL ON TABLE admin.version,admin.corsheaders_corsmodel,admin.django_content_type,admin.django_migrations,admin.django_session,admin.remora_sauuser TO web;
    GRANT ALL ON SEQUENCE admin.version_id_seq,admin.corsheaders_corsmodel_id_seq,admin.django_content_type_id_seq,admin.django_migrations_id_seq,admin.remora_sauuser_id_seq TO web;     
   END IF;
  
  -- For user sau_reader
  PERFORM admin.grant_privilege('allocation', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('admin', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('web', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('web_partition', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('web_cache', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('fao', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('geo', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('feru', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('expedition', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('distribution', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('allocation_partition', 'sau_reader', false, false);
  PERFORM admin.grant_privilege('allocation_data_partition', 'sau_reader', false, false);
  
  RETURN;
END
$body$
LANGUAGE plpgsql
SECURITY DEFINER;

SELECT admin.grant_access();
