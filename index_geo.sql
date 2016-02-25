CREATE INDEX eez_wkb_geometry_geom_idx ON geo.eez USING gist(wkb_geometry);
CREATE INDEX eez_eez_id_idx ON geo.eez(eez_id);
CREATE UNIQUE INDEX v_eez_id_idx ON geo.v_eez(id);
CREATE INDEX v_eez_fishbase_id_idx ON geo.v_eez(fishbase_id);

CREATE UNIQUE INDEX rfmo_rfmo_id_idx ON geo.rfmo(rfmo_id);
CREATE INDEX rfmo_geom_idx ON geo.rfmo USING gist(geom);
CREATE UNIQUE INDEX v_rfmo_id_idx ON geo.v_rfmo(id);

CREATE INDEX ifa_eez_id_idx ON geo.ifa(eez_id);
CREATE INDEX ifa_geom_idx ON geo.ifa USING gist(geom);
CREATE INDEX v_ifa_eez_id_idx ON geo.v_ifa(eez_id);

CREATE INDEX fao_geom_geom_idx ON geo.fao USING gist(geom);
CREATE INDEX fao_fao_area_id_idx ON geo.fao(fao_area_id);
CREATE UNIQUE INDEX v_fao_fao_area_id_idx ON geo.v_fao(fao_area_id);

CREATE INDEX high_seas_geom_geom_idx ON geo.high_seas USING gist(geom);
CREATE INDEX high_seas_fao_area_id_idx ON geo.high_seas(fao_area_id);
CREATE UNIQUE INDEX v_high_seas_id_idx ON geo.v_high_seas(id);

CREATE INDEX mariculture_entity_eez_id_idx ON geo.mariculture_entity(eez_id);
CREATE INDEX v_mariculture_entity_c_number_idx ON geo.v_mariculture_entity(c_number);
CREATE INDEX v_mariculture_entity_c_iso_code_idx ON geo.v_mariculture_entity(c_iso_code);

CREATE INDEX mariculture_c_number_idx ON geo.mariculture(c_number);
CREATE INDEX mariculture_taxon_key_idx ON geo.mariculture(taxon_key);
CREATE INDEX mariculture_geom_idx ON geo.mariculture USING gist(geom);

CREATE INDEX mariculture_points_c_number_idx on geo.mariculture_points(c_number);
CREATE INDEX mariculture_points_entity_id_idx on geo.mariculture_points(entity_id);
CREATE INDEX mariculture_points_sub_entity_id_idx on geo.mariculture_points(sub_entity_id);

CREATE UNIQUE INDEX area_area_key_idx ON geo.area(area_key);
CREATE UNIQUE INDEX v_area_id_idx ON geo.v_area(id);
CREATE INDEX v_area_marine_layer_id_main_area_id_idx ON geo.v_area(marine_layer_id, main_area_id);
