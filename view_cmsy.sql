-- B/Bmsy not weighted by the catch
create materialized view cmsy.v_b_unweighted as
select vfd.main_area_id as eez_id, b.sciname, b.stock, vfd.taxon_key,
b.b_bmsy_5yr,
b.b_bmsy_3yr,
b.b_bmsy_1yr,
sum(b.catch_sum) stock_catch,
sum(vfd.catch_sum) eez_catch, b.percentage_eez_in_meow ,
(b.b_bmsy_5yr * b.percentage_eez_in_meow) B_5yr_with_area,
(b.b_bmsy_5yr) B_5yr_without_area,
(b.b_bmsy_3yr * b.percentage_eez_in_meow) B_3yr_with_area,
(b.b_bmsy_3yr) B_3yr_without_area,
(b.b_bmsy_1yr * b.percentage_eez_in_meow) B_1yr_with_area,
(b.b_bmsy_1yr ) as B_1yr_without_area
from web.v_fact_data vfd,
cmsy.v_b_bmsy_avg b
where vfd.taxon_key = b.taxon_key
and vfd.main_area_id = b.eez_id
and vfd.marine_layer_id = 1
group by vfd.main_area_id, b.sciname, b.stock, vfd.taxon_key, b.b_bmsy_5yr,b.percentage_eez_in_meow, b.b_bmsy_3yr, b.b_bmsy_1yr;

-- Count how many taxa have discards greater than 20%
create materialized view cmsy.v_discards_above_20 as
select p.eez_id, sum(vfd.catch_sum) as catch_sum,  count(p.taxon_key) as discards_count
from cmsy.v_discard_percentage p
inner join web.v_fact_data vfd on (vfd.main_area_id = p.eez_id and vfd.taxon_key = p.taxon_key)
where vfd.marine_layer_id = 1
where p.discard_percentage > .2
group by p.eez_id;

-- B/Bmsy average table
-- Summarize the B/Bmsy values from the outputfile by stock and meow and the percentage of eez in meow
create materialized view cmsy.v_b_bmsy_avg as
select mp.stock, mp.meow, mp.meow_id, a.sciname, cdt.taxon_key, a.subregion, mec.eez, mec.eez_id, mec.percentage_eez_in_meow, b.biomass/(max(a.bmsy::float)) as b_bmsy_5yr, c.biomass/(max(a.bmsy::float)) as b_bmsy_3yr, d.biomass/(max(a.bmsy::float)) as b_bmsy_1yr, sum(a.catch::float) catch_sum
from cmsy.outputfile a
left join web.cube_dim_taxon cdt on (a.sciname = cdt.scientific_name)
full join web.meow_pdf mp on (mp.stock = a.stock)
full join (select stock, sum(biomass_management)/5 biomass from cmsy.outputfile where year between 2010 and 2014 group by stock order by stock asc) as b
on( a.stock = b.stock)
full join (select stock, sum(biomass_management)/3 biomass from cmsy.outputfile where year between 2012 and 2014 group by stock order by stock asc) as c
on( a.stock = c.stock)
full join (select stock, sum(biomass_management) biomass from cmsy.outputfile where year = 2014 group by stock order by stock asc) as d
on( a.stock = d.stock)
full join web.meow_eez_combo mec on mec.meow = mp.meow
where a.year <= 2014
group by mp.stock, mp.meow, mp.meow_id, a.sciname,cdt.taxon_key, b.biomass, c.biomass, d.biomass,mec.eez_id, a.subregion, mec.eez, mec.percentage_eez_in_meow;

-- B/Bmsy weighted by the catch
create materialized view cmsy.v_b_weighted as
select vfd.main_area_id eez_id,b.stock, b.sciname, vfd.taxon_key, b.meow, b.meow_id,
b.b_bmsy_5yr,
b.b_bmsy_3yr,
b.b_bmsy_1yr,
sum(b.catch_sum) as stock_catch,
sum(vfd.catch_sum)* b.percentage_eez_in_meow eez_catch, b.percentage_eez_in_meow ,
(b.b_bmsy_5yr * sum(vfd.catch_sum) * b.percentage_eez_in_meow) as B_5yr_with_area,
(b.b_bmsy_5yr * sum(vfd.catch_sum)) as B_5yr_without_area,
(b.b_bmsy_3yr * sum(vfd.catch_sum) * b.percentage_eez_in_meow) as B_3yr_with_area,
(b.b_bmsy_3yr * sum(vfd.catch_sum)) as B_3yr_without_area,
(b.b_bmsy_1yr * sum(vfd.catch_sum) * b.percentage_eez_in_meow) as B_1yr_with_area,
(b.b_bmsy_1yr * sum(vfd.catch_sum)) as B_1yr_without_area
from web.v_fact_data vfd,
cmsy.v_b_bmsy_avg b
where vfd.taxon_key = b.taxon_key
and vfd.main_area_id = b.eez_id
and vfd.marine_layer_id = 1
group by b.stock, vfd.main_area_id, b.meow,b.meow_id, b.sciname, vfd.taxon_key, b.b_bmsy_5yr,b.percentage_eez_in_meow, b.b_bmsy_3yr, b.b_bmsy_1yr
order by main_area_id asc;

-- Sum of >600000 taxa catch by EEZ
create materialized view cmsy.v_eez_species_total as 
select vfd.main_area_id eez_id, sum(vfd.catch_sum) catch_total, count(distinct vfd.taxon_key) as species_count
from web.v_fact_data vfd
where taxon_key > 600000 and marine_layer_id = 1
group by vfd.main_area_id;

-- Sum of all taxa catch by EEZ
create materialized view cmsy.v_eez_total as 
select vfd.main_area_id eez_id, sum(vfd.catch_sum) catch_total, count(distinct vfd.taxon_key) as taxa_count
from web.v_fact_data vfd
where marine_layer_id = 1
group by vfd.main_area_id;

-- B by all taxa catch by EEZ summarized
create materialized view cmsy.v_b_summary_weighted_all_catch as 
select ee.name eez, sum(b.B_5yr_with_area) B_5yr_with_area,
sum(b.B_3yr_with_area) B_3yr_with_area,
sum(b.B_1yr_with_area) B_1yr_with_area,
sum(b.B_5yr_without_area) B_5yr_without_area,
sum(b.B_3yr_without_area) B_3yr_without_area,
sum(b.B_1yr_without_area) B_1yr_without_area,
e.catch_total as eez_catch
from cmsy.v_b_weighted b,
cmsy.v_eez_total e,
web.eez ee
where b.eez_id = e.eez_id
and ee.eez_id = b.eez_id
group by ee.name, e.species_total
order by eez asc;

