CREATE TABLE expedition.abundance (
    abundance_key integer NOT NULL,
    expedition_key integer,
    chronology_key double precision,
    bibliography_key integer,
    page_number character(50),
    image_file character(100),
    specimen_key character(50),
    abundance_text text,
    rank character(50),
    habitat character(50),
    kingdom character(50),
    "group" character(50),
    species character(50),
    remarks1 text,
    diversity_indicator character(50),
    diversity_rank character(50),
    remarks2 character(255),
    updated timestamp without time zone,
    web_use character(50),
    abundance_user character(50),
    abundance_time timestamp without time zone
);


CREATE TABLE expedition.abundance_by_station (
    expedition_key integer,
    station_number character(50),
    count_of_abundance_key integer
);


CREATE TABLE expedition.baudin_specimen_626 (
    gicim_origine_numeroid double precision,
    premier_collecteur character(255),
    second_collecteur character(255),
    annee_entree character(255),
    numero_entree character(50),
    gicim_poissons_numeroid double precision,
    excollection double precision,
    observations character(255),
    nom_scientific_fishbase character(50),
    url_fb character(255),
    url_mnhn character(255),
    museum_catalog_no character(50)
);


CREATE TABLE expedition.bibliography (
    bibliography_key serial PRIMARY KEY,
    author character(255),
    year character(50),
    title text,
    alternate_title character(255),
    source text,
    edition character(50),
    number_of_volumes character(50),
    publisher character(50),
    place_published character(50),
    number_of_pages character(50),
    journal_name character(250),
    volume character(50),
    number character(50),
    pages character(50),
    isbn_issn character(50),
    call_number character(50),
    accession_number character(50),
    holding_library character(250),
    holding_institution character(250),
    holding_city character(150),
    holding_country character(150),
    type character(50),
    language character(50),
    url character(255),
    pdf_file character(50),
    remarks text,
    last_updated timestamp without time zone,
    bibliography_user character(50),
    bibliography_time timestamp without time zone
);


CREATE TABLE expedition.biographies (
    biography_key serial PRIMARY KEY,
    last_name character(50),
    first_names character(50),
    title character(50),
    date_birth character(50),
    date_death character(50),
    nationality character(50),
    birth_country character(50),
    biography_detail text,
    last_updated character(50),
    biography_user character(50),
    biography_time timestamp without time zone
);


CREATE TABLE expedition.chronology (
    chronology_key integer PRIMARY KEY,
    expedition_key integer,
    station_number character(50),
    arrival_date character(50),
    departure_date character(50),
    arrival_year character(50),
    departure_year character(50),
    location_country character(50),
    location_name character(50),
    count_code character(50),
    location_latitude character(50),
    latitude_decimal double precision,
    location_longitude character(50),
    longitude_decimal double precision,
    location_name_historic character(50),
    location_longitude_historic character(50),
    location_latitude_historic character(50),
    last_updated timestamp without time zone,
    activity text,
    notes text,
    chronology_user character(50),
    chronology_time timestamp without time zone
);


CREATE TABLE expedition.collections (
    collection_key serial PRIMARY KEY,
    museum_name character(50),
    museum_address1 character(50),
    museum_address2 character(50),
    museum_city character(50),
    museum_postcode character(50),
    museum_province character(50),
    museum_country character(50),
    collection_department character(50),
    curator character(50),
    curator_telephone character(50),
    curator_email character(50),
    manager character(50),
    manager_telephone character(50),
    manager_email character(50),
    last_updated timestamp without time zone,
    collection_user character(50),
    collection_time timestamp without time zone
);


CREATE TABLE expedition.country (
    count_code character(255) NOT NULL,
    c_number double precision,
    fao_name character(255),
    saup_name character(255),
    english_name character(255),
    continent character(255)
);


CREATE TABLE expedition.defreycinet_629 (
    gicim_origine_numeroid double precision,
    premier_collecteur character(255),
    second_collecteur character(255),
    annee_entree character(255),
    numero_entree character(255),
    gicim_poissons_numeroid double precision,
    excollection double precision,
    observations text,
    catalog_no character(255),
    mnhn_link character(255),
    expedition_key character(255),
    collection_key character(255)
);


