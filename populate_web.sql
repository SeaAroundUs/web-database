/*
INSERT INTO web.catch_type(catch_type_id, name)
VALUES (1, 'reported landings'),
       (2, 'discards'),               
       (3, 'unreported landings');

INSERT INTO web.sector_type(sector_type_id, name)
VALUES (1, 'Industrial'),
       (2, 'Subsistence'),
       (3, 'Artisanal'),
       (4, 'Recreational');

INSERT INTO web.entity_layer(entity_layer_id, name)
VALUES  (1, 'eez'),
        (2, 'highsea'),
        (3, 'lme'),
        (4, 'rfmo'),
        (5, 'baltic'),
        (6, 'global'),
        (7, 'bob'),
        (8, 'mariculture'),
        (9, 'persiangulf'),
        (10, 'tropics'),
        (11, '[for allocation only]'),
        (12, 'allocation_eez'),
        (14, 'ifa'),
        (15, '[ICES_EEZ_HS combo]'),
        (16, '[EEZ_BigCell_combo]'),
        (100, 'fishing entity'),
        (200, 'area bucket'),
        (300, 'taxon'),
        (400, 'area key'),
        (500, 'commercial group'),
        (600, 'functional group'),
        (700, 'reporting status'),
        (800, 'catch type'),
        (900, 'fao')
        ;
*/
/*
INSERT INTO web.area_bucket_type(marine_layer_id, name, area_id_type, description)
VALUES (1, 'climate zone', 'eez id', null),
       (1, 'by jurisdiction', 'eez id', null),               
       (1, 'immediate neighbors', 'eez id', null),
       (1, 'ocean basin', 'fao area id', null),
       (1, 'regional eez''s', 'eez id', null),
       (3, 'climate zone', 'lme id', null),
       (3, 'ocean basin', 'fao area id', null)
       (6, 'fao area', 'area key', 'high seas plus eez intersections');

INSERT INTO web.area_bucket(area_bucket_type_id, area_id_reference, name, area_id_bucket)
VALUES (web.lookup_area_bucket_type(1, 'climate zone'), null, 'Polar', ARRAY[334,124,304,352,74,744,645,649,650,239,950,841]),
       (web.lookup_area_bucket_type(1, 'climate zone'), null, 'Subtropical', ARRAY[8,12,38,574,44,48,60,70,100,153,155,191,197,198,818,899,250,895,274,268,300,900,364,368,376,380,902,901,390,410,414,422,434,470,891,504,504,732,516,555,620,622,621,642,647,684,705,710,710,903,723,724,760,788,794,793,804,612,856,858,852,848,862]),
       (web.lookup_area_bucket_type(1, 'climate zone'), null, 'Temperate', ARRAY[32,37,56,124,124,152,208,208,233,234,246,250,896,897,666,278,279,372,408,428,440,528,554,578,616,648,649,711,724,752,752,826,830,238,841,851]),
       (web.lookup_area_bucket_type(1, 'climate zone'), null, 'Tropical', ARRAY[24,28,36,162,166,50,52,84,204,76,76,76,77,96,116,120,132,156,344,170,170,174,184,178,180,188,188,384,192,262,212,214,218,219,818,222,226,111,583,242,898,312,254,474,175,540,258,638,251,312,312,876,266,270,288,308,320,320,324,624,328,332,340,340,356,357,362,361,362,364,376,388,393,393,400,404,296,296,296,430,450,460,461,463,462,584,478,480,484,484,500,508,104,520,533,533,533,528,528,772,558,558,566,570,512,512,586,585,591,591,598,604,608,634,882,678,683,686,690,694,702,90,706,144,659,662,670,736,740,157,834,764,764,626,768,776,780,796,798,784,660,855,136,86,654,92,16,316,842,488,580,850,848,548,862,704,887]),
       (web.lookup_area_bucket_type(1, 'ocean basin'), null, 'Atlantic', ARRAY[21, 27, 31, 34, 41, 47]),
       --(web.lookup_area_bucket_type(1, 'ocean basin'), null, 'Mediterranean and Black Sea', ARRAY[37]),
       (web.lookup_area_bucket_type(1, 'ocean basin'), null, 'Pacific', ARRAY[61, 67, 71, 77, 81, 87]),
       (web.lookup_area_bucket_type(1, 'ocean basin'), null, 'Indian', ARRAY[51, 57]),
       (web.lookup_area_bucket_type(1, 'ocean basin'), null, 'Artic', ARRAY[18]),
       (web.lookup_area_bucket_type(1, 'ocean basin'), null, 'Antarctic', ARRAY[48, 58, 88]),
       (web.lookup_area_bucket_type(1, 'regional eez''s'), null, 'Black Sea EEZs', ARRAY[804, 642, 100, 794, 268, 647]),
       (web.lookup_area_bucket_type(1, 'regional eez''s'), null, 'Baltic Sea EEZs', ARRAY[752, 246, 651, 233, 428, 440, 648, 616, 208, 278]),
       (web.lookup_area_bucket_type(1, 'regional eez''s'), null, 'Mediterranean EEZs', ARRAY[724, 504, 12, 788, 470, 434, 818, 274, 376, 422, 760, 793, 300, 8, 891, 191, 380, 250]),
       
       (web.lookup_area_bucket_type(3, 'climate zone'), null, 'Polar', ARRAY[52,61,20,55,18,66,64,1,56,19,63,59,58,57,54,53]),
       (web.lookup_area_bucket_type(3, 'climate zone'), null, 'Subtropical', ARRAY[29,62,3,27,41,47,4,13,25,49,26,15,43,6,44]),
       (web.lookup_area_bucket_type(3, 'climate zone'), null, 'Temperate', ARRAY[65,23,24,60,2,9,46,22,7,21,51,14,8,50,42,48]),
       (web.lookup_area_bucket_type(3, 'climate zone'), null, 'Tropical', ARRAY[30,32,34,12,16,28,5,35,38,10,39,17,40,45,11,33,31,36,37]),
       (web.lookup_area_bucket_type(3, 'ocean basin'), null, 'Atlantic', ARRAY[21, 27, 31, 34, 41, 47]),
       --(web.lookup_area_bucket_type(3, 'ocean basin'), null, 'Mediterranean and Black Sea', ARRAY[37]),
       (web.lookup_area_bucket_type(3, 'ocean basin'), null, 'Pacific', ARRAY[61, 67, 71, 77, 81, 87]),
       (web.lookup_area_bucket_type(3, 'ocean basin'), null, 'Indian', ARRAY[51, 57]),
       (web.lookup_area_bucket_type(3, 'ocean basin'), null, 'Artic', ARRAY[18]),
       (web.lookup_area_bucket_type(3, 'ocean basin'), null, 'Antarctic', ARRAY[48, 58, 88])
       ;

TRUNCTE web.area_invisible;
INSERT INTO web.area_invisible(marine_layer_id, main_area_id, sub_area_id)
VALUES
(1, 100, 0),
(1, 144, 0),
(1, 356, 0),
(1, 462, 0),
(1, 702, 0),
(1, 926, 0);
*/