-- B by species level taxa catch by EEZ summarized
create materialized view cmsy.v_b_summary_weighted_species_catch as 
select ee.name eez, sum(b.B_5yr_with_area) B_5yr_with_area,
sum(b.B_3yr_with_area) B_3yr_with_area,
sum(b.B_1yr_with_area) B_1yr_with_area,
sum(b.B_5yr_without_area) B_5yr_without_area,
sum(b.B_3yr_without_area) B_3yr_without_area,
sum(b.B_1yr_without_area) B_1yr_without_area,
e.catch_total as eez_catch
from cmsy.v_b_weighted b,
cmsy.v_eez_species_total e,
web.eez ee
where b.eez_id = e.eez_id
and ee.eez_id = b.eez_id
group by ee.name, e.species_total
order by eez asc;

-- B by all taxa catch by EEZ summarized
create materialized view cmsy.v_b_summary_unweighted_all_catch as 
select ee.name eez, sum(b.B_5yr_with_area) B_5yr_with_area,
sum(b.B_3yr_with_area) B_3yr_with_area,
sum(b.B_1yr_with_area) B_1yr_with_area,
sum(b.B_5yr_without_area) B_5yr_without_area,
sum(b.B_3yr_without_area) B_3yr_without_area,
sum(b.B_1yr_without_area) B_1yr_without_area,
count(b.sciname),
e.species_total as eez_catch
from cmsy.v_b_unweighted b,
cmsy.v_eez_total e,
web.eez ee
where b.eez_id = e.eez_id
and ee.eez_id = b.eez_id
group by ee.name, e.species_total
order by eez asc;

-- B by species level taxa catch by EEZ summarized
create materialized view cmsy.v_b_summary_unweighted_species_catch as 
select ee.name eez, sum(b.B_5yr_with_area) B_5yr_with_area,
sum(b.B_3yr_with_area) B_3yr_with_area,
sum(b.B_1yr_with_area) B_1yr_with_area,
sum(b.B_5yr_without_area) B_5yr_without_area,
sum(b.B_3yr_without_area) B_3yr_without_area,
sum(b.B_1yr_without_area) B_1yr_without_area,
e.species_total as eez_catch
from cmsy.v_b_unweighted b,
cmsy.v_eez_species_total e,
web.eez ee
where b.eez_id = e.eez_id
and ee.eez_id = b.eez_id
group by ee.name, e.species_total
order by eez asc;

-- B prime by species only catch (B/Bmsy (Weighted) / species only catch by EEZ)
create materialized view cmsy.v_b_prime_weighted_species_only_catch as 
select eez, (b.b_5yr_with_area/b.species_total) b_prime_5yr_with_area,
(b.b_3yr_with_area/b.species_total) b_prime_3yr_with_area,
(b.b_1yr_with_area/b.species_total) b_prime_1yr_with_area,
(b.b_5yr_without_area/b.species_total) b_prime_5yr_without_area,
(b.b_3yr_without_area/b.species_total) b_prime_3yr_without_area,
(b.b_1yr_without_area/b.species_total) b_prime_1yr_without_area
from cmsy.v_b_summary_weighted_species_catch b;

-- B prime by all catch (B/Bmsy (Weighted) / all catch by EEZ)
create materialized view cmsy.v_b_prime_weighted_all_catch as 
select eez, (b.b_5yr_with_area/b.species_total) b_prime_5yr_with_area,
(b.b_3yr_with_area/b.species_total) b_prime_3yr_with_area,
(b.b_1yr_with_area/b.species_total) b_prime_1yr_with_area,
(b.b_5yr_without_area/b.species_total) b_prime_5yr_without_area,
(b.b_3yr_without_area/b.species_total) b_prime_3yr_without_area,
(b.b_1yr_without_area/b.species_total) b_prime_1yr_without_area
from cmsy.v_b_summary_weighted_all_catch b;

-- B' unweighted
create materialized view cmsy.v_b_prime_unweighted as 
select b.eez_id, e.name eez, count(b.sciname) number_of_stocks_5yr, b3.stock_num number_of_stocks_3yr, b4.stock_num number_of_stocks_1yr,
sum(b.b_bmsy_5yr)/b2.stock_num as Bprime_5yr, sum(b.b_bmsy_3yr)/b3.stock_num as Bprime_3yr, sum(b.b_bmsy_1yr)/b4.stock_num as Bprime_1yr
from cmsy.v_b_unweighted b
inner join (select eez_id, count(sciname) stock_num from cmsy.v_b_unweighted  where catch > 1
and b_bmsy_5yr > 0 group by v_b_unweighted.eez_id) as b2 on b.eez_id = b2.eez_id
inner join (select eez_id, count(sciname) stock_num from cmsy.v_b_unweighted  where catch > 1
and b_bmsy_3yr > 0 group by v_b_unweighted.eez_id) as b3 on b.eez_id = b3.eez_id
inner join (select eez_id, count(sciname) stock_num from cmsy.v_b_unweighted  where catch > 1
and b_bmsy_1yr > 0 group by v_b_unweighted.eez_id) as b4 on b.eez_id = b4.eez_id
inner join web.eez e on e.eez_id = b.eez_id
where b.catch > 1
and b.b_bmsy_5yr > 0
group by b.eez_id, b2.stock_num, b3.stock_num, b4.stock_num, e.name;


-- CMSY Assessment Summary
-- Genus level catch
select main_area_id, count(distinct taxon_key), sum(catch_sum)
from web.v_fact_data vfd
where marine_layer_id = 1
and taxon_key between 500000 and 599999
group by main_area_id;

-- Species level total catch
select main_area_id, count(distinct taxon_key), sum(catch_sum)
from web.v_fact_data vfd
where marine_layer_id = 1
and taxon_key > 600000
group by main_area_id;

-- Species level catch excluding discards
select main_area_id, count(distinct taxon_key), sum(catch_sum)
from web.v_fact_data vfd
where marine_layer_id = 1
and taxon_key > 600000
and catch_type_id = 1
group by main_area_id;

-- Filter eez by taxon where discards are less than or equal to 20%
create materialized view cmsy.v_eez_exclude_discards_above_20 as
select vfd.main_area_id, vfd.taxon_key, sum(vfd.catch_sum) as catch_sum, count(p.taxon_key) as discards_count
from cmsy.v_discard_percentage p
inner join web.v_fact_data vfd on (vfd.main_area_id = p.eez_id and vfd.taxon_key = p.taxon_key)
where vfd.marine_layer_id = 1
and p.discard_percentage <= .2
group by vfd.main_area_id, vfd.taxon_key;

