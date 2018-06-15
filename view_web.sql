/* standard views */
create or replace view web.v_eez_info
as                                     
  with eez_area_sum(main_area_id, total_area) as (
      select a.main_area_id, sum(a.area) from web.area a where marine_layer_id = 1 group by a.main_area_id
  )
  select a.area_key,
         a.marine_layer_id,
         a.main_area_id,
         a.sub_area_id,
         ge.geo_entity_id,
         fe.fishing_entity_id,    
         ge.name as geo_entity_name,
         e.name as eez_name,
         fao.name as fao_area_name,
         fe.name as fishing_entity_name,
         e.legacy_c_number c_number,
         e.declaration_year,
         coalesce(ge.started_eez_at::int, 9999) as started_eez_at,
         (case when fe2.geo_entity_id is not null then fe2.date_allowed_to_fish_other_eezs
               when fe3.geo_entity_id is not null then fe3.date_allowed_to_fish_other_eezs
               else 9999
           end) as date_allowed_to_fish_other_eezs,
         (case when fe2.geo_entity_id is not null then fe2.date_allowed_to_fish_high_seas
               when fe3.geo_entity_id is not null then fe3.date_allowed_to_fish_high_seas
               else 9999
           end) as date_allowed_to_fish_high_seas,
         a.area,
         a.shelf_area,
         a.ifa,
         a.coral_reefs,
         a.sea_mounts,
         (a.area * a.ppr / eas.total_area)::numeric(50,20) as ppr,
         a.number_of_cells         
    from web.area a
    join eez_area_sum eas on (eas.main_area_id = a.main_area_id)
    join web.eez e on (e.eez_id = a.main_area_id)
    join web.geo_entity ge on ge.geo_entity_id = e.geo_entity_id
    join web.fao_area fao on fao.fao_area_id = a.sub_area_id
    join web.fishing_entity fe on fe.fishing_entity_id = e.is_home_eez_of_fishing_entity_id
    left join web.fishing_entity fe2 on (fe2.geo_entity_id = ge.geo_entity_id and fe2.is_currently_used_for_web)
    left join web.fishing_entity fe3 on (fe3.geo_entity_id = ge.admin_geo_entity_id)
   where a.marine_layer_id = 1;

create or replace view web.v_commercial_group_catch
as
  select f.marine_layer_id,
         f.main_area_id,
         f.sub_area_id,
         f.year,
         cg.commercial_group_id,
         cg.name as commercial_group_name,
         f.catch_sum,
         f.real_value
    from web.v_fact_data f
    join web.v_web_taxon wt on wt.taxon_key = f.taxon_key
    join web.commercial_groups cg on cg.commercial_group_id = wt.commercial_group_id;

create or replace view web.v_catch_type_catch
as
 select f.marine_layer_id,
        f.main_area_id,
        f.sub_area_id,
        f.year,
        c.catch_type_id,
        f.catch_status,
        f.reporting_status,
        c.name AS catch_type_name,
        f.catch_sum,
        f.real_value
   from web.v_fact_data f
   join web.catch_type c on c.catch_type_id = f.catch_type_id;


create or replace view web.v_fishing_entity_catch
as
 select f.marine_layer_id,
        f.main_area_id,
        f.sub_area_id,
        f.year,
        fe.fishing_entity_id,
        fe.name AS fishing_entity_name,
        f.catch_sum,
        f.real_value,
        e.is_home_eez_of_fishing_entity_id
   from web.v_fact_data f
   join web.v_dim_fishing_entity fe on fe.fishing_entity_id = f.fishing_entity_id
   left join web.eez e on (e.eez_id = f.main_area_id and f.marine_layer_id = 1);

create or replace view web.v_fishing_sector_catch
as
 select f.marine_layer_id,
        f.main_area_id,
        f.sub_area_id,
        f.year,
        s.sector_type_id,
        s.name AS sector_name,
        f.catch_sum,
        f.real_value
   from web.v_fact_data f
   join web.sector_type s on s.sector_type_id = f.sector_type_id;


