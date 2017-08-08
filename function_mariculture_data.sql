create or replace function web.f_mariculture_data_by_species(i_mariculture_entity_id int, i_sub_unit_id int default null, i_top_count_limit int default 11)
returns json 
as
$body$
  with md_summary(taxon_key, year, production) as (
    select md.taxon_key, md.year, sum(md.production)
      from web.mariculture_sub_entity se
      join web.mariculture_data md on (md.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
     where se.mariculture_entity_id = i_mariculture_entity_id
       and se.mariculture_sub_entity_id = coalesce(i_sub_unit_id, se.mariculture_sub_entity_id)
     group by md.taxon_key, md.year
     having sum(md.production) > 0.0
  ),
  top_taxon(taxon_key, production_rank) as (
    select t.taxon_key, row_number() over(order by t.production desc)
      from (select mds.taxon_key, sum(mds.production) as production
              from md_summary mds
             --where mds.taxon_key not in (100039, 100139, 100239, 100339)
             group by mds.taxon_key
             order by production desc
             limit i_top_count_limit
           ) as t
  ),
  total_by_year(year, mixed_group, total)  as (
    select mds.year, sum(case when tt.taxon_key is null then mds.production else 0 end), sum(mds.production)
      from md_summary mds
      left join top_taxon tt on (tt.taxon_key = mds.taxon_key)
     group by mds.year
  ),
  max_year(year_threshold) as (
    select max(year) from mariculture_data
  )
  select json_agg(fd.*) 
    from ((select t.taxon_key as entity_id, t.common_name as key, t.scientific_name,
                  (select array_accum(array[array[tm.time_business_key, coalesce(mds.production::int, 0)]] order by tm.time_key) 
                     from web.time tm
                     join max_year my on (tm.time_business_key <= my.year_threshold)
                     left join md_summary mds on (mds.year = tm.time_business_key and mds.taxon_key = top.taxon_key)
                  ) as values
             from top_taxon top
             join web.cube_dim_taxon t on (t.taxon_key = top.taxon_key)
            order by top.production_rank)
         union all
         (select null::int, 'Others'::text as key, null::text, 
                 (select array_accum(array[array[tm.time_business_key, coalesce(tby.mixed_group::int, 0)]] order by tm.time_key) 
                    from web.time tm
                     join max_year my on (tm.time_business_key <= my.year_threshold)
                    left join total_by_year tby on (tby.year = tm.time_business_key)) as values)
         )
      as fd;
$body$
language sql;

create or replace function web.f_mariculture_data_by_species_tsv(i_mariculture_entity_id int, i_sub_unit_id int default null, i_top_count_limit int default 11, i_is_scientific_name boolean default false)
returns setof text 
as
$body$
declare
  top_count_limit int := coalesce(i_top_count_limit, 11);
  is_scientific_name boolean := coalesce(i_is_scientific_name, false);
begin
  return query
  with md_summary(taxon_key, year, production) as (
    select md.taxon_key, md.year, sum(md.production)
      from web.mariculture_sub_entity se
      join web.mariculture_data md on (md.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
     where se.mariculture_entity_id = i_mariculture_entity_id
       and se.mariculture_sub_entity_id = coalesce(i_sub_unit_id, se.mariculture_sub_entity_id)
     group by md.taxon_key, md.year
     having sum(md.production) > 0.0
  ),
  top_taxon(taxon_key, production_rank) as (
    select t.taxon_key, row_number() over(order by t.production desc)
      from (select mds.taxon_key, sum(mds.production) as production
              from md_summary mds
             --where mds.taxon_key not in (100039, 100139, 100239, 100339)
             group by mds.taxon_key
             order by production desc
             limit i_top_count_limit
           ) as t
  ),
  total_by_year(year, mixed_group, total)  as (
    select mds.year, sum(case when tt.taxon_key is null then mds.production else 0 end), sum(mds.production)
      from md_summary mds
      left join top_taxon tt on (tt.taxon_key = mds.taxon_key)
     group by mds.year
  ),
  max_year(year_threshold) as (
    select max(year) from mariculture_data
  )
  select array_to_string('Year'::text || array_agg(csv_escape(case when is_scientific_name then t.scientific_name else t.common_name end)::text order by top.production_rank) || 'Mixed group'::text || 'Total'::text, E'\t') 
    from top_taxon top
    join web.cube_dim_taxon t on (t.taxon_key = top.taxon_key)
  union all
  select array_to_string(tm.time_business_key::text || array_agg(coalesce(mds.production::int, 0)::text order by tm.time_business_key, top.production_rank nulls last) || coalesce(max(tby.mixed_group::int), 0)::text || coalesce(max(tby.total::int), 0)::text, E'\t')
    from web.time tm
    join max_year my on (tm.time_business_key <= my.year_threshold)
    left join top_taxon top on (true)
    left join total_by_year tby on (tby.year = tm.time_business_key) 
    left join md_summary mds on (mds.year = tm.time_business_key and mds.taxon_key = top.taxon_key)
   group by tm.time_business_key;
end
$body$
language plpgsql;

create or replace function web.f_mariculture_data_by_commercial_groups(i_mariculture_entity_id int, i_sub_unit_id int default null)
returns json 
as
$body$
  with md_summary(commercial_group_id, year, production) as (
    select wt.commercial_group_id, md.year, sum(md.production)
      from web.mariculture_sub_entity se
      join web.mariculture_data md on (md.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
      join web.cube_dim_taxon wt on (wt.taxon_key = md.taxon_key)
     where se.mariculture_entity_id = i_mariculture_entity_id
       and se.mariculture_sub_entity_id = coalesce(i_sub_unit_id, se.mariculture_sub_entity_id)
     group by wt.commercial_group_id, md.year
     having sum(md.production) > 0.0
  ),
  top_cgroup(commercial_group_id, production_rank) as (
    select t.commercial_group_id, row_number() over(order by t.production desc)
      from (select mds.commercial_group_id, sum(mds.production) as production
              from md_summary mds
             group by mds.commercial_group_id
             order by production desc
           ) as t
  ),
  total_by_year(year, total)  as (
    select mds.year, sum(mds.production) from md_summary mds group by mds.year
  ),
  max_year(year_threshold) as (
    select max(year) from mariculture_data
  )
  select json_agg(fd.*) 
    from (select cg.commercial_group_id as entity_id, cg.name as key,
                 (select array_accum(array[array[tm.time_business_key, coalesce(mds.production::int, 0)]] order by tm.time_key) 
                    from web.time tm
                    join max_year my on (tm.time_business_key <= my.year_threshold)
                    left join md_summary mds on (mds.year = tm.time_business_key and mds.commercial_group_id = top.commercial_group_id)
                 ) as values
            from top_cgroup top
            join web.commercial_groups cg on (cg.commercial_group_id = top.commercial_group_id)
           order by top.production_rank)
      as fd;
$body$
language sql;

create or replace function web.f_mariculture_data_by_commercial_groups_tsv(i_mariculture_entity_id int, i_sub_unit_id int default null)
returns setof text 
as
$body$
  with md_summary(commercial_group_id, year, production) as (
    select wt.commercial_group_id, md.year, sum(md.production)
      from web.mariculture_sub_entity se
      join web.mariculture_data md on (md.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
      join web.cube_dim_taxon wt on (wt.taxon_key = md.taxon_key)
     where se.mariculture_entity_id = i_mariculture_entity_id
       and se.mariculture_sub_entity_id = coalesce(i_sub_unit_id, se.mariculture_sub_entity_id)
     group by wt.commercial_group_id, md.year
     having sum(md.production) > 0.0
  ),
  top_cgroup(commercial_group_id, production_rank) as (
    select t.commercial_group_id, row_number() over(order by t.production desc)
      from (select mds.commercial_group_id, sum(mds.production) as production
              from md_summary mds
             group by mds.commercial_group_id
             order by production desc
           ) as t
  ),
  total_by_year(year, total)  as (
    select mds.year, sum(mds.production) from md_summary mds group by mds.year
  ),
  max_year(year_threshold) as (
    select max(year) from mariculture_data
  )
  select array_to_string('Year'::text || array_agg(cg.name::text order by top.production_rank) || 'Total'::text, E'\t') 
    from top_cgroup top
    join web.commercial_groups cg on (cg.commercial_group_id = top.commercial_group_id)
  union all
  select array_to_string(tm.time_business_key::text || array_agg(coalesce(mds.production::int, 0)::text order by tm.time_business_key, top.production_rank) || coalesce(max(tby.total::int), 0)::text, E'\t')
    from web.time tm
    join max_year my on (tm.time_business_key <= my.year_threshold)
    left join top_cgroup top on (true)
    left join total_by_year tby on (tby.year = tm.time_business_key) 
    left join md_summary mds on (mds.year = tm.time_business_key and mds.commercial_group_id = top.commercial_group_id)
   group by tm.time_business_key;
$body$
language sql;

create or replace function web.f_mariculture_data_by_functional_groups(i_mariculture_entity_id int, i_sub_unit_id int default null)
returns json                            
as
$body$
  with md_summary(functional_group_id, year, production) as (
    select wt.functional_group_id, md.year, sum(md.production)
      from web.mariculture_sub_entity se
      join web.mariculture_data md on (md.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
      join web.cube_dim_taxon wt on (wt.taxon_key = md.taxon_key)
     where se.mariculture_entity_id = i_mariculture_entity_id
       and se.mariculture_sub_entity_id = coalesce(i_sub_unit_id, se.mariculture_sub_entity_id)
     group by wt.functional_group_id, md.year
     --having sum(md.production) > 0.0
  ),
  top_fgroup(functional_group_id, production_rank) as (
    select t.functional_group_id, row_number() over(order by t.production desc)
      from (select mds.functional_group_id, sum(mds.production) as production
              from md_summary mds
             group by mds.functional_group_id
             order by production desc
           ) as t
  ),
  total_by_year(year, total)  as (
    select mds.year, sum(mds.production) from md_summary mds group by mds.year
  ),
  max_year(year_threshold) as (
    select max(year) from mariculture_data
  )
  select json_agg(fd.*) 
    from (select fg.functional_group_id as entity_id, fg.description as key,
                 (select array_accum(array[array[tm.time_business_key, coalesce(mds.production::int, 0)]] order by tm.time_key) 
                    from web.time tm
                    join max_year my on (tm.time_business_key <= my.year_threshold)
                    left join md_summary mds on (mds.year = tm.time_business_key and mds.functional_group_id = top.functional_group_id)
                 ) as values
            from top_fgroup top
            join web.functional_groups fg on (fg.functional_group_id = top.functional_group_id)
           order by top.production_rank)
      as fd;
$body$
language sql;

create or replace function web.f_mariculture_data_by_functional_groups_tsv(i_mariculture_entity_id int, i_sub_unit_id int default null)
returns setof text 
as
$body$
  with md_summary(functional_group_id, year, production) as (
    select wt.functional_group_id, md.year, sum(md.production)
      from web.mariculture_sub_entity se
      join web.mariculture_data md on (md.mariculture_sub_entity_id = se.mariculture_sub_entity_id)
      join web.cube_dim_taxon wt on (wt.taxon_key = md.taxon_key)
     where se.mariculture_entity_id = i_mariculture_entity_id
       and se.mariculture_sub_entity_id = coalesce(i_sub_unit_id, se.mariculture_sub_entity_id)
     group by wt.functional_group_id, md.year
     having sum(md.production) > 0.0
  ),
  top_fgroup(functional_group_id, production_rank) as (
    select t.functional_group_id, row_number() over(order by t.production desc)
      from (select mds.functional_group_id, sum(mds.production) as production
              from md_summary mds
             group by mds.functional_group_id
             order by production desc
           ) as t
  ),
  total_by_year(year, total)  as (
    select mds.year, sum(mds.production) from md_summary mds group by mds.year
  ),
  max_year(year_threshold) as (
    select max(year) from mariculture_data
  )
  select array_to_string('Year'::text || array_agg(fg.description::text order by top.production_rank) || 'Total'::text, E'\t') 
    from top_fgroup top
    join web.functional_groups fg on (fg.functional_group_id = top.functional_group_id)
  union all
  select array_to_string(tm.time_business_key::text || array_agg(coalesce(mds.production::int, 0)::text order by tm.time_business_key, top.production_rank) || coalesce(max(tby.total::int), 0)::text, E'\t')
    from web.time tm
    join max_year my on (tm.time_business_key <= my.year_threshold)
    left join top_fgroup top on (true)
    left join total_by_year tby on (tby.year = tm.time_business_key) 
    left join md_summary mds on (mds.year = tm.time_business_key and mds.functional_group_id = top.functional_group_id)
   group by tm.time_business_key;
$body$
language sql;
