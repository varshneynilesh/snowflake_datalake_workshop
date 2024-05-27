ALTER DATABASE OPENSTREETMAP_DENVER RENAME TO SONRA_DENVER_CO_USA_FREE;

SELECT table_type, count(1) FROM SONRA_DENVER_CO_USA_FREE.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'DENVER'
GROUP BY 1;


SELECT * FROM SONRA_DENVER_CO_USA_FREE.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'DENVER'
AND (table_name not like '%AMENITY%' AND table_name not like '%SHOP%')


set mc_lat='-104.97300245114094';
set mc_lng='39.76471253574085';

--Confluence Park into a Variable (loc for location)
set loc_lat='-105.00840763333615'; 
set loc_lng='39.754141917497826';

select st_makepoint($mc_lat,$mc_lng) as melanies_cafe_point;
select st_makepoint($loc_lat,$loc_lng) as confluent_park_point;

select st_distance(
        st_makepoint($mc_lat,$mc_lng)
        ,st_makepoint($loc_lat,$loc_lng)
        ) as mc_to_cp;

CREATE SCHEMA mels_smoothie_challenge_db.locations;

CREATE FUNCTION mels_smoothie_challenge_db.locations.distance_to_mc(loc_lat number(38,32), loc_lng number(38, 32))
RETURNS FLOAT
AS
$$
    select st_distance(
        st_makepoint('-104.97300245114094','39.76471253574085')
        ,st_makepoint($loc_lat,$loc_lng)
        ) 
$$;

set tc_lat='-105.00532059763648'; 
set tc_lng='39.74548137398218';

select mels_smoothie_challenge_db.locations.distance_to_mc($tc_lat,$tc_lng);

CREATE VIEW mels_smoothie_challenge_db.locations.competition
AS
select * 
from SONRA_DENVER_CO_USA_FREE.DENVER.V_OSM_DEN_AMENITY_SUSTENANCE
where 
    ((amenity in ('fast_food','cafe','restaurant','juice_bar'))
    and 
    (name ilike '%jamba%' or name ilike '%juice%'
     or name ilike '%superfruit%'))
 or 

-- find the closest comptetors
SELECT
 name
 ,cuisine
 , ST_DISTANCE(
    st_makepoint('-104.97300245114094','39.76471253574085')
    , coordinates
  ) AS distance_from_melanies
 ,*
FROM  competition
ORDER by distance_from_melanies;
    (cuisine like '%smoothie%' or cuisine like '%juice%');

CREATE FUNCTION mels_smoothie_challenge_db.locations.distance_to_mc(lat_and_lng GEOGRAPHY)
RETURNS FLOAT
AS
$$
    select st_distance(
        st_makepoint('-104.97300245114094','39.76471253574085'),
        lat_and_lng
        ) 
$$;

SELECT
 name
 ,cuisine
 ,distance_to_mc(coordinates) AS distance_from_melanies
 ,*
FROM  competition
ORDER by distance_from_melanies;

select name
, distance_to_mc(coordinates) as distance_to_melanies 
, ST_ASWKT(coordinates)
from SONRA_DENVER_CO_USA_FREE.DENVER.V_OSM_DEN_SHOP
where shop='books' 
and name like '%Tattered Cover%'
and addr_street like '%Wazee%';


create view mels_smoothie_challenge_db.locations.denver_bike_shops
as
select  
*,
distance_to_mc(coordinates) as distance_to_melanies,
from SONRA_DENVER_CO_USA_FREE.DENVER.V_OSM_DEN_SHOP_OUTDOORS_AND_SPORT_VEHICLES
WHERE shop = 'bicycle';

select * from mels_smoothie_challenge_db.locations.denver_bike_shops order by distance_to_melanies;