create or replace view web.v_functional_group_catch
as
 select f.marine_layer_id,
        f.main_area_id,
        f.sub_area_id,
        f.year,
        fg.functional_group_id,
        fg.name AS functional_group_name,
        fg.description AS functional_group_description,
        f.catch_sum,
        f.real_value
   from web.v_fact_data f
   join web.v_web_taxon wt on wt.taxon_key = f.taxon_key
   join web.functional_groups fg on fg.functional_group_id = wt.functional_group_id;


create or replace view web.v_gear_catch
as
 select f.marine_layer_id,
        f.main_area_id,
        f.sub_area_id,
        f.year,
        g.gear_id,
        g.name AS gear_name,
        f.catch_sum,
        f.real_value
   from web.v_fact_data f
   join web.gear g on g.gear_id = f.gear_id;


create or replace view web.v_taxon_catch
as
  select f.marine_layer_id,
         f.main_area_id,
         f.sub_area_id,
         f.year,
         wt.taxon_key,
         wt.scientific_name,
         wt.common_name,
         f.catch_sum,
         f.real_value
    from web.v_fact_data f
    join web.v_web_taxon wt on wt.taxon_key = f.taxon_key;

create or replace view web.v_eez_vs_high_seas
as
  with catch(time_key, catch_total, eez_catch_total, high_seas_catch_total, value_total, eez_value_total, high_seas_value_total) as (
    select f.time_key, 
           sum(f.catch_sum),
           sum(case when f.sub_area_id = 1 then f.catch_sum else 0 end),
           sum(case when f.sub_area_id = 2 then f.catch_sum else 0 end),
           sum(f.real_value),
           sum(case when f.sub_area_id = 1 then f.real_value else 0 end),
           sum(case when f.sub_area_id = 2 then f.real_value else 0 end)
      from web.v_fact_data f
     where f.marine_layer_id = 6 and f.main_area_id = 1 
     group by f.time_key
  )
  select dt.time_business_key::varchar as year, 
         (100 * (c.eez_catch_total / c.catch_total))::numeric(3) as eez_percent_catch, 
         (100 * (c.high_seas_catch_total / c.catch_total))::numeric(3) as high_seas_percent_catch,
         (100 * (c.eez_value_total / c.value_total))::numeric(3) as eez_percent_value, 
         (100 * (c.high_seas_value_total / c.value_total))::numeric(3) as high_seas_percent_value
    from web.v_dim_time dt
    join catch c on (c.time_key = dt.time_key)
   order by dt.time_business_key;

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

create or replace view web.v_taxon_habitat_index
as
  select hi.taxon_key,
         hi.taxon_name,
         hi.common_name as name,
         hi.sl_max,
         hi.cla_code,
         hi.ord_code,
         hi.fam_code,
         hi.gen_code,
         hi.spe_code,
         hi.habitat_diversity_index,
         hi.effective_d as effective_distance,
         hi.estuaries,
         hi.coral,
         hi.seagrass,
         hi.seamount,
         hi.others,
         hi.shelf as c_shelf,
         hi.slope as c_slope,
         hi.abyssal,
         hi.inshore,
         hi.offshore
    from web.habitat_index hi;