-- Top 90% of catch of an eez with taxon key
-- calculate the contribution of each species in the eez by dividing individual species catch with sum of total species catch for a given eez
create materialized view cmsy.v_top_90_percent_species_by_catch as 
with t1(eez_id, taxon_key, percentage) as 
(select e.main_area_id, e.taxon_key, (e.catch_sum/e1.catch_sum)::float as percentage, e.catch_sum
from cmsy.v_eez_exclude_discards_above_20 e,
(select main_area_id, sum(catch_sum) catch_sum
from cmsy.v_eez_exclude_discards_above_20 e group by main_area_id) as e1
where e1.main_area_id = e.main_area_id
order by main_area_id,percentage desc),
-- add a running total for the percentages by each eez
t2 as 
(select eez_id, taxon_key, percentage, sum(percentage) over (partition by eez_id order by eez_id,percentage desc, 1) as running_total, catch_sum
from t1
order by eez_id, percentage desc)
-- select species where the running total of the percent contribution is less than 0.9 (90%)
(select *
from t2 
where running_total <= .9
union
-- to account for the percentage being less than 0.9, find the next species which will bring the contribution to just above 0.9.
-- filter the t2 by entries with a running total > 0.9 and then find the mininum amount which will represent the next species
select t2.eez_id, t2.taxon_key, t2.percentage as percent_catch_contrib, t2.running_total, t2.catch_sum
from t2,
(select eez_id, min(running_total) as running_total
from t2
where running_total > .9
group by eez_id) as t3
where t2.eez_id = t3.eez_id and t2.running_total = t3.running_total
group by t2.eez_id, t2.taxon_key, t2.percentage, t2.running_total, t2.catch_sum)
order by t2.eez_id, t2.percentage desc;

-- summary of straddling stocks
create materialized view  cmsy.v_straddling_stocks as
with temp as(
select u.eez_id, u.taxon_key, straddling , sum(u.eez_catch) eez_catch
from cmsy.v_b_unweighted u
inner join (select stock,taxon_key, count(distinct meow) as straddling
from cmsy.v_b_bmsy_averages where taxon_key > 600000 and stock is not null
group by stock, taxon_key) as ba
on ba.taxon_key = u.taxon_key and u.stock = ba.stock
--where ba.straddling > 1
group by u.eez_id, u.taxon_key, straddling
)
select eez_id, taxon_key, max(straddling) straddling ,max(eez_catch) eez_catch
from temp
group by eez_id, taxon_key

--
create materialized view cmsy.v_assessment_summary as 
select e.eez_id, e.name eez,nei_count, nei_catch, family_order_class_count, family_order_class_catch, genera_count, genera_catch, species_total_count, species_total_catch, top_90_species_count, top_90_species_catch, d."count" excluded_discard_species_count,
straddling_stocks_count, straddling_stocks_catch, local_stocks_count, local_stocks_catch, total_assessed_count, total_assessed_catch, un.bprime_3yr b_prime_unweighted_3yr, un.bprime_1yr b_prime_unweighted_1yr, w.b_prime_3yr_with_area b_prime_weighted_3yr, w.b_prime_1yr_with_area b_prime_weighted_1yr
--total_assessed_count/top_90_species_count 'percent_count_assessed(90%)', total_assessed_catch/top_90_species_catch 'percent_catch_assessed(90%)',
--d.count 'excluded_species_discards_count(>20%)' 
from web.eez e 
-- Not elsewhere identified (nei)
left join 
  (select main_area_id, count(distinct taxon_key) nei_count, sum(catch_sum) nei_catch
  from web.v_fact_data vfd
  where marine_layer_id = 1
  and taxon_key between 100000 and 199999
  group by main_area_id) as nei 
on nei.main_area_id = e.eez_id
-- Family, Order, Class
left join 
  (select main_area_id, count(distinct taxon_key) family_order_class_count, sum(catch_sum) family_order_class_catch
  from web.v_fact_data vfd
  where marine_layer_id = 1
  and taxon_key between 200000 and 499999
  group by main_area_id) as family_order_class 
on family_order_class.main_area_id = e.eez_id
-- Genera level total catch
left join 
  (select main_area_id, count(distinct taxon_key) genera_count, sum(catch_sum) genera_catch
  from web.v_fact_data vfd
  where marine_layer_id = 1
  and taxon_key between 500000 and 599999
  group by main_area_id) as genera 
on genera.main_area_id = e.eez_id
-- Species level total catch
left join
  (select main_area_id, count(distinct taxon_key) species_total_count, sum(catch_sum) species_total_catch
  from web.v_fact_data vfd
  where marine_layer_id = 1
  and taxon_key > 600000
  group by main_area_id) as species_total
on species_total.main_area_id = e.eez_id
-- Top 90% species level catch excluding discards above 20%
left join
  (select eez_id, count(taxon_key) top_90_species_count, sum(catch_sum) top_90_species_catch
  from cmsy.v_top_90_percent_species_by_catch
  group by eez_id) as t90
on t90.eez_id = e.eez_id
-- Assessed straddling stocks catch
left join 
  (select eez_id, count(taxon_key) straddling_stocks_count, sum(eez_catch) straddling_stocks_catch from straddling_stocks
  where straddling > 1
  group by eez_id) as straddling
on straddling.eez_id = e.eez_id
-- Assessed non-straddling stocks catch
left join 
  (select eez_id, count(taxon_key) local_stocks_count, sum(eez_catch) local_stocks_catch from straddling_stocks
  where straddling = 1
  group by eez_id) as local
on local.eez_id = e.eez_id
-- Total assessed stocks catch
left join 
  (select eez_id, count(taxon_key) total_assessed_count, sum(eez_catch) total_assessed_catch from straddling_stocks
  group by eez_id) as total_assessed
on total_assessed.eez_id = e.eez_id
-- discards above 20
left join cmsy.v_discards_above_20 d on d.main_area_id = e.eez_id
-- B' unweighted
left join cmsy.v_b_prime_unweighted un on un.eez_id = e.eez_id
-- B' weighted
left join cmsy.v_b_prime_weighted_all_catch w on w.eez = e.name
where e.eez_id not in (0, 999)




--Added views for CMSY
--M.Nevado
--8.6.2020

