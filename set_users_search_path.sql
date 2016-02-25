ALTER USER sau SET search_path TO admin, web, fao, geo, feru, expedition, allocation, tiger, topology, tiger_data, public;
ALTER USER allocation SET search_path TO allocation, admin, tiger, topology, tiger_data, public;
ALTER USER web SET search_path TO web, geo, feru, fao, expedition, admin, allocation, tiger, topology, tiger_data, public;