create or replace view web.v_subsidy
as
  with geo_to_srm(geo_entity_id, srm_geo_entity_id) as (
    select ge.geo_entity_id, 
           case 
           when exists (select 1 from web.subsidy_ref_mapping srm where srm.geo_entity_id = ge.geo_entity_id limit 1) then ge.geo_entity_id
           else (select srm.geo_entity_id from web.subsidy_ref_mapping srm where srm.geo_entity_id = ge.admin_geo_entity_id limit 1)
           end
      from web.geo_entity ge
  )
  select ge.geo_entity_id,
         ge.name,
         sy.year,
         (case ge.geo_entity_id 
          when 221 then
            (select json_agg(d.*) 
               from ((select e1.eez_id, e1.name from web.eez e1 where e1.geo_entity_id = ge.geo_entity_id and e1.is_currently_used_for_web order by e1.eez_id)
                    union all
                    (select e2.eez_id, e2.name from web.eez e2 where e2.geo_entity_id in (1, 90) and e2.is_currently_used_for_web order by e2.eez_id))
                 as d
            )
          else
            (select json_agg(d.*) 
               from (/*select e1.eez_id, e1.name 
                       from web.eez e1
                       join web.geo_entity wge on (wge.admin_geo_entity_id = ge.admin_geo_entity_id)
                      where e1.geo_entity_id = wge.geo_entity_id and e1.is_currently_used_for_web 
                      order by e1.eez_id*/
                     select e1.eez_id, e1.name from web.eez e1 where e1.geo_entity_id = ge.geo_entity_id and e1.is_currently_used_for_web order by e1.eez_id 
                    )
                 as d
            )
           end) as eez_components,
         (select json_agg(ad.*)
            from (select sdc.title, sdc.description,
                 (select json_agg(d.*)
                    from ((select sd.title, sd.description, s.a1::int as amount, null::numeric(8,2) perc_landed, srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.a1)
                            where sd.definition_id = 'A1')
                           union all
                           (select sd.title, sd.description, s.a2::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.a2)
                            where sd.definition_id = 'A2')
                           union all
                           (select sd.title, sd.description, s.a3::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.a3)
                            where sd.definition_id = 'A3')
                           union all
                           (select 'sub_total', null,
                                   (abs(s.a1) + abs(s.a2) + abs(s.a3))::int as amount, 
                                   (case when s.landed_value = 0 then null else ((abs(s.a1) + abs(s.a2) + abs(s.a3))/s.landed_value*100.00) end)::numeric(8,2), 
                                   null, 
                                   null,
                                   null)
                         ) as d
                 )
                 as figures
            from web.subsidy_definition sdc
           where sdc.definition_id = 'A0') as ad
         ) as a0,
         (select json_agg(ad.*)
            from (select sdc.title, sdc.description,
                 (select json_agg(d.*)
                    from ((select sd.title, sd.description, s.b1::int as amount, null::numeric(8,2) perc_landed, srd.url, srd.link_text, srd.reference_id  
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b1)
                            where sd.definition_id = 'B1')
                           union all
                           (select sd.title, sd.description, s.b2::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b2)
                            where sd.definition_id = 'B2')
                           union all
                           (select sd.title, sd.description, s.b3::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b3)
                            where sd.definition_id = 'B3')
                           union all
                           (select sd.title, sd.description, s.b4::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b4)
                            where sd.definition_id = 'B4')
                           union all
                           (select sd.title, sd.description, s.b5::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b5)
                            where sd.definition_id = 'B5')
                           union all
                           (select sd.title, sd.description, s.b6::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b6)
                            where sd.definition_id = 'B6')
                           union all
                           (select sd.title, sd.description, s.b7::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.b7)
                            where sd.definition_id = 'B7')
                           union all
                           (select 'sub_total', null, 
                                   (abs(s.b1) + abs(s.b2) + abs(s.b3) + abs(s.b4) + abs(s.b5) + abs(s.b6) + abs(s.b7))::int as amount,
                                   (case when s.landed_value = 0 then null else ((abs(s.b1) + abs(s.b2) + abs(s.b3) + abs(s.b4) + abs(s.b5) + abs(s.b6) + abs(s.b7))/s.landed_value*100.00) end)::numeric(8,2), 
                                   null, 
                                   null,
                                   null)
                         ) as d
                 )
                 as figures
            from web.subsidy_definition sdc
           where sdc.definition_id = 'B0') as ad
         ) as b0,
         (select json_agg(ad.*)
            from (select sdc.title, sdc.description,
                 (select json_agg(d.*)
                    from ((select sd.title, sd.description, s.c1::int as amount, null::numeric(8,2) perc_landed, srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.c1)
                            where sd.definition_id = 'C1')
                           union all
                           (select sd.title, sd.description, s.c2::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.c2)
                            where sd.definition_id = 'C2')
                           union all
                           (select sd.title, sd.description, s.c3::int as amount, null::numeric(8,2), srd.url, srd.link_text, srd.reference_id 
                             from web.subsidy_definition sd
                             left join web.subsidy_ref_definition srd on (srd.reference_id = srm.c3)
                            where sd.definition_id = 'C3')
                           union all
                           (select 'sub_total', null, 
                                   (abs(s.c1) + abs(s.c2) + abs(s.c3))::int as amount, 
                                   (case when s.landed_value = 0 then null else ((abs(s.c1) + abs(s.c2) + abs(s.c3))/s.landed_value*100.00) end)::numeric(8,2), 
                                   null, 
                                   null,
                                   null)
                         ) as d
                 )
                 as figures
            from web.subsidy_definition sdc
           where sdc.definition_id = 'C0') as ad
         ) as c0,
         (select json_agg(d.*)
            from (select (abs(s.a1) + abs(s.a2) + abs(s.a3) + abs(s.b1) + abs(s.b2) + abs(s.b3) + abs(s.b4) + abs(s.b5) + abs(s.b6) + abs(s.b7) + abs(s.c1) + abs(s.c2) + abs(s.c3))::int as amount, 
                         (case when s.landed_value = 0 then null else ((abs(s.a1) + abs(s.a2) + abs(s.a3) + abs(s.b1) + abs(s.b2) + abs(s.b3) + abs(s.b4) + abs(s.b5) + abs(s.b6) + abs(s.b7) + abs(s.c1) + abs(s.c2) + abs(s.c3))/s.landed_value*100.00) end)::numeric(8,2) as perc_landed
                 ) as d
         ) as grand_total
    from (select distinct g.geo_entity_id, u.year 
            from web.geo_entity g, unnest(array[2000, 2009]) as u(year)
           where g.geo_entity_id > 0) sy
    join web.geo_entity ge on (ge.geo_entity_id = sy.geo_entity_id)
    left join geo_to_srm gts on (gts.geo_entity_id = sy.geo_entity_id)
    left join web.subsidy_ref_mapping srm on (srm.geo_entity_id = gts.srm_geo_entity_id)
    left join web.subsidy s on (s.geo_entity_id = sy.geo_entity_id and s.year = sy.year);

