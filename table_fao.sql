CREATE TABLE fao.fao_rfb(
  fid smallint primary key,
  acronym varchar(20) not null unique,
  name text,
  profile_url text,
  modified_timestamp timestamp not null default now()
);

CREATE TABLE fao.fao_country_rfb_membership(
  id serial primary key,
  country_iso3 char(3) not null,
  rfb_fid smallint not null,
  membership_type varchar(100) not null,
  modified_timestamp timestamp not null default now(),
  CONSTRAINT fao_country_rfb_membership_uk UNIQUE(country_iso3, rfb_fid, membership_type)
);

CREATE TABLE fao.fao_country_rfmo_membership(
  id serial primary key,
  rfmo_id int not null,
  country_iso3 char(3) not null,
  country_name varchar(256) not null,
  country_facp_url text,
  modified_timestamp timestamp not null default now(),
  CONSTRAINT fao_country_rfmo_membership_uk UNIQUE(rfmo_id, country_iso3)
);
