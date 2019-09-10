CREATE TABLE geo.area (
    gid serial primary key,
    area_key int,
    area_km2 numeric,
    geom geometry(MultiPolygon, 4326),
    ifa_area_km2 numeric,
    ifa_geom geometry(MultiPolygon, 4326)
);

CREATE TABLE geo.fao (
    gid serial primary key,
    fao_area_id int not null,
    f_level character varying(254),
    ocean character varying(254),
    sub_ocean character varying(254),
    label text,
    geom public.geometry(MultiPolygon, 4326)
);


CREATE TABLE geo.high_seas (
    gid serial primary key,
    fao_area_id int,
    eez_ogc_fid_intersects int[], 
    geom public.geometry(MultiPolygon, 4326)
);


CREATE TABLE geo.eez (
    ogc_fid serial primary key,
    eez_id integer,
    shape_length double precision,
    shape_area double precision,
    wkb_geometry geometry(MultiPolygon, 4326)
);


CREATE TABLE geo.lme (
    gid serial primary key,
    object_id integer,
    lme_number integer,
    lme_name character varying(70),
    shape_leng numeric,
    shape_area numeric,
    geom public.geometry(MultiPolygon, 4326)
);

CREATE TABLE geo.meow (
	gid serial primary key,
	meow_id integer,
	eco_id integer,
	ecoregion character varying(70),
	prov_id integer,
	province character varying(70),
	realm_id integer,
	realm character varying(70),
	lat_zone character varying(70),
	shape_area numeric,
	geom public.geometry(MultiPolygon, 4326)
);

CREATE TABLE geo.fao_lme(
  fao_lme_combo_id int PRIMARY KEY,
  fao_area_id smallint NOT NULL,
  lme_number int NOT NULL,
  CONSTRAINT unique_fao_lme UNIQUE (fao_area_id, lme_number)
);

CREATE TABLE geo.fao_meow(
	fao_meow_combo_id int PRIMARY KEY,
	fao_area_id smallint NOT NULL,
	ecoregion_id int NOT NULL,
	CONSTRAINT unique_fao_meow UNIQUE (fao_area_id, ecoregion_id)
);

CREATE TABLE geo.rfmo (  
    gid          serial PRIMARY KEY,
    name         character varying(15), 
    rfmo_id      int not null,
    area_km2     numeric,
    shape_length numeric,
    shape_area   numeric,
    geom         geometry(MultiPolygon, 4326) 
);


CREATE TABLE geo.ifa (
    gid        serial primary key,               
    object_id   integer,               
    eez_id      integer,               
    c_name     varchar(50), 
    a_name     varchar(50),
    a_num      integer,               
    area_km2   numeric,                                                       
    shape_leng numeric,               
    shape_area numeric,       
    ifa_is_located_in_this_fao numeric,		
    geom       geometry(MultiPolygon, 4326)
);


CREATE TABLE geo.mariculture(
 gid      integer PRIMARY KEY,
 id       integer,                     
 c_number  smallint,                    
 taxon_key integer,                   
 sub_unit  character varying(50),       
 y1965    numeric,
 y1966    numeric,
 y1967    numeric,
 y1968    numeric,
 y1969    numeric,
 y1970    numeric,
 y1971    numeric,
 y1972    numeric,
 y1973    numeric,
 y1974    numeric,
 y1975    numeric,
 y1976    numeric,
 y1977    numeric,
 y1978    numeric,
 y1979    numeric,
 y1980    numeric,
 y1981    numeric,
 y1982    numeric,
 y1983    numeric,
 y1984    numeric,
 y1985    numeric,
 y1986    numeric,
 y1987    numeric,
 y1988    numeric,
 y1989    numeric,
 y1990    numeric,
 y1991    numeric,
 y1992    numeric,
 y1993    numeric,
 y1994    numeric,
 y1995    numeric,
 y1996    numeric,
 y1997    numeric,
 y1998    numeric,
 y1999    numeric,
 y2000    numeric,                                      
 y2001    numeric,
 y2002    numeric,
 y2003    numeric,
 y2004    numeric,
 y2005    numeric,
 y2006    numeric,
 y2007    numeric,
 y1964    numeric,
 y1963    numeric,
 y1962    numeric,
 y1961    numeric,
 y1960    numeric,
 y1959    numeric,
 y1958    numeric,
 y1957    numeric,
 y1956    numeric,
 y1955    numeric,
 y1954    numeric,
 y1953    numeric,
 y1952    numeric,
 y1951    numeric,
 y1950    numeric,
 y2008    numeric,
 geom     geometry(MultiPolygon,4326) 
); 

