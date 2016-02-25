(select 'refresh materialized view web.' || table_name || ';' from matview_v('web') where table_name not like 'TOTALS%' order by case when table_name = 'v_taxon_catch' then 1 else 0 end)
union all
(select 'refresh materialized view geo.' || table_name || ';' from matview_v('geo') where table_name not like 'TOTALS%')
union all
(select 'refresh materialized view allocation.' || table_name || ';' from matview_v('allocation') where table_name not like 'TOTALS%');
