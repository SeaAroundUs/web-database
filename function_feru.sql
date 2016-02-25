create or replace function feru.populate_subsidy_for_year(i_for_year int) returns void as
$body$
  with sub(c_number, c_name, subsidy_values, landed_value) as (
    select c_number, min(country_name), array_agg(coalesce(re_est_subsidy, 0.0) order by type), sum(re_est_subsidy) 
      from feru.subsidy 
     group by c_number
  )
  insert into web.subsidy(geo_entity_id, country, c_number, landed_value, year, a1,a2,a3, b1,b2,b3,b4,b5,b6,b7, c1,c2,c3)
  select g.geo_entity_id, s.c_name, s.c_number, s.landed_value, i_for_year, 
         s.subsidy_values[1], s.subsidy_values[2], s.subsidy_values[3], s.subsidy_values[4], s.subsidy_values[5],
         s.subsidy_values[6], s.subsidy_values[7], s.subsidy_values[8], s.subsidy_values[9], s.subsidy_values[10],
         s.subsidy_values[11], s.subsidy_values[12], s.subsidy_values[13]
    from sub s
    join web.geo_entity g on (g.legacy_c_number = s.c_number);
$body$
language sql;

