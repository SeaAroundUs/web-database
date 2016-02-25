create or replace function web.f_entity_layer_metrics
(
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[], 
  i_other_params json default null
)
returns table(area numeric, shelf numeric, ifa numeric, coral_reefs numeric, seamounts numeric, ppr numeric) as
$body$
declare
  main_area_col_name text;
  additional_join_clause text := '';
  area_bucket_id_layer int;
  rtn_sql text;
begin
  case 
    when i_entity_layer_id < 100 then 
      main_area_col_name := 'a.main_area_id';
    when i_entity_layer_id = 200 then 
      main_area_col_name := 'ab.area_bucket_id';
      
      area_bucket_id_layer := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
      
      if area_bucket_id_layer = 400 then
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and a.area_key = any(ab.area_id_bucket))';
      else
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and a.main_area_id = any(ab.area_id_bucket) and a.marine_layer_id = ' || area_bucket_id_layer || ')';
      end if;
    when i_entity_layer_id = 400 then
      main_area_col_name := 'a.area_key';
    when i_entity_layer_id = 900 then
      main_area_col_name := 'fa.fao_area_id';
      additional_join_clause := additional_join_clause || ' join web.fao_area fa on (fa.fao_area_id = any($1) and a.area_key = any(fa.area_key))';
    else
      raise exception 'Input entity layer % is not valid for metrics calculation.', i_entity_layer_id;
  end case;
  
  rtn_sql := 
    'select sum(a.area),sum(a.shelf_area),sum(a.ifa),sum(a.coral_reefs),sum(a.sea_mounts),sum(a.area * a.ppr)/sum(a.area)' || 
    ' from web.area a' || 
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id < 100 then ' a.marine_layer_id = ' || i_entity_layer_id || ' and a.main_area_id = any($1) and'
    else ''
     end ||
    ' (case when $2 is null then true else a.sub_area_id = any($2) end)';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;

create or replace function web.f_entity_layer_exploited_organisms
(
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_sub_entity_id int[] default null::int[],
  i_other_params json default null
)
returns setof json
--(taxon_group int, trophic_level numeric, taxon_key int, sl_max_cm int, taxon_level 1, scientific_name varchar(255), common_name varchar(255)) 
as
$body$
declare
  additional_join_clause text := '';
  where_clause text := null;
  area_bucket_id_layer int;
  rtn_sql text := 'select distinct t.taxon_group_id as taxon_group, t.tl as trophic_level, t.taxon_key, t.sl_max as sl_max_cm, t.taxon_level_id as taxon_level, t.scientific_name, t.common_name from web.v_fact_data f join web.cube_dim_taxon t on (t.taxon_key = f.taxon_key)';
  managed_species_type varchar(20);
begin
  case 
    when i_entity_layer_id < 100 then 
      where_clause := 'f.main_area_id = any($1) and f.marine_layer_id = ' || i_entity_layer_id;
      
      /* Special consideration for RFMO */
      if i_entity_layer_id = 4 then
        if coalesce((json_object_field_text(i_other_params, 'managed_species_only'))::boolean, false) then
          managed_species_type := coalesce(lower(json_object_field_text(i_other_params, 'managed_species_type')), 'all');
          case managed_species_type
          when 'primary' then
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.primary_taxon_keys)))';
          when 'secondary' then
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.secondary_taxon_keys)))';
          else
            additional_join_clause := additional_join_clause || ' join web.rfmo_managed_taxon mt on (mt.rfmo_id = any($1) and (not mt.taxon_check_required or f.taxon_key = any(mt.primary_taxon_keys || mt.secondary_taxon_keys)))';
          end case;
        end if;
      end if;
    when i_entity_layer_id = 100 then 
      where_clause := 'f.fishing_entity_id = any($1)';
    when i_entity_layer_id = 200 then 
      area_bucket_id_layer := case when i_entity_layer_id = 200 then web.get_area_bucket_id_layer(i_entity_id) else 0 end;
      
      if area_bucket_id_layer = 400 then
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.area_key = any(ab.area_id_bucket))';
      else
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.main_area_id = any(ab.area_id_bucket) and f.marine_layer_id = ' || area_bucket_id_layer || ')';
      end if;
    when i_entity_layer_id = 300 then
      where_clause := 't.taxon_key = any($1)';
    when i_entity_layer_id = 400 then
      where_clause := 'f.area_key = any($1)';
    when i_entity_layer_id = 500 then
      where_clause := 't.commercial_group_id = any($1)';
    when i_entity_layer_id = 600 then
      where_clause := 't.functional_group_id = any($1)';
    when i_entity_layer_id = 700 then
      where_clause := 'f.reporting_status = any($1)';
    when i_entity_layer_id = 800 then
      where_clause := 'f.catch_status = any($1)';
    when i_entity_layer_id = 900 then
      additional_join_clause := additional_join_clause || ' join web.fao_area fa on (fa.fao_area_id = any($1) and f.area_key = any(fa.area_key))';
    else
      raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;

  rtn_sql := 
    rtn_sql ||
    additional_join_clause ||
    ' where (case when $2 is null then true else f.sub_area_id = any($2) end)' ||
    coalesce(' and ' || where_clause, '');

  return query execute format('select json_agg(d.*) from (%s) as d', rtn_sql)
  using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;