--v_biomass_window
CREATE OR REPLACE VIEW cmsy.v_biomass_window
AS WITH mini(stock_description, year, biomass_window) AS (
         SELECT b.stock_description,
            b.year,
            min(b.biomass_window) AS bw_lower
           FROM cmsy.raw_biomass_window b
          GROUP BY b.stock_description, b.year
        ), maxi(stock_description, year, biomass_window) AS (
         SELECT b.stock_description,
            b.year,
            max(b.biomass_window) AS bw_upper
           FROM cmsy.raw_biomass_window b
          GROUP BY b.stock_description, b.year
        ), main(stock_description, year, bw_lower, bw_upper) AS (
         SELECT mi.stock_description,
            mi.year,
            mi.biomass_window AS bw_lower,
            mx.biomass_window AS bw_upper
           FROM mini mi
             JOIN maxi mx ON mi.stock_description::text = mx.stock_description::text AND mi.year = mx.year
        )
 SELECT s.stock_id,
    m.stock_description,
    m.year,
    m.bw_lower,
    m.bw_upper
   FROM main m
     JOIN cmsy.stock s ON m.stock_description::text = s.stock_description::text
  WHERE s.is_active = true;


--v_catch_input
CREATE OR REPLACE VIEW cmsy.v_catch_input
AS SELECT t.ref_id,
    t.stock_name,
    t.year,
    t.catch,
    t.biomass,
    t.date_ref
   FROM ( SELECT ci.ref_id,
            ci.stock_name,
            ci.year,
            ci.catch,
            ci.biomass,
            ci.date_ref,
            row_number() OVER (PARTITION BY ci.stock_name, ci.year ORDER BY ci.date_ref DESC) AS r
           FROM cmsy.raw_catch_id ci) t
  WHERE t.r = 1;


--v_cmsy_ref
CREATE OR REPLACE VIEW cmsy.v_cmsy_ref
AS SELECT concat(ma.main_area_id, si.taxon_key) AS id,
    array_accum(ARRAY[r.pdf_file]) AS "values"
   FROM cmsy.stock si
     JOIN cmsy.ref_content rc ON si.stock_id::text = rc.stock_id::text
     JOIN cmsy.reference r ON rc.ref_id = r.ref_id
     JOIN cmsy.stock_marine_area ma ON si.stock_id::text = ma.stock_id::text
  WHERE ma.marine_layer_id = 19 AND si.is_active = true
  GROUP BY ma.main_area_id, si.taxon_key;


--v_eez_species_total
CREATE OR REPLACE VIEW cmsy.v_eez_species_total
AS SELECT vfd.main_area_id AS eez,
    count(DISTINCT vfd.taxon_key) AS count,
    sum(vfd.catch_sum) AS sum
   FROM v_fact_data vfd
  WHERE vfd.marine_layer_id = 1 AND vfd.taxon_key > 600000
  GROUP BY vfd.main_area_id;


--v_me_species_total
CREATE OR REPLACE VIEW cmsy.v_me_species_total
AS SELECT b.eez,
    b.eez_id,
    count(DISTINCT b.taxon_key) AS count,
    sum(b.catch_sum) AS sum
   FROM cmsy.b_bmsy_averages b
  GROUP BY b.eez, b.eez_id;


--v_msy
CREATE OR REPLACE VIEW cmsy.v_msy
AS SELECT msy.cmsy_graph_id::integer AS id,
    msy.meow AS key,
    msy.scientific_name AS s_name,
    msy.common_name AS c_name,
    array_accum(ARRAY[ARRAY[msy.year::numeric, msy.catch::numeric(20,3), msy.msy::numeric(20,3), msy.lower_msy::numeric(20,3), msy.upper_msy::numeric(20,3), msy.biomass::numeric(20,3), msy.bmsy::numeric(20,3), msy.halfbmsy::numeric(20,3), msy.lower_bmsy::numeric(20,3), msy.upper_bmsy::numeric(20,3), msy.exploitation::numeric(20,3), msy.fmsy::numeric(20,3), msy.lower_fmsy::numeric(20,3), msy.upper_fmsy::numeric(20,3), msy.bw_lower::numeric(20,3), msy.bw_upper::numeric(20,3), msy.b_cpue::numeric(20,3), msy.b_lower_cpue::numeric(20,3), msy.b_upper_cpue::numeric(20,3), msy.f_cpue::numeric(20,3), msy.f_lower_cpue::numeric(20,3), msy.f_upper_cpue::numeric(20,3), msy.uncertainty_score::numeric(20,3)]] ORDER BY msy.year) AS "values"
   FROM cmsy.mv_output_bmsy msy
  GROUP BY msy.cmsy_graph_id, msy.meow, msy.scientific_name, msy.common_name
  ORDER BY msy.common_name, msy.scientific_name;


--v_stock_id_reference
CREATE OR REPLACE VIEW cmsy.v_stock_id_reference
AS WITH base(stock_name, scientific_name, marine_layer_id, main_area_id, meow_id) AS (
         SELECT s.stock_name,
            o_1.sciname,
            s.marine_layer_id,
            s.main_area_id,
            s.meow_id
           FROM cmsy.stock_marine_area s
             JOIN cmsy.raw_outputfile o_1 ON s.stock_name::text = o_1.stock::text
        ), stock_name(stock_name, taxon_key, scientific_name, common_name, marine_layer_id, main_area_id, meow_id) AS (
         SELECT DISTINCT b.stock_name,
            c.taxon_key,
            c.scientific_name,
            c.common_name,
            b.marine_layer_id,
            b.main_area_id,
            b.meow_id
           FROM base b
             JOIN cube_dim_taxon c ON c.scientific_name::text = b.scientific_name::text
        ), main(stock_name, stock_id_area, taxon_kay, scientific_name, common_name) AS (
         SELECT DISTINCT s.stock_name,
            concat(s.taxon_key, '_', s.marine_layer_id, '_', s.main_area_id) AS stock_id_area,
            s.taxon_key,
            s.scientific_name,
            s.common_name
           FROM stock_name s
        )
 SELECT DISTINCT m.stock_name,
    concat(m.common_name, ' in ', o.subregion) AS stock_description,
    m.stock_id_area,
    m.taxon_kay,
    m.scientific_name
   FROM main m
     JOIN cmsy.raw_outputfile o ON m.stock_name::text = o.stock::text;


