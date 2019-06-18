CREATE OR REPLACE VIEW fishing_effort.v_fishing_effort
AS WITH base_table(fishing_entity_id, year, sector_type_id, eez_id, gear_id ,effort_gear_id, length_code, m_um, motorisation, kw_boat, number_boats, days_fished, em_factor, sfr, fuel_coeff) AS (
         SELECT fe.fishing_entity_id,
            fe.year,
            fe.sector_type_id,
            fe.eez_id,
			fg.gear_id,
            fe.effort_gear_id,
            fe.length_code,
            fe.m_um,
            fe.motorisation,
            fe.kw_boat,
            fe.number_boats,
            fe.days_fished,
                CASE fe.m_um
                    WHEN 'M'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3::int THEN 3.0058
                        WHEN 1::int THEN 3.17
                        WHEN 2::int THEN 3.0058
                        WHEN 4::int THEN 3.0058
                        ELSE NULL::numeric
                    END
                    WHEN 'UM'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3::int THEN 0
                        WHEN 1::int THEN 0
                        WHEN 2::int THEN 0
                        WHEN 4::int THEN 0
                        ELSE NULL::integer
                    END::numeric
                    ELSE NULL::numeric
                END AS em_factor,
                CASE fe.m_um
                    WHEN 'M'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3::int THEN 0.00035
                        WHEN 1::int THEN 0.0002
                        WHEN 2::int THEN 0.00035
                        WHEN 4::int THEN 0.00035
                        ELSE NULL::numeric
                    END
                    WHEN 'UM'::text THEN
                    CASE fe.sector_type_id
                        WHEN 3::int THEN 0
                        WHEN 1::int THEN 0
                        WHEN 2::int THEN 0
                        WHEN 4::int THEN 0
                        ELSE NULL::integer
                    END::numeric
                    ELSE NULL::numeric
                END AS sfr,
            fc.fuel_coeff
           FROM fishing_effort.fishing_effort fe
             JOIN fishing_effort.fuel_coeff fc ON fe.year = fc."﻿year"
             join web.sector_type st on st.sector_type_id = fe.sector_type_id
			 JOIN fishing_effort.fishing_effort_gear fg ON st.name = fg.sector_type and fe.effort_gear_id = fg.effort_gear_id
        )
 SELECT base_table.fishing_entity_id,
    base_table.year,
    base_table.sector_type_id,
    base_table.eez_id,
	base_table.gear_id,
    base_table.effort_gear_id,
    base_table.length_code,
    base_table.m_um,
    base_table.motorisation,
    base_table.kw_boat,
    base_table.number_boats,
    base_table.days_fished,
    base_table.em_factor,
    base_table.sfr,
    base_table.fuel_coeff,
    base_table.kw_boat * base_table.number_boats * base_table.motorisation::double precision * base_table.em_factor::double precision * base_table.sfr::double precision * base_table.fuel_coeff * base_table.days_fished::double precision AS co2
   FROM base_table