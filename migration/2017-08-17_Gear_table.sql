ALTER TABLE web.gear ADD COLUMN notes text;

VACUUM FULL ANALYZE web.gear;

select admin.grant_access();
