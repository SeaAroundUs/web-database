/* For database versioning */
CREATE TABLE admin.version (
  id serial primary key,
  name varchar(50),
  major int not null,
  minor int not null,
  revision int,
  is_active boolean not null default false,
  released_to_qa timestamp,
  released_to_staging timestamp,
  released_to_production timestamp,
  last_modified timestamp not null default now(),
  description text
);

/* For user registration/access control */
CREATE TABLE admin.corsheaders_corsmodel (
    id serial PRIMARY KEY,
    cors character varying(255) NOT NULL
);

CREATE TABLE admin.django_content_type (
    id serial PRIMARY KEY,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);

CREATE TABLE admin.django_migrations (
    id serial PRIMARY KEY,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);

CREATE TABLE admin.django_session (
    session_key character varying(40) PRIMARY KEY,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);

CREATE TABLE admin.remora_sauuser (
    id serial PRIMARY KEY,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    email character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    organization character varying(50) NOT NULL,
    activation_token character varying(64),
    token character varying(64)
);

/* For transfering of data from SQL Server */
CREATE TABLE admin.datatransfer_tables(
  id SERIAL PRIMARY KEY,
  source_database_name VARCHAR(256),
  source_table_name VARCHAR(256),
  source_key_column VARCHAR(256),
  source_where_clause TEXT,
  target_schema_name VARCHAR(256),
  target_table_name VARCHAR(256),
  target_excluded_columns TEXT[],
  number_of_threads INT NOT NULL DEFAULT 1,
  last_transferred TIMESTAMP,
  last_transfer_success BOOLEAN
);

/* For interative viewing/editing of data */
CREATE TABLE admin.knittool_query
(
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  sql TEXT NOT NULL,
  column_width TEXT[][],
  modified TIMESTAMP NOT NULL DEFAULT current_timestamp
);

CREATE UNIQUE INDEX knittool_query_uk ON admin.knittool_query(LOWER(name));

CREATE OR REPLACE FUNCTION admin.save_knittool_query(i_name TEXT, i_sql TEXT) RETURNS INTEGER AS
$body$
DECLARE
  query_id INTEGER;
  query_sql TEXT;
BEGIN
  SELECT id, sql
    INTO query_id, query_sql
    FROM admin.knittool_query
   WHERE LOWER(name) = LOWER(i_name);
    
  IF FOUND THEN
    IF i_sql <> query_sql THEN
      UPDATE admin.knittool_query 
         SET sql = i_sql, modified = current_timestamp
       WHERE id = query_id;
    END IF;
  ELSE
    INSERT INTO admin.knittool_query(name, sql)
         VALUES (i_name, i_sql)
      RETURNING id 
           INTO query_id;
  END IF;
  
  RETURN query_id;
END;
$body$
LANGUAGE plpgsql;