CREATE TABLE geo.mariculture_points (
    gid serial primary key,
    object_id integer,
    c_number double precision,
    taxon_key integer,
    sub_unit character varying(254),
    long double precision,
    lat double precision,
    f2010 double precision,
    f2009 double precision,
    f2008 double precision,
    f2007 double precision,
    f2006 double precision,
    f2005 double precision,
    f2004 double precision,
    f2003 double precision,
    f2002 double precision,
    f2001 double precision,
    f2000 double precision,
    f1999 double precision,
    f1998 double precision,
    f1997 double precision,
    f1996 double precision,
    f1995 double precision,
    f1994 double precision,
    f1993 double precision,
    f1992 double precision,
    f1991 double precision,
    f1990 double precision,
    f1989 double precision,
    f1988 double precision,
    f1987 double precision,
    f1986 double precision,
    f1985 double precision,
    f1984 double precision,
    f1983 double precision,
    f1982 double precision,
    f1981 double precision,
    f1980 double precision,
    f1979 double precision,
    f1978 double precision,
    f1977 double precision,
    f1976 double precision,
    f1975 double precision,
    f1974 double precision,
    f1973 double precision,
    f1972 double precision,
    f1971 double precision,
    f1970 double precision,
    f1969 double precision,
    f1968 double precision,
    f1967 double precision,
    f1966 double precision,
    f1965 double precision,
    f1964 double precision,
    f1963 double precision,
    f1962 double precision,
    f1961 double precision,
    f1960 double precision,
    f1959 double precision,
    f1958 double precision,
    f1957 double precision,
    f1956 double precision,
    f1955 double precision,
    f1954 double precision,
    f1953 double precision,
    f1952 double precision,
    f1951 double precision,
    f1950 double precision,
    eez_id integer, 
    eez_name character varying(254), 
    entity_id smallint, 
    sub_entity_id smallint,
    geom public.geometry(Point,4326)
);


CREATE TABLE geo.ne_country (
    gid integer primary key,
    c_number int not null default 0,
    sovereignt character varying(32),
    sov_a3 character varying(3),
    level double precision,
    type character varying(17),
    admin character varying(40),
    adm0_a3 character varying(3),
    name character varying(36),
    name_long character varying(40),
    iso_a2 character varying(5),
    iso_a3 character varying(3),
    iso_n3 character varying(3),
    un_a3 character varying(4),
    continent character varying(23),
    region_un character varying(23),
    subregion character varying(25),
    geom public.geometry(MultiPolygon,4326)
);

CREATE TABLE geo.mariculture_entity (
    gid serial primary key,
    object_id integer,
    join_count integer,
    target_fid integer,
    join_fid integer,
    eez_id smallint,
    sub_unit character varying(50),
    taxon_key numeric,
    sub_unit_1 character varying(254),
    f2010 numeric,
    f2009 numeric,
    f2008 numeric,
    f2007 numeric,
    f2006 numeric,
    f2005 numeric,
    f2004 numeric,
    f2003 numeric,
    f2002 numeric,
    f2001 numeric,
    f2000 numeric,
    f1999 numeric,
    f1998 numeric,
    f1997 numeric,
    f1996 numeric,
    f1995 numeric,
    f1994 numeric,
    f1993 numeric,
    f1992 numeric,
    f1991 numeric,
    f1990 numeric,
    f1989 numeric,
    f1988 numeric,
    f1987 numeric,
    f1986 numeric,
    f1985 numeric,
    f1984 numeric,
    f1983 numeric,
    f1982 numeric,
    f1981 numeric,
    f1980 numeric,
    f1979 numeric,
    f1978 numeric,
    f1977 numeric,
    f1976 numeric,
    f1975 numeric,
    f1974 numeric,
    f1973 numeric,
    f1972 numeric,
    f1971 numeric,
    f1970 numeric,
    f1969 numeric,
    f1968 numeric,
    f1967 numeric,
    f1966 numeric,
    f1965 numeric,
    f1964 numeric,
    f1963 numeric,
    f1962 numeric,
    f1961 numeric,
    f1960 numeric,
    f1959 numeric,
    f1958 numeric,
    f1957 numeric,
    f1956 numeric,
    f1955 numeric,
    f1954 numeric,
    f1953 numeric,
    f1952 numeric,
    f1951 numeric,
    f1950 numeric,
    shape_leng numeric,
    shape_area numeric,
    geom public.geometry(MultiPolygon,4326)
);

CREATE TABLE geo.cell_grid (
    cell_id serial primary key,
    lat float,
    lon float,
    geom public.geometry(MultiPolygon,4326)
);

CREATE TABLE geo.eez_fao (
  eez_fao_area_id SERIAL PRIMARY KEY,
  reconstruction_eez_id int NOT NULL,
  fao_area_id int NOT NULL,
  socio_economic_area_id int
);

CREATE TABLE geo.meow_oceans_combo (
	meow_ocean_combo_id serial primary key,
	meow_id int4,
	meow varchar,
	fao_area_id int4,
	"name" varchar
);
