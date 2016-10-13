drop view if exists web.v_country_profile;

alter table web.country_fishery_profile
alter fish_mgt_plan type text,
alter url_fish_mgt_plan type text,
alter gov_marine_fish type text,
alter major_law_plan type text,
alter url_major_law_plan type text,
alter gov_protect_marine_env type text,
alter url_gov_protect_marine_env type text;

create or replace view web.v_country_profile
as
  with cntry as (
    select c.*, 
           fp.fish_mgt_plan,fp.url_fish_mgt_plan,fp.gov_marine_fish,fp.major_law_plan,fp.url_major_law_plan,fp.gov_protect_marine_env,fp.url_gov_protect_marine_env,
           array(select row_to_json(n.*) from web.country_ngo n where n.count_code = c.count_code) as ngo
      from web.country c
      left join web.country_fishery_profile fp on (fp.count_code = c.count_code)
  )
  select c.count_code, c.c_number, c.country, row_to_json(c.*) AS asjson
    from cntry c;

truncate web.country_fishery_profile;

\copy web.country_fishery_profile from 'country_fishery_profile_updated_2016-10-11.txt' with (format csv, header, delimiter E'\t')

VACUUM FULL ANALYZE web.country_fishery_profile;

INSERT INTO admin.datatransfer_tables(source_database_name, source_table_name, source_select_clause, source_where_clause, target_schema_name, target_table_name, target_excluded_columns)
VALUES     
('sau_int', 'master.country_fishery_profile', '*', NULL, 'web', 'country_fishery_profile', '{}'::TEXT[]);

VACUUM FULL ANALYZE admin.datatransfer_tables;

select admin.grant_access();
