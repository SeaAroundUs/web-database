/**
helper functions
**/

create or replace function web.f_dimension_effort_query_layer_preprocessor
(
  i_entity_layer_id int,
  i_area_bucket_id_layer int, 
  i_other_params json
)
returns table(main_area_col_name text, additional_join_clause text) as
$body$
declare
  main_area_col_name text;
  additional_join_clause text := '';
  managed_species_type varchar(20);
begin
  case 
    when i_entity_layer_id < 100 then 
      main_area_col_name := 'f.main_area_id';
      
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
      main_area_col_name := 'f.fishing_entity_id::int';
    when i_entity_layer_id = 200 then 
      main_area_col_name := 'ab.area_bucket_id';
      
      if i_area_bucket_id_layer = 400 then
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.area_key = any(ab.area_id_bucket))';
      else
        additional_join_clause := additional_join_clause || ' join web.area_bucket ab on (ab.area_bucket_id = any($1) and f.main_area_id = any(ab.area_id_bucket) and f.marine_layer_id = ' || i_area_bucket_id_layer || ')';
      end if;
    when i_entity_layer_id = 300 then
      main_area_col_name := 'f.taxon_key';
    when i_entity_layer_id = 400 then
      main_area_col_name := 'f.area_key';
    when i_entity_layer_id = 500 then
      main_area_col_name := 'wt.commercial_group_id';
      additional_join_clause := ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)';
    when i_entity_layer_id = 600 then
      main_area_col_name := 'wt.functional_group_id';
      additional_join_clause := ' join web.cube_dim_taxon wt on (wt.taxon_key = f.taxon_key)';
    when i_entity_layer_id = 700 then
      main_area_col_name := 'f.reporting_status';
    when i_entity_layer_id = 800 then
      main_area_col_name := 'f.catch_status';
    when i_entity_layer_id = 900 then
      main_area_col_name := 'fa.fao_area_id';
      additional_join_clause := additional_join_clause || ' join web.fao_area fa on (fa.fao_area_id = any($1) and f.area_key = any(fa.area_key))';
    when i_entity_layer_id = 1000 then
      main_area_col_name := 'f.data_layer_id';
    when i_entity_layer_id = 1100 then
      main_area_col_name := 'f.gear_type';
    else
      raise exception 'Invalid entity layer id input received: %', i_entity_layer_id;
  end case;
  
  return query select main_area_col_name, additional_join_clause;
end
$body$
language plpgsql;


create or replace function web.f_dimension_fishing_sector_effort_query 
(
  i_measure varchar(20),
  i_entity_id int[],
  i_sub_entity_id int[],
  i_entity_layer_id int default 1,
  i_area_bucket_id_layer int default null,
  i_output_area_id boolean default false,
  i_other_params json default null
)
returns table(year int, entity_id int, dimension_member_id int, measure numeric) as
$body$
declare
  rtn_sql text;
  main_area_col_name text;
  additional_join_clause text := '';
begin
  select *
    into main_area_col_name, additional_join_clause
    from web.f_dimension_catch_query_layer_preprocessor(i_entity_layer_id, i_area_bucket_id_layer, i_other_params);

  rtn_sql := 
    'select f.year,' || 
    case when coalesce(i_output_area_id, false) then main_area_col_name else 'null::int' end ||
    ',f.sector_type_id::int' ||
    case when i_measure = 'kw' then ',sum(f.kw_boat)' else ',sum(f.number_boats)::numeric' end ||  
    ' from fishing_effort.v_fishing_effort f' ||
    additional_join_clause ||
    ' where' ||   
    case 
    when i_entity_layer_id = 100 then ' f.fishing_entity_id = any($1) and'
    else ''
     end ||
    ' group by f.year' || 
    case when coalesce(i_output_area_id, false) 
    then
      ',' || main_area_col_name
    else 
      '' 
    end ||
    ',f.sector_type_id';

  return query execute rtn_sql
   using i_entity_id, i_sub_entity_id;
end
$body$
language plpgsql;


create or replace function fishing_effort.f_kw_by_dimension_json
(
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_top_count int default 10,
  i_other_params json default null
)
returns setof json as
$body$
  select f.data from web.f_effort_data_in_json('kw', i_dimension, i_entity_id, i_entity_layer_id, i_top_count, i_other_params) as f(data) where f.data is not null;
$body$
language sql;

create or replace function web.f_effort_data_in_json 
(
  i_measure varchar(20),
  i_dimension varchar(100), 
  i_entity_id int[], 
  i_entity_layer_id int default 1,
  i_top_count int default 10,
  i_other_params json default null
)                 
returns json as
$body$
  select f.* from web.f_dimension_fishing_sector_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'fishing_sector'
  union all
  select f.* from web.f_dimension_length_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'length_class'
  union all
  select f.* from web.f_dimension_gear_type_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'gear_type'
  union all
  select f.* from web.f_dimension_co2_json(i_measure, i_entity_id, i_entity_layer_id, i_sub_entity_id, i_other_params) as f where i_dimension = 'co2'
   ;   
$body$
language sql;