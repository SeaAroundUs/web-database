\echo
\echo Adding usefull extensions...
\echo
-- sau public (global) schema objects
\i set_users_search_path.sql
\i aggregate.sql
\i table_public.sql
\i view.sql
\cd util
\i initialize.sql
\cd ..

--These extensions are not supported by RDS
--CREATE EXTENSION adminpack;
--CREATE EXTENSION xml2;

DROP EXTENSION IF EXISTS dblink CASCADE;
DROP EXTENSION IF EXISTS hstore CASCADE;
DROP EXTENSION IF EXISTS intarray CASCADE;
DROP EXTENSION IF EXISTS tablefunc CASCADE;
DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;
DROP EXTENSION IF EXISTS fuzzystrmatch CASCADE;
DROP EXTENSION IF EXISTS postgis CASCADE;
DROP EXTENSION IF EXISTS postgres_fdw;

CREATE EXTENSION dblink;
CREATE EXTENSION hstore;
CREATE EXTENSION intarray;
CREATE EXTENSION tablefunc;
CREATE EXTENSION "uuid-ossp";
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION postgis_tiger_geocoder;
--CREATE EXTENSION file_fdw;
CREATE EXTENSION postgres_fdw;

\echo
\echo Creating Admin DB Objects...
\echo
\c sau sau
--- Create a project schema (namespace) for ease of maintenance (backup)
DROP SCHEMA IF EXISTS admin CASCADE;
CREATE SCHEMA admin;

DROP SCHEMA IF EXISTS allocation CASCADE;
CREATE SCHEMA allocation;

DROP SCHEMA IF EXISTS web CASCADE;
CREATE SCHEMA web;

DROP SCHEMA IF EXISTS web_partition CASCADE;
CREATE SCHEMA web_partition;

DROP SCHEMA IF EXISTS geo CASCADE;
CREATE SCHEMA geo;

DROP SCHEMA IF EXISTS feru CASCADE;
CREATE SCHEMA feru;

DROP SCHEMA IF EXISTS expedition CASCADE;
CREATE SCHEMA expedition;

DROP SCHEMA IF EXISTS distribution CASCADE;
CREATE SCHEMA distribution;

DROP SCHEMA IF EXISTS fao CASCADE;
CREATE SCHEMA fao;

\i table_admin.sql
\i grant.sql

\echo
\echo Creating Allocation DB Objects...
\echo
\i table_allocation.sql
\i view_allocation.sql
\i function_allocation.sql

\echo
\echo Creating FAO DB Objects...
\echo
\i table_fao.sql

\echo
\echo Creating Web DB Objects...
\echo
\i table_web.sql
\i function_web.sql
\i mat_view_web.sql
\i view_web.sql
\i function_mariculture_data.sql
\i function_catch_by_dimension.sql
\i function_catch_in_csv.sql
\i function_indicators.sql
\i function_spatial_catch.sql
\i function_web_partition.sql
\i function_entity_layer.sql
\i populate_web.sql

\i table_feru.sql
\i function_feru.sql

\i table_geo.sql
\i function_geo.sql
\i view_geo.sql

\i table_expedition.sql

select admin.grant_access();