--v_stock_inuput
CREATE OR REPLACE VIEW cmsy.v_stock_input
AS SELECT t.region,
    t.subregion,
    t.stock_name,
    t."group",
    t.stock_description,
    t.englishname,
    t.scientific_name,
    t.resilience_source,
    t.r_source,
    t.cpue_source,
    t.biomass_window_source,
    t.stock_resource,
    t.minofyear,
    t.maxofyear,
    t.startyear,
    t.endyear,
    t.resilience,
    t.r_low,
    t.r_hi,
    t.stb_low,
    t.stb_hi,
    t.int_yr,
    t.intb_low,
    t.intb_hi,
    t.endb_low,
    t.endb_hi,
    t.q_start,
    t.q_end,
    t.btype,
    t.e_creep,
    t.force_cmsy,
    t.comment,
    t.notes,
    t.date_ref
   FROM ( SELECT si.region,
            si.subregion,
            si.stock_name,
            si."group",
            si.stock_description,
            si.englishname,
            si.scientific_name,
            si.resilience_source,
            si.r_source,
            si.cpue_source,
            si.biomass_window_source,
            si.stock_resource,
            si.minofyear,
            si.maxofyear,
            si.startyear,
            si.endyear,
            si.resilience,
            si.r_low,
            si.r_hi,
            si.stb_low,
            si.stb_hi,
            si.int_yr,
            si.intb_low,
            si.intb_hi,
            si.endb_low,
            si.endb_hi,
            si.q_start,
            si.q_end,
            si.btype,
            si.e_creep,
            si.force_cmsy,
            si.comment,
            si.notes,
            si.date_ref,
            row_number() OVER (PARTITION BY si.subregion, si.stock_name, si."group", si.stock_description, si.scientific_name ORDER BY si.date_ref DESC) AS r
           FROM cmsy.raw_stock_id si) t
  WHERE t.r = 1;


--v_stock_meow_reference
CREATE OR REPLACE VIEW cmsy.v_stock_meow_reference
AS SELECT smr.meow_id,
    json_agg(json_build_object('meow_id', smr.meow_id, 'meow', me.name, 'taxon_key', st.taxon_key, 'scientific_name', cdt.scientific_name, 'stock', st.stock_name, 'url', smr.pdf_url, 'common_name', cdt.common_name, 'group_type', smr.group_type, 'graph_url', smr.graph_url)) AS pdf
   FROM cmsy.stock_meow_reference smr
     JOIN meow me ON me.meow_id = smr.meow_id
     JOIN cmsy.stock st ON smr.stock_id::text = st.stock_id::text
     JOIN cube_dim_taxon cdt ON st.taxon_key = cdt.taxon_key
  GROUP BY smr.meow_id
  ORDER BY smr.meow_id;


--v_stock_strad
CREATE OR REPLACE VIEW cmsy.v_stock_strad
AS SELECT s.stock_id,
    s.stock_description,
    s.stock_num,
    s.taxon_key,
    s.is_stradling,
    s.is_active,
    s.date_modified
   FROM cmsy.stock s
  WHERE s.is_stradling = true;







--Added materialized views for CMSY
--M.Nevado
--8.6.2020

--b_bmsy_averages
CREATE MATERIALIZED VIEW cmsy.b_bmsy_averages
AS SELECT mp.stock_name,
    me.name AS meow,
    mp.meow_id,
    a.sciname,
    cdt.taxon_key,
    a.subregion,
    mec.eez,
    mec.eez_id,
    mec.percentage_eez_in_meow,
    b.biomass / max(a.bmsy) AS b_bmsy_5yr,
    c.biomass / max(a.bmsy) AS b_bmsy_3yr,
    d.biomass / max(a.bmsy) AS b_bmsy_1yr,
    sum(a.catch::double precision) AS catch_sum
   FROM cmsy.raw_outputfile a
     FULL JOIN cube_dim_taxon cdt ON a.sciname::text = cdt.scientific_name::text
     FULL JOIN cmsy.stock_meow_reference mp ON mp.stock_name::text = a.stock::text
     FULL JOIN ( SELECT raw_outputfile.stock,
            sum(raw_outputfile.biomass_management) / 5::double precision AS biomass
           FROM cmsy.raw_outputfile
          WHERE raw_outputfile.year >= 2010 AND raw_outputfile.year <= 2014
          GROUP BY raw_outputfile.stock
          ORDER BY raw_outputfile.stock) b ON a.stock::text = b.stock::text
     FULL JOIN ( SELECT raw_outputfile.stock,
            sum(raw_outputfile.biomass_management) / 3::double precision AS biomass
           FROM cmsy.raw_outputfile
          WHERE raw_outputfile.year >= 2012 AND raw_outputfile.year <= 2014
          GROUP BY raw_outputfile.stock
          ORDER BY raw_outputfile.stock) c ON a.stock::text = c.stock::text
     FULL JOIN ( SELECT raw_outputfile.stock,
            sum(raw_outputfile.biomass_management) AS biomass
           FROM cmsy.raw_outputfile
          WHERE raw_outputfile.year = 2014
          GROUP BY raw_outputfile.stock
          ORDER BY raw_outputfile.stock) d ON a.stock::text = d.stock::text
     FULL JOIN meow me ON me.meow_id = mp.meow_id
     FULL JOIN meow_eez_combo mec ON mec.meow::text = me.name::text
  WHERE a.catch::text <> 'NA'::text
  GROUP BY mp.stock_name, me.name, mp.meow_id, a.sciname, cdt.taxon_key, b.biomass, c.biomass, d.biomass, mec.eez_id, a.subregion, mec.eez, mec.percentage_eez_in_meow;


--materialized view b_unweighted2
CREATE MATERIALIZED VIEW cmsy.b_unweighted2
AS SELECT vfd.main_area_id AS eez_id,
    b.sciname,
    vfd.taxon_key,
    b.b_bmsy_5yr,
    b.b_bmsy_3yr,
    b.b_bmsy_1yr,
    sum(b.catch_sum) AS stock_catch,
    sum(vfd.catch_sum) AS eez_catch,
    b.percentage_eez_in_meow,
    b.b_bmsy_5yr * b.percentage_eez_in_meow AS b_5yr_with_area,
    b.b_bmsy_5yr AS b_5yr_without_area,
    b.b_bmsy_3yr * b.percentage_eez_in_meow AS b_3yr_with_area,
    b.b_bmsy_3yr AS b_3yr_without_area,
    b.b_bmsy_1yr * b.percentage_eez_in_meow AS b_1yr_with_area,
    b.b_bmsy_1yr AS b_1yr_without_area
   FROM v_fact_data vfd,
    cmsy.b_bmsy_averages b
  WHERE vfd.taxon_key = b.taxon_key AND vfd.main_area_id = b.eez_id AND vfd.marine_layer_id = 1
  GROUP BY vfd.main_area_id, b.sciname, vfd.taxon_key, b.b_bmsy_5yr, b.percentage_eez_in_meow, b.b_bmsy_3yr, b.b_bmsy_1yr;

