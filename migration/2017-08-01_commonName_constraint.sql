alter table web.cube_dim_taxon
alter common_name set NOT NULL;

vacuum analyze web.cube_dim_taxon;

SELECT admin.grant_access();
