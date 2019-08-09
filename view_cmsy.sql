

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
group by mp.stock, mp.meow, mp.meow_id, a.sciname,cdt.taxon_key, b.biomass, c.biomass, d.biomass,mec.eez_id, a.subregion, mec.eez, mec.percentage_eez_in_meow


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
group by vfd.main_area_id, b.sciname, b.stock, vfd.taxon_key, b.b_bmsy_5yr,b.percentage_eez_in_meow, b.b_bmsy_3yr, b.b_bmsy_1yr


-- Sum of >600000 taxa catch by EEZ
create materialized view cmsy.v_eez_species_total as 
select vfd.main_area_id eez_id, sum(vfd.catch_sum) catch_total, count(distinct vfd.taxon_key) as species_count
from web.v_fact_data vfd
where taxon_key > 600000 and marine_layer_id = 1
group by vfd.main_area_id

-- Sum of all taxa catch by EEZ
create materialized view cmsy.v_eez_total as 
select vfd.main_area_id eez_id, sum(vfd.catch_sum) catch_total, count(distinct vfd.taxon_key) as taxa_count
from web.v_fact_data vfd
where marine_layer_id = 1
group by vfd.main_area_id

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
order by eez asc

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
order by eez asc

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
order by eez asc


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
order by eez asc

-- B prime by species only catch (B/Bmsy (Weighted) / species only catch by EEZ)
create materialized view cmsy.v_b_prime_weighted_species_only_catch as 
select eez, (b.b_5yr_with_area/b.species_total) b_prime_5yr_with_area,
(b.b_3yr_with_area/b.species_total) b_prime_3yr_with_area,
(b.b_1yr_with_area/b.species_total) b_prime_1yr_with_area,
(b.b_5yr_without_area/b.species_total) b_prime_5yr_without_area,
(b.b_3yr_without_area/b.species_total) b_prime_3yr_without_area,
(b.b_1yr_without_area/b.species_total) b_prime_1yr_without_area
from cmsy.v_b_summary_weighted_species_catch b

-- B prime by all catch (B/Bmsy (Weighted) / all catch by EEZ)
create materialized view cmsy.v_b_prime_weighted_all_catch as 
select eez, (b.b_5yr_with_area/b.species_total) b_prime_5yr_with_area,
(b.b_3yr_with_area/b.species_total) b_prime_3yr_with_area,
(b.b_1yr_with_area/b.species_total) b_prime_1yr_with_area,
(b.b_5yr_without_area/b.species_total) b_prime_5yr_without_area,
(b.b_3yr_without_area/b.species_total) b_prime_3yr_without_area,
(b.b_1yr_without_area/b.species_total) b_prime_1yr_without_area
from cmsy.v_b_summary_weighted_all_catch b

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
group by b.eez_id, b2.stock_num, b3.stock_num, b4.stock_num, e.name


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


-- Determine species discard % for eez
create materialized view cmsy.v_discard_percentage as 
select distinct vfd.main_area_id as eez_id,  vfd.taxon_key, coalesce(temp2.discard_catch/temp1.total_catch, 0) discard_percentage
from web.v_fact_data vfd
left join (select main_area_id, taxon_key, sum(catch_sum) as total_catch from web.v_fact_data where marine_layer_id = 1 and taxon_key > 600000 group by main_area_id, taxon_key) as temp1
on (vfd.main_area_id = temp1.main_area_id and vfd.taxon_key = temp1.taxon_key)
left join (select main_area_id, taxon_key, sum(catch_sum) as discard_catch from web.v_fact_data where marine_layer_id = 1 and catch_type_id = 2 and taxon_key > 600000 group by main_area_id, taxon_key) as temp2
on (vfd.main_area_id = temp2.main_area_id and vfd.taxon_key = temp2.taxon_key)
where vfd.marine_layer_id = 1 and vfd.taxon_key > 600000;

-- Filter eez by taxon where discards are less than or equal to 20%
create materialized view cmsy.v_eez_exclude_discards_above_20 as
select vfd.main_area_id, vfd.taxon_key, sum(vfd.catch_sum) as catch_sum, count(p.taxon_key) as discards_count
from cmsy.v_discard_percentage p
inner join web.v_fact_data vfd on (vfd.main_area_id = p.eez_id and vfd.taxon_key = p.taxon_key)
where vfd.marine_layer_id = 1
and p.discard_percentage <= .2
group by vfd.main_area_id, vfd.taxon_key;


-- Count how many taxa have discards greater than 20%
create materialized view cmsy.v_discards_above_20 as
select p.eez_id, sum(vfd.catch_sum) as catch_sum,  count(p.taxon_key) as discards_count
from cmsy.v_discard_percentage p
inner join web.v_fact_data vfd on (vfd.main_area_id = p.eez_id and vfd.taxon_key = p.taxon_key)
where vfd.marine_layer_id = 1
where p.discard_percentage > .2
group by p.eez_id;


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
