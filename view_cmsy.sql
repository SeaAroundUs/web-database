--New views for cmsy
--M.Nevado
--10.8.2020

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