create or replace view web.v_geo_entity_with_eez as
with admin(geo_entity_id) as (
  select distinct ge.admin_geo_entity_id
    from web.geo_entity ge     
   where ge.geo_entity_id != 0
), 
ee(admin_geo_entity_id, admin_geo_name, eez) as (
select a.geo_entity_id, gea.name, 
       (select json_agg(g.*) 
          from (select ge.geo_entity_id as geo_entity_id, ge.name geo_name, e.eez_id, e.name eez_name
                  from web.geo_entity ge
                  join web.eez e on (e.geo_entity_id = ge.geo_entity_id)
                 where ge.admin_geo_entity_id = a.geo_entity_id
                 order by ge.geo_entity_id) as g)
  from admin a
  join web.geo_entity gea on (gea.geo_entity_id = a.geo_entity_id)
)
select *
  from ee
 where ee.eez is not null
 order by ee.admin_geo_entity_id;
 
create or replace view web.v_eez_fao_rfb
as
  with ee(eez_id, a_country_iso3) as (
    select e.eez_id, coalesce(c.fao_code, c.un_name)
      from web.eez e
      join web.geo_entity ge on (ge.geo_entity_id = e.geo_entity_id)
      join web.country c on (c.c_number = ge.legacy_admin_c_number)
  )
  select ee.eez_id, ee.a_country_iso3 country_iso3,
         (select json_agg(rf.*)
            from (select r.fid, r.acronym, r.name, r.profile_url as url
                    from fao.fao_country_rfb_membership fcrm
                    join fao.fao_rfb r on (r.fid = fcrm.rfb_fid)
                   where fcrm.country_iso3 = ee.a_country_iso3
                     and fcrm.membership_type = 'Full'
                   order by r.name) as rf
         ) as rfb
    from ee;

create or replace view web.v_rfmo_fao_contracting_country
as
  select r.rfmo_id, r.name, r.long_name,
         (select json_agg(rf.*)
            from (select fcrm.country_iso3 iso3, fcrm.country_name as name, fcrm.country_facp_url facp_url
                    from fao.fao_country_rfmo_membership fcrm
                   where fcrm.rfmo_id = r.rfmo_id
                   order by fcrm.country_name) as rf
         ) as contracting_country
    from web.rfmo r;

create or replace view web.v_meow_pdf
as 
select meow_id, json_agg(json_build_object(
'meow_id', meow_id,
'meow', meow,
'taxon_key', taxon_key,
'scientific_name',scientific_name,
'stock',stock,
'url', pdf_url)) as pdf
from meow_pdf
group by meow_id
order by meow_id	
/*
The command below should be maintained as the last command in this entire script.
*/
SELECT admin.grant_access();
