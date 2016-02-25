------
------ Foreign Keys
------
--ALTER TABLE geo. ADD CONSTRAINT _fk
--FOREIGN KEY () REFERENCES web.() ON DELETE CASCADE;
ALTER TABLE geo.rfmo ADD CONSTRAINT rfmo_rfmo_id_fk
FOREIGN KEY (rfmo_id) REFERENCES web.rfmo(rfmo_id) ON DELETE CASCADE;

ALTER TABLE geo.ifa ADD CONSTRAINT ifa_eez_id_fk
FOREIGN KEY (eez_id) REFERENCES web.eez(eez_id) ON DELETE CASCADE;

ALTER TABLE geo.ne_country ADD CONSTRAINT ne_country_c_number_fk
FOREIGN KEY (c_number) REFERENCES web.country(c_number) ON DELETE CASCADE;

