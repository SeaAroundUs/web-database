CREATE INDEX indx_expedition_key ON expedition.abundance_by_station(expedition_key);

CREATE INDEX ix_country ON expedition.country(count_code, c_number);

CREATE INDEX ix_vessels_1 ON expedition.vessels(expedition_key, vessel_name);