--materialized view b_unweighted3
CREATE MATERIALIZED VIEW cmsy.b_unweighted3
AS SELECT vfd.main_area_id AS eez_id,
    b.sciname,
    b.stock_name,
    vfd.taxon_key,
    b.b_bmsy_5yr,
    b.b_bmsy_3yr,
    b.b_bmsy_1yr,
    sum(b.catch_sum) AS stock_catch,
    sum(vfd.catch_sum) AS eez_catch,
    b.percentage_eez_in_meow,
    b.b_bmsy_5yr * b.percentage_eez_in_meow AS b_5yr_with_area,
    b.b_bmsy_5yr AS b_5yr_without_area,
    b.b_bmsy_3yr * b.percentage_eez_in_meow AS b_3yr_with_area,
    b.b_bmsy_3yr AS b_3yr_without_area,
    b.b_bmsy_1yr * b.percentage_eez_in_meow AS b_1yr_with_area,
    b.b_bmsy_1yr AS b_1yr_without_area
   FROM v_fact_data vfd,
    cmsy.b_bmsy_averages b
  WHERE vfd.taxon_key = b.taxon_key AND vfd.main_area_id = b.eez_id AND vfd.marine_layer_id = 1
  GROUP BY vfd.main_area_id, b.sciname, b.stock_name, vfd.taxon_key, b.b_bmsy_5yr, b.percentage_eez_in_meow, b.b_bmsy_3yr, b.b_bmsy_1yr;


--materialized view discard_percentage
CREATE MATERIALIZED VIEW cmsy.discard_percentage
AS SELECT DISTINCT vfd.main_area_id,
    vfd.taxon_key,
    COALESCE(temp2.discard_catch / temp1.total_catch, 0::numeric) AS discard_percentage
   FROM v_fact_data vfd
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS total_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 1 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp1 ON vfd.main_area_id = temp1.main_area_id AND vfd.taxon_key = temp1.taxon_key
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS discard_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 1 AND v_fact_data.catch_type_id = 2 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp2 ON vfd.main_area_id = temp2.main_area_id AND vfd.taxon_key = temp2.taxon_key
  WHERE vfd.marine_layer_id = 1 AND vfd.taxon_key > 600000;


--materialized view discard_percentage_meow
CREATE MATERIALIZED VIEW cmsy.discard_percentage_meow
AS SELECT DISTINCT vfd.main_area_id,
    vfd.taxon_key,
    COALESCE(temp2.discard_catch / temp1.total_catch, 0::numeric) AS discard_percentage
   FROM v_fact_data vfd
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS total_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp1 ON vfd.main_area_id = temp1.main_area_id AND vfd.taxon_key = temp1.taxon_key
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS discard_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.catch_type_id = 2
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp2 ON vfd.main_area_id = temp2.main_area_id AND vfd.taxon_key = temp2.taxon_key
  WHERE vfd.marine_layer_id = 19;


--materialized view discard_percentage_meow_species_level
CREATE MATERIALIZED VIEW cmsy.discard_percentage_meow_species_level
AS SELECT DISTINCT vfd.main_area_id,
    vfd.taxon_key,
    COALESCE(temp2.discard_catch / temp1.total_catch, 0::numeric) AS discard_percentage
   FROM v_fact_data vfd
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS total_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp1 ON vfd.main_area_id = temp1.main_area_id AND vfd.taxon_key = temp1.taxon_key
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS discard_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.catch_type_id = 2 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp2 ON vfd.main_area_id = temp2.main_area_id AND vfd.taxon_key = temp2.taxon_key
  WHERE vfd.marine_layer_id = 19 AND vfd.taxon_key > 600000;


--materialized view discards_above_20_meow
CREATE MATERIALIZED VIEW cmsy.discards_above_20_meow
AS SELECT d.main_area_id,
    count(d.taxon_key) AS count
   FROM cmsy.discard_percentage_meow d
  WHERE d.discard_percentage > 0.2
  GROUP BY d.main_area_id;


--materialized view discards_above_20_meow_species_level
CREATE MATERIALIZED VIEW cmsy.discards_above_20_meow_species_level
AS SELECT d.main_area_id,
    count(d.taxon_key) AS count
   FROM cmsy.discard_percentage_meow_species_level d
  WHERE d.discard_percentage > 0.2
  GROUP BY d.main_area_id;


--materialized view eez_exclude_discards_above_20
CREATE MATERIALIZED VIEW cmsy.eez_exclude_discards_above_20
AS SELECT vfd.main_area_id,
    vfd.taxon_key,
    sum(vfd.catch_sum) AS catch_sum
   FROM cmsy.discard_percentage p
     JOIN v_fact_data vfd ON vfd.main_area_id = p.main_area_id AND vfd.taxon_key = p.taxon_key
  WHERE vfd.marine_layer_id = 1 AND p.discard_percentage < 0.2
  GROUP BY vfd.main_area_id, vfd.taxon_key;


--materialied view eez_species_total
CREATE MATERIALIZED VIEW cmsy.eez_species_total
AS SELECT vfd.main_area_id AS eez_id,
    sum(vfd.catch_sum) AS species_total
   FROM v_fact_data vfd
  WHERE vfd.taxon_key > 600000 AND vfd.marine_layer_id = 1
  GROUP BY vfd.main_area_id;


--materialized view eez_total
CREATE MATERIALIZED VIEW cmsy.eez_total
AS SELECT vfd.main_area_id AS eez_id,
    sum(vfd.catch_sum) AS species_total
   FROM v_fact_data vfd
  WHERE vfd.marine_layer_id = 1
  GROUP BY vfd.main_area_id;


--materialized view mv_catch_reliability_score
CREATE MATERIALIZED VIEW cmsy.mv_catch_reliability_score
AS WITH base(marine_layer_id, main_area_id, taxon_key, year, sector_type_id, score, total_catch) AS (
         SELECT v_fact_data.marine_layer_id,
            v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            v_fact_data.year,
            v_fact_data.sector_type_id,
            v_fact_data.score,
            v_fact_data.catch_sum
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19
          GROUP BY v_fact_data.marine_layer_id, v_fact_data.main_area_id, v_fact_data.taxon_key, v_fact_data.year, v_fact_data.sector_type_id, v_fact_data.score, v_fact_data.catch_sum
        ), main(marine_layer_id, main_area_id, taxon_key, year, sum_total_catch, total_catch_x_score, weighted_score) AS (
         SELECT b.marine_layer_id,
            b.main_area_id,
            b.taxon_key,
            b.year,
            sum(b.total_catch) AS sum,
            sum(b.total_catch * b.score::numeric) AS sum,
            sum(b.total_catch * b.score::numeric) / sum(b.total_catch)
           FROM base b
          GROUP BY b.marine_layer_id, b.main_area_id, b.taxon_key, b.year
        ), uncert(cmsy_graph_id, marine_layer_id, main_area_id, taxon_key, year, total_catch_x_score, sum_total_catch, weighted_score) AS (
         SELECT m.main_area_id::text || m.taxon_key::text AS cmsy_graph_id,
            m.marine_layer_id,
            m.main_area_id,
            m.taxon_key,
            m.year,
            m.total_catch_x_score,
            m.sum_total_catch,
            round(m.total_catch_x_score / m.sum_total_catch, 2) AS w_score
           FROM main m
          GROUP BY m.marine_layer_id, m.main_area_id, m.taxon_key, m.year, m.sum_total_catch, m.total_catch_x_score
        )
 SELECT u.cmsy_graph_id,
    u.year,
    u.weighted_score
   FROM uncert u;


