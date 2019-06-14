create or replace view web.v_effort
as
  select e.fishing_entity_id,
         fe.name as fishing_entity,
         e.year,
         e.length_code,
         fg.gear_name as gear,
         e.sector_type,
         e.kw_boat,
         e.number_boats
    from web.fishing_effort e
    join web.fishing_entity fe on fe.fishing_entity_id = e.fishing_entity_id
    join web.fishing_effort_gear fg on fg.effort_gear_id = e.effort_gear_code;
