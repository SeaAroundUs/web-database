alter schema tiger owner to rds_superuser;
alter schema topology owner to rds_superuser;
alter schema tiger_data owner to rds_superuser;

with obj as (
  select * from schema_v('tiger', array['r','v','S']) 
  union all 
  select * from schema_v('topology', array['r','v','S'])
)
select exec('ALTER ' || object_type || ' ' || object_name || ' OWNER TO rds_superuser')
  from obj;

