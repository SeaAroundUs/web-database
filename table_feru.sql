CREATE TABLE feru.country (
    country_id integer,
    c_master varchar(50),
    fao_name varchar(255),
    countcode varchar(255),
    c_number varchar(50),
    region varchar(50),
    high_seas varchar(50),
    own_eez varchar(50),
    dwf_eez varchar(50),
    un_name varchar(255),
    label varchar(255),
    continent varchar(255),
    sub_con varchar(255),
    fao varchar(255),
    goep_admin varchar(50),
    admin_country varchar(255),
    a_code varchar(50),
    sub_eez varchar(50),
    partition varchar(50),
    disputed_eez varchar(50),
    eu varchar(50),
    ussr varchar(50),
    usa varchar(50),
    yugoslavia varchar(50),
    czechoslovakia varchar(50),
    territory varchar(50),
    terr_year varchar(50),
    fish_zone varchar(50),
    fish_year varchar(50),
    eez varchar(50),
    eez_year varchar(50),
    access_year varchar(50),
    unclosc_sign varchar(255),
    unclosc_rat varchar(255),
    fishing varchar(50),
    comment varchar(255),
    web_ref_cat_id varchar(50),
    c_number2 varchar(50),
    saup_name varchar(255),
    wdi_country_name varchar(255),
    wdi_new_id varchar(50),
    wdi_3code varchar(50),
    wdi_eez varchar(50),
    country varchar(255),
    un_eez varchar(50),
    un_new_id varchar(50),
    un_code varchar(50),
    un_3code varchar(50),
    un_region varchar(50),
    un_sub_region varchar(50),
    developed varchar(50),
    least_developed varchar(50),
    land_locked varchar(50),
    small_island_developing varchar(50),
    commonwealth_of_ind_states varchar(50),
    transition varchar(50),
    gtap_num integer,
    gtap_3code varchar(255),
    gtap_name varchar(255),
    gtap_region varchar(50),
    goep_code varchar(50),
    iso2 varchar(255),
    gtap_num2 varchar(255),
    gtap_code2 varchar(255),
    gtap_name2 varchar(255),
    gtap_region2 varchar(255),
    gtap_cge_note varchar(255)
);


CREATE TABLE feru.currency (
    iso_4217_number varchar(50),
    digits_after_decimal varchar(50),
    currency_name text,
    currency_country text,
    currency_abbrv varchar(3)
);


CREATE TABLE feru.data (
    data_id integer,
    year varchar(50),
    entity varchar(50),
    recipient_entity varchar(50),
    recipient_state_prov varchar(50),
    donating_entity varchar(50),
    sub_category varchar(50),
    outlay varchar(50),
    expenditure varchar(50),
    dummy character(1),
    comment text,
    doc_source varchar(255),
    source_visit_date varchar(255),
    fy varchar(255),
    fao_web_link_ref varchar(50),
    ref varchar(255),
    url varchar(200),
    "user" varchar(50),
    old_comment text,
    currency varchar(50),
    fish_source varchar(50),
    fish_sector varchar(50),
    iso3 varchar(50),
    eez varchar(50)
);


CREATE TABLE feru.data_entry (
    data_id integer,
    year varchar(50),
    entity varchar(50),
    recipient_entity varchar(50),
    recipient_state_prov varchar(50),
    recipient_city varchar(50),
    donating_entity varchar(50),
    sub_type varchar(50),
    outlay varchar(50),
    expenditure varchar(50),
    dummy character(1),
    comment text,
    ref integer,
    refernce_file varchar(50),
    refernce_file2 varchar(50),
    url varchar(255),
    "user" varchar(50),
    currency varchar(50),
    fish_source varchar(50),
    fish_sector varchar(50)
);


CREATE TABLE feru.reference (
    ref_id integer,
    ref_name varchar(50),
    ref_source varchar(50),
    ref_comment text,
    ref_year varchar(50),
    ref_author varchar(50),
    ref_title varchar(50),
    ref_url varchar(200),
    ref_file varchar(50)
);


CREATE TABLE feru.sub_type (
    sub_category_id varchar(50),
    sub_category varchar(50),
    category varchar(50),
    sub_type varchar(50),
    sub_name text,
    description text
);


CREATE TABLE feru.year (
    year_id integer,
    year varchar(50)
);

CREATE TABLE feru.subsidy(      
  id int primary key,
  c_number int not null,
  region_id int,
  region_name text,
  country_name text,
  type text,
  sub_type text,
  category text,
  subsidy decimal,
  re_est_subsidy decimal,
  is_new_data boolean,
  is_developed boolean,
  hdi_2005 decimal,
  year int
);