CREATE TABLE expedition.duperrey_627 (
    gicim_origine_numeroid double precision,
    premier_collecteur character(255),
    second_collecteur character(255),
    annee_entree character(255),
    numero_entree character(255),
    gicim_poissons_numeroid double precision,
    excollection double precision,
    observations character(255),
    catalog_no character(255),
    collection_number double precision,
    mnhn_url character(255)
);


CREATE TABLE expedition.durville_628 (
    gicim_origine_numeroid double precision,
    premier_collecteur character(255),
    second_collecteur character(255),
    annee_entree character(255),
    numero_entree character(255),
    gicim_poissons_numeroid double precision,
    excollection double precision,
    observations character(255),
    collection_no character(255),
    mnhn_link character(255)
);


CREATE TABLE expedition.expeditions (
    expedition_key integer PRIMARY KEY,
    year_depart integer,
    year_arrive integer,
    vessel_name character(50),
    country_commisioning character(100),
    expedition_name character(255),
    narrative text,
    type_habitat character(10),
    type_geographic character(50),
    purpose character(30),
    coverage_geographic character(50),
    coverage_general character(50),
    coverage_species_groups character(50),
    main_species_group_collected character(255),
    other_species_groups_collected character(255),
    remarks text,
    notes text,
    collection_number integer,
    last_updated timestamp without time zone,
    expedition_user character(50),
    expedition_time timestamp without time zone
);


CREATE TABLE expedition.oceans (
    ocean_id serial PRIMARY KEY,
    year_of_departure character(50),
    year_of_arrival character(50),
    port_of_departure character(255),
    country_port_of_departure character(255),
    port_of_arrival character(255),
    country_port_of_arrival character(255),
    field_01 character(255),
    country_of_vessel character(255),
    field_02 character(255),
    field_03 text,
    expedition_leader character(255),
    nationality_expedition_leader character(255),
    biography_expedition_leader text,
    field_04 text,
    field_05 character(255),
    other_officers text,
    lead_scientist character(255),
    nationality_lead_scientist character(255),
    biography_lead_scientist text,
    naturalist character(255),
    nationality_naturalist character(255),
    biography_naturalist character(255),
    botanist character(255),
    nationality_botanist character(255),
    biography_botanist character(255),
    zoologist character(255),
    nationality_zoologist character(255),
    biography_zoologist character(255),
    other_scientists character(255),
    nationality_other_scientists character(255),
    artist character(255),
    nationality_artist character(255),
    biography_artist character(255),
    name_of_museum_stocking_collection character(255),
    country_of_stocking_museum character(255),
    main_species_group_of_collection character(255),
    other_groups_collected character(255),
    comments text,
    notes text,
    ocean_user character(50),
    ocean_time timestamp without time zone
);


CREATE TABLE expedition.participants (
    participant_key serial PRIMARY KEY,
    expedition_key integer,
    biography_key integer,
    role character(50),
    date_joined_expedition character(50),
    date_left_expedition character(50),
    last_updated timestamp without time zone NOT NULL,
    participant_user character(50),
    participant_time timestamp without time zone
);


CREATE TABLE expedition.reference_index (
    reference_key integer PRIMARY KEY,
    bibliography_key integer,
    biography_key integer,
    chronology_key double precision,
    collection_key integer,
    expedition_key integer,
    participant_key integer,
    specimen_key character(50),
    reference_type character(50),
    reference_notes text,
    reference_user character(50),
    reference_time timestamp without time zone
);


CREATE TABLE expedition.specimen (
    specimen_key character(50) PRIMARY KEY,
    expedition_key integer,
    chronology_key character(50),
    collection_key character(50),
    fishbase_valid_name character(50),
    fishbase_link text,
    museum_catalog_number character(50),
    museum_link text,
    remarks character(255),
    discrepancies_with character(50),
    last_updated timestamp without time zone,
    specimen_user character(50),
    specimen_time timestamp without time zone
);


CREATE TABLE expedition.vessels (
    expedition_key integer,
    vessel_name character(50),
    year_begin integer,
    year_end integer,
    notes text,
    vessel_user character(50),
    vessel_time timestamp without time zone
);

