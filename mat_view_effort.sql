--New fishing_effort materialized views
--M.Nevado
--8.7.2020

CREATE MATERIALIZED VIEW fishing_effort.mv_by_fishent
AS SELECT v_fact_data.fishing_entity_id,
    v_fact_data.year,
    sum(v_fact_data.catch_sum) AS sum
   FROM v_fact_data
  WHERE (v_fact_data.fishing_entity_id = ANY (ARRAY[1, 2])) AND v_fact_data.end_use_type_id = 3 AND (v_fact_data.marine_layer_id = ANY (ARRAY[1, 2]))
  GROUP BY v_fact_data.fishing_entity_id, v_fact_data.year;

CREATE MATERIALIZED VIEW fishing_effort.mv_by_fishentall
AS SELECT v_fact_data.fishing_entity_id,
    v_fact_data.year,
    sum(v_fact_data.catch_sum) AS sum
   FROM v_fact_data
  WHERE v_fact_data.end_use_type_id = 3 AND (v_fact_data.marine_layer_id = ANY (ARRAY[1, 2]))
  GROUP BY v_fact_data.fishing_entity_id, v_fact_data.year;
