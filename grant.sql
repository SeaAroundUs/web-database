--DO NOT assign sau role to app users, if fine-grain access control is desirable
--- Assign sau role to allocation and web users
--GRANT sau TO allocation; 
--GRANT sau TO web;

CREATE OR REPLACE FUNCTION admin.grant_access() RETURNS void AS
$body$
BEGIN
  --- Granting access to user is very important to enable insert/delete/update 
  --- operations on the tables
  IF is_schema_exists('admin') THEN
    GRANT USAGE ON SCHEMA admin TO allocation;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA admin TO allocation;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA admin TO allocation;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA admin TO allocation;
    
    GRANT USAGE ON SCHEMA admin TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA admin TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA admin TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA admin TO web;
    
    /* Writeable grants to specific tables in the admin schema to the web user */
    GRANT ALL ON TABLE admin.version,admin.corsheaders_corsmodel,admin.django_content_type,admin.django_migrations,admin.django_session,admin.remora_sauuser TO web;
    GRANT ALL ON SEQUENCE admin.version_id_seq,admin.corsheaders_corsmodel_id_seq,admin.django_content_type_id_seq,admin.django_migrations_id_seq,admin.remora_sauuser_id_seq TO web;     
  END IF;
  
  IF is_schema_exists('allocation') THEN
    GRANT USAGE ON SCHEMA allocation TO allocation;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA allocation TO allocation;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA allocation TO allocation;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA allocation TO allocation;
    
    GRANT USAGE ON SCHEMA allocation TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA allocation TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA allocation TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA allocation TO web;
  END IF;
  
  IF is_schema_exists('web') THEN
    GRANT USAGE ON SCHEMA web TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA web TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA web TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA web TO web;
  END IF;
  
  IF is_schema_exists('web_partition') THEN
    GRANT USAGE ON SCHEMA web_partition TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA web_partition TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA web_partition TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA web_partition TO web;
  END IF;
  
  IF is_schema_exists('web_cache') THEN
    GRANT USAGE ON SCHEMA web_cache TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA web_cache TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA web_cache TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA web_cache TO web;
  END IF;
  
  IF is_schema_exists('fao') THEN
    GRANT USAGE ON SCHEMA fao TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA fao TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA fao TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA fao TO web;
  END IF;
  
  IF is_schema_exists('geo') THEN
    GRANT USAGE ON SCHEMA geo TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA geo TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA geo TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA geo TO web;
  END IF;
  
  IF is_schema_exists('feru') THEN
    GRANT USAGE ON SCHEMA feru TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA feru TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA feru TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA feru TO web;
  END IF;
  
  IF is_schema_exists('expedition') THEN
    GRANT USAGE ON SCHEMA expedition TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA expedition TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA expedition TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA expedition TO web;
  END IF;
  
  IF is_schema_exists('distribution') THEN
    GRANT USAGE ON SCHEMA distribution TO web;
    GRANT SELECT,REFERENCES ON ALL TABLES IN SCHEMA distribution TO web;
    GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA distribution TO web;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA distribution TO web;
  END IF;
END
$body$
LANGUAGE plpgsql
SECURITY DEFINER;

SELECT admin.grant_access();