--materialized view mv_output_bmsy
CREATE MATERIALIZED VIEW cmsy.mv_output_bmsy
AS WITH base(cmsy_graph_id, meow, stock_name, stock_description, scientific_name, common_name, year, catch, msy, lower_msy, upper_msy, exploitation, fmsy, lower_fmsy, upper_fmsy, biomass, bmsy, halfbmsy, lower_bmsy, upper_bmsy, b_cpue, b_lower_cpue, b_upper_cpue, f_cpue, f_lower_cpue, f_upper_cpue) AS (
         SELECT concat(mp.meow_id, mp.taxon_key) AS stock_id,
            mp.meow,
            op.stock AS stock_name,
            op."Name" AS stock_description,
            op.sciname AS scientific_name,
            cd.common_name,
            op.year,
            op.catch,
            op.msy,
            op.msy_lcl AS lower_msy,
            op.msy_ucl AS upper_msy,
            op.f_fmsy_management AS exploitation,
            1 AS fmsy,
            op.f_fm_lcl AS lower_fmsy,
            op.f_fm_ucl AS upper_fmsy,
            op.biomass_management AS biomass,
            op.bmsy,
            NULL::double precision AS halfbmsy,
            op.bm_lcl AS lower_bmsy,
            op.bm_ucl AS upper_bmsy,
            op.cpue_biomass AS b_cpue,
            op.cpue_lcl AS b_lower_cpue,
            op.cpue_ucl AS b_upper_cpue,
            NULL::double precision AS f_cpue,
            NULL::double precision AS f_lower_cpue,
            NULL::double precision AS f_upper_cpue
           FROM cmsy.raw_outputfile op
             JOIN cube_dim_taxon cd ON op.sciname::text = cd.scientific_name::text
             LEFT JOIN stock_meow_reference mp ON op.stock::text = mp.stock_name::text
          WHERE op.year < 2015 AND op.catch::text <> 'NA'::text AND (op.stock::text IN ( SELECT DISTINCT mpt.stock_name AS stock
                   FROM stock_meow_reference mpt))
        )
 SELECT b.cmsy_graph_id,
    b.meow,
    b.stock_name,
    b.stock_description,
    b.scientific_name,
    b.common_name,
    b.year,
    b.catch,
    b.msy,
    b.lower_msy,
    b.upper_msy,
    b.exploitation,
    b.fmsy,
    b.lower_fmsy,
    b.upper_fmsy,
    b.biomass,
    b.bmsy,
    b.halfbmsy,
    b.lower_bmsy,
    b.upper_bmsy,
    bw.bw_lower,
    bw.bw_upper,
    b.b_cpue,
    b.b_lower_cpue,
    b.b_upper_cpue,
    b.f_cpue,
    b.f_lower_cpue,
    b.f_upper_cpue,
    crs.weighted_score AS uncertainty_score
   FROM base b
     LEFT JOIN cmsy.mv_catch_reliability_score crs ON crs.cmsy_graph_id = b.cmsy_graph_id AND crs.year = b.year
     LEFT JOIN cmsy.v_biomass_window bw ON bw.stock_description::text = b.stock_description::text AND bw.year = b.year
  ORDER BY b.year, b.cmsy_graph_id;


--materialized view top_90_percent_species_by_catch
CREATE MATERIALIZED VIEW cmsy.top_90_percent_species_by_catch
AS WITH t1(eez_id, taxon_key, percentage) AS (
         SELECT e.main_area_id,
            e.taxon_key,
            (e.catch_sum / e1.catch_sum)::double precision AS percentage,
            e.catch_sum
           FROM cmsy.eez_exclude_discards_above_20 e,
            ( SELECT e_1.main_area_id,
                    sum(e_1.catch_sum) AS catch_sum
                   FROM cmsy.eez_exclude_discards_above_20 e_1
                  GROUP BY e_1.main_area_id) e1
          WHERE e1.main_area_id = e.main_area_id
          ORDER BY e.main_area_id, ((e.catch_sum / e1.catch_sum)::double precision) DESC
        ), t2 AS (
         SELECT t1.eez_id,
            t1.taxon_key,
            t1.percentage,
            sum(t1.percentage) OVER (PARTITION BY t1.eez_id ORDER BY t1.eez_id, t1.percentage DESC, 1::integer) AS running_total,
            t1.catch_sum
           FROM t1
          ORDER BY t1.eez_id, t1.percentage DESC
        )
 SELECT t2.eez_id,
    t2.taxon_key,
    t2.percentage,
    t2.running_total,
    t2.catch_sum
   FROM t2
  WHERE t2.running_total <= 0.9::double precision
UNION
 SELECT t2.eez_id,
    t2.taxon_key,
    t2.percentage,
    t2.running_total,
    t2.catch_sum
   FROM t2,
    ( SELECT t2_1.eez_id,
            min(t2_1.running_total) AS running_total
           FROM t2 t2_1
          WHERE t2_1.running_total > 0.9::double precision
          GROUP BY t2_1.eez_id) t3
  WHERE t2.eez_id = t3.eez_id AND t2.running_total = t3.running_total
  GROUP BY t2.eez_id, t2.taxon_key, t2.percentage, t2.running_total, t2.catch_sum;


--materialized view v_me_discard_percentage
CREATE MATERIALIZED VIEW cmsy.v_me_discard_percentage
AS SELECT DISTINCT vfd.main_area_id AS meow_id,
    vfd.taxon_key,
    COALESCE(temp2.discard_catch / temp1.total_catch, 0::numeric) AS discard_percentage
   FROM v_fact_data vfd
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS total_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp1 ON vfd.main_area_id = temp1.main_area_id AND vfd.taxon_key = temp1.taxon_key
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS discard_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.catch_type_id = 2 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp2 ON vfd.main_area_id = temp2.main_area_id AND vfd.taxon_key = temp2.taxon_key
  WHERE vfd.marine_layer_id = 19 AND vfd.taxon_key > 600000;


