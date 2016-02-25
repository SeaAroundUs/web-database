CREATE MATERIALIZED VIEW allocation.v_allocation_result_eez_unique_universal_data_id AS
SELECT DISTINCT universal_data_id 
 FROM allocation.allocation_result_eez
WITH NO DATA;
