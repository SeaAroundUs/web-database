CREATE OR REPLACE VIEW fishing_effort.v_fishing_effort
AS WITH base_table(fishing_entity_id, year, sector_type_id, eez_id, effort_gear_id, length_code, m_um, motorisation, kw_boat, number_boats, days_fished, effort, em_factor, sfr, fuel_coeff) AS (
         SELECT fe.fishing_entity_id,
            fe.year,
            fe.sector_type_id,
            fe.eez_id,
            fe.effort_gear_code,
            fe.length_code,
            fe.m_um,
            fe.motorisation,
            fe.kw_boat,
            fe.number_boats,
            fe.days_fished,
            fe.effort,
                CASE fe.m_um
                    WHEN 'M'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3 THEN 3.0058
                        WHEN 1 THEN 3.17
                        WHEN 2 THEN 3.0058
                        WHEN 4 THEN 3.0058
                        ELSE NULL::numeric
                    END
                    WHEN 'UM'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3 THEN 0
                        WHEN 1 THEN 0
                        WHEN 2 THEN 0
                        WHEN 4 THEN 0
                        ELSE NULL::integer
                    END::numeric
                    ELSE NULL::numeric
                END AS em_factor,
                CASE fe.m_um
                    WHEN 'M'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3 THEN 0.00035
                        WHEN 1 THEN 0.0002
                        WHEN 2 THEN 0.00035
                        WHEN 4 THEN 0.00035
                        ELSE NULL::numeric
                    END
                    WHEN 'UM'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3 THEN 0
                        WHEN 1 THEN 0
                        WHEN 2 THEN 0
                        WHEN 4 THEN 0
                        ELSE NULL::integer
                    END::numeric
                    ELSE NULL::numeric
                END AS sfr,
            fc.fuel_coeff
           FROM fishing_effort.fishing_effort fe
             JOIN fishing_effort.fuel_coeff fc ON fe.year = fc."﻿year"
             JOIN sector_type st ON st.sector_type_id = fe.sector_type_id
             JOIN fishing_effort.fishing_effort_gear fg ON st.name::text = fg.sector_type::text AND fe.effort_gear_code::text = fg.effort_gear_id::text
        )
 SELECT base_table.fishing_entity_id,
    base_table.year,
    base_table.sector_type_id,
    base_table.eez_id,
    base_table.effort_gear_id,
    base_table.length_code,
    base_table.m_um,
    base_table.motorisation,
    base_table.kw_boat,
    base_table.number_boats,
    base_table.days_fished,
    base_table.effort,
    base_table.em_factor,
    base_table.sfr,
    base_table.fuel_coeff,
    base_table.kw_boat * base_table.number_boats * base_table.motorisation::double precision * base_table.em_factor::double precision * base_table.sfr::double precision * base_table.fuel_coeff * base_table.days_fished::double precision AS co2
   FROM base_table;



--New fishing_effort views
--M.Nevado
--8.7.2020

CREATE OR REPLACE VIEW fishing_effort.bait_boat_types_calc
AS SELECT fe.sector_type_id,
    fe.effort_gear_code,
    fe.motorisation,
    fe.length_code,
    "left"((((((fe.sector_type_id::character varying::text || '.'::character varying::text) || fe.effort_gear_code::text) || '.'::character varying::text) || fe.motorisation::character varying::text) || '.'::character varying::text) || fe.length_code::character varying::text, 12)::character varying AS boat_type,
    fe.case_number
   FROM fishing_effort.fishing_effort fe;

CREATE OR REPLACE VIEW fishing_effort.bait_catch1
AS SELECT fe.sector_type_id,
    fe.effort_gear_code,
    fe.motorisation,
    fe.length_code,
    "left"((((((fe.sector_type_id::character varying::text || '.'::character varying::text) || fe.effort_gear_code::text) || '.'::character varying::text) || fe.motorisation::character varying::text) || '.'::character varying::text) || fe.length_code::character varying::text, 12)::character varying AS boat_type,
    fe.case_number
   FROM fishing_effort.fishing_effort fe;