--materialized view v_me_discard_percentage_2
CREATE MATERIALIZED VIEW cmsy.v_me_discard_percentage_2
AS SELECT DISTINCT vfd.main_area_id AS meow_id,
    vfd.taxon_key,
    COALESCE(temp2.discard_catch / temp1.total_catch, 0::numeric) AS discard_percentage,
    sum(vfd.catch_sum) AS catch_sum
   FROM v_fact_data vfd
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS total_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp1 ON vfd.main_area_id = temp1.main_area_id AND vfd.taxon_key = temp1.taxon_key
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS discard_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.catch_type_id = 2 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp2 ON vfd.main_area_id = temp2.main_area_id AND vfd.taxon_key = temp2.taxon_key
  WHERE vfd.marine_layer_id = 19 AND vfd.taxon_key > 600000 AND vfd.year > 1989
  GROUP BY vfd.main_area_id, vfd.taxon_key, temp2.discard_catch, temp1.total_catch;


--materialized view v_me_discard_percentage_3
CREATE MATERIALIZED VIEW cmsy.v_me_discard_percentage_3
AS SELECT DISTINCT vfd.main_area_id AS meow_id,
    vfd.taxon_key,
    COALESCE(temp2.discard_catch / temp1.total_catch, 0::numeric) AS discard_percentage,
    sum(vfd.catch_sum) AS catch_sum
   FROM v_fact_data vfd
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS total_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp1 ON vfd.main_area_id = temp1.main_area_id AND vfd.taxon_key = temp1.taxon_key
     LEFT JOIN ( SELECT v_fact_data.main_area_id,
            v_fact_data.taxon_key,
            sum(v_fact_data.catch_sum) AS discard_catch
           FROM v_fact_data
          WHERE v_fact_data.marine_layer_id = 19 AND v_fact_data.catch_type_id = 2 AND v_fact_data.taxon_key > 600000
          GROUP BY v_fact_data.main_area_id, v_fact_data.taxon_key) temp2 ON vfd.main_area_id = temp2.main_area_id AND vfd.taxon_key = temp2.taxon_key
  WHERE vfd.marine_layer_id = 19 AND vfd.taxon_key > 600000
  GROUP BY vfd.main_area_id, vfd.taxon_key, temp2.discard_catch, temp1.total_catch;


--materialized view v_me_discards_above_20
CREATE MATERIALIZED VIEW cmsy.v_me_discards_above_20
AS SELECT p.meow_id,
    sum(vfd.catch_sum) AS catch_sum,
    count(p.taxon_key) AS discards_count
   FROM cmsy.v_me_discard_percentage p
     JOIN v_fact_data vfd ON vfd.main_area_id = p.meow_id AND vfd.taxon_key = p.taxon_key
  WHERE vfd.marine_layer_id = 19 AND p.discard_percentage > 0.2
  GROUP BY p.meow_id;


--materialized view v_me_discards_above_20_2
CREATE MATERIALIZED VIEW cmsy.v_me_discards_above_20_2
AS SELECT p.meow_id,
    sum(vfd.catch_sum) AS catch_sum,
    count(DISTINCT p.taxon_key) AS species_count
   FROM cmsy.v_me_discard_percentage p
     JOIN v_fact_data vfd ON vfd.main_area_id = p.meow_id AND vfd.taxon_key = p.taxon_key
  WHERE vfd.marine_layer_id = 19 AND p.discard_percentage > 0.2
  GROUP BY p.meow_id;


--materialized view v_me_exclude_discards_above_20
CREATE MATERIALIZED VIEW cmsy.v_me_exclude_discards_above_20
AS SELECT vfd.main_area_id,
    vfd.taxon_key,
    sum(vfd.catch_sum) AS catch_sum,
    count(p.taxon_key) AS discards_count
   FROM cmsy.v_me_discard_percentage p
     JOIN v_fact_data vfd ON vfd.main_area_id = p.meow_id AND vfd.taxon_key = p.taxon_key
  WHERE vfd.marine_layer_id = 19 AND p.discard_percentage <= 0.2
  GROUP BY vfd.main_area_id, vfd.taxon_key;


--materialized view v_me_exclude_discards_above_20_2
CREATE MATERIALIZED VIEW cmsy.v_me_exclude_discards_above_20_2
AS SELECT vfd.main_area_id,
    vfd.taxon_key,
    sum(vfd.catch_sum) AS catch_sum
   FROM cmsy.v_me_discard_percentage p
     JOIN v_fact_data vfd ON vfd.main_area_id = p.meow_id AND vfd.taxon_key = p.taxon_key
  WHERE vfd.marine_layer_id = 19 AND p.discard_percentage <= 0.2
  GROUP BY vfd.main_area_id, vfd.taxon_key;


--materialzied view v_me_top_90_percent_species_by_catch
CREATE MATERIALIZED VIEW cmsy.v_me_top_90_percent_species_by_catch
AS WITH t1(meow_id, taxon_key, percentage) AS (
         SELECT e.main_area_id,
            e.taxon_key,
            (e.catch_sum / e1.catch_sum)::double precision AS percentage,
            e.catch_sum
           FROM cmsy.v_me_exclude_discards_above_20 e,
            ( SELECT e_1.main_area_id,
                    sum(e_1.catch_sum) AS catch_sum
                   FROM cmsy.v_me_exclude_discards_above_20 e_1
                  GROUP BY e_1.main_area_id) e1
          WHERE e1.main_area_id = e.main_area_id
          ORDER BY e.main_area_id, ((e.catch_sum / e1.catch_sum)::double precision) DESC
        ), t2 AS (
         SELECT t1.meow_id,
            t1.taxon_key,
            t1.percentage,
            sum(t1.percentage) OVER (PARTITION BY t1.meow_id ORDER BY t1.meow_id, t1.percentage DESC, 1::integer) AS running_total,
            t1.catch_sum
           FROM t1
          ORDER BY t1.meow_id, t1.percentage DESC
        )
 SELECT t2.meow_id,
    t2.taxon_key,
    t2.percentage,
    t2.running_total,
    t2.catch_sum
   FROM t2
  WHERE t2.running_total <= 0.9::double precision
UNION
 SELECT t2.meow_id,
    t2.taxon_key,
    t2.percentage,
    t2.running_total,
    t2.catch_sum
   FROM t2,
    ( SELECT t2_1.meow_id,
            min(t2_1.running_total) AS running_total
           FROM t2 t2_1
          WHERE t2_1.running_total > 0.9::double precision
          GROUP BY t2_1.meow_id) t3
  WHERE t2.meow_id = t3.meow_id AND t2.running_total = t3.running_total
  GROUP BY t2.meow_id, t2.taxon_key, t2.percentage, t2.running_total, t2.catch_sum;