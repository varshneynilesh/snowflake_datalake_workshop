USE ROLE SYSADMIN;

CREATE DATABASE mels_smoothie_challenge_db;

DROP SCHEMA mels_smoothie_challenge_db.public;

CREATE SCHEMA mels_smoothie_challenge_db.trails;

CREATE OR REPLACE STAGE mels_smoothie_challenge_db.trails.trails_geojson 
	URL = 's3://uni-lab-files-more/dlkw/trails/trails_geojson' ;

LIST @mels_smoothie_challenge_db.trails.trails_geojson;
    
CREATE STAGE mels_smoothie_challenge_db.trails.trails_parquet 
	URL = 's3://uni-lab-files-more/dlkw/trails/trails_parquet'; 

LIST @mels_smoothie_challenge_db.trails.trails_parquet;

CREATE FILE FORMAT mels_smoothie_challenge_db.trails.ff_json
    type = JSON;

CREATE FILE FORMAT mels_smoothie_challenge_db.trails.ff_parquet
    type = PARQUET;

SELECT $1 FROM @mels_smoothie_challenge_db.trails.trails_geojson
(file_format => mels_smoothie_challenge_db.trails.ff_json);

SELECT $1 FROM @mels_smoothie_challenge_db.trails.trails_parquet
(file_format => mels_smoothie_challenge_db.trails.ff_parquet);

CREATE OR REPLACE VIEW mels_smoothie_challenge_db.trails.cherry_creek_trail
AS
SELECT  
 $1:sequence_1 as point_id,
 $1:trail_name::varchar as trail_name,
 $1:latitude::number(11,8) as lng,
 $1:longitude::number(11,8) as lat,
 lng||' '||lat as coord_pair
FROM @trails_parquet
(file_format => ff_parquet)
ORDER BY point_id;


select 
'LINESTRING('||
listagg(coord_pair, ',') 
within group (order by point_id)
||')' as my_linestring
from cherry_creek_trail
--where point_id <= 10
group by trail_name;

-- JSON data
SELECT $1 FROM @mels_smoothie_challenge_db.trails.trails_geojson
(file_format => mels_smoothie_challenge_db.trails.ff_json);



CREATE OR REPLACE VIEW mels_smoothie_challenge_db.trails.denver_area_trails
AS
select
$1:features[0]:properties:Name::string as feature_name
,$1:features[0]:geometry:coordinates::string as feature_coordinates
,$1:features[0]:geometry::string as geometry
,$1:features[0]:properties::string as feature_properties
,$1:crs:properties:name::string as specs
,$1 as whole_object
from @trails_geojson (file_format => ff_json);

-- calculate length of the trail
select 
'LINESTRING('||
listagg(coord_pair, ',') 
within group (order by point_id)
||')' as my_linestring
,st_length(TO_GEOGRAPHY(my_linestring)) as length_of_trail --this line is new! but it won't work!
from cherry_creek_trail
group by trail_name;

SELECT  
    feature_name,
    st_length(to_geography(geometry)) trail_length
FROM mels_smoothie_challenge_db.trails.denver_area_trails;

select get_ddl('view', 'denver_area_trails')

create or replace view DENVER_AREA_TRAILS
AS
select
$1:features[0]:properties:Name::string as feature_name
,$1:features[0]:geometry:coordinates::string as feature_coordinates
,$1:features[0]:geometry::string as geometry
, st_length(to_geography(GEOMETRY)) trail_length
,$1:features[0]:properties::string as feature_properties
,$1:crs:properties:name::string as specs
,$1 as whole_object
from @trails_geojson (file_format => ff_json);

select * from mels_smoothie_challenge_db.trails.denver_area_trails;

create view mels_smoothie_challenge_db.trails.DENVER_AREA_TRAILS_2 as
select 
trail_name as feature_name
,'{"coordinates":['||listagg('['||lng||','||lat||']',',')||'],"type":"LineString"}' as geometry
,st_length(to_geography(geometry)) as trail_length
from cherry_creek_trail
group by trail_name;


select feature_name, geometry, trail_length
from DENVER_AREA_TRAILS
union all
select feature_name, geometry, trail_length
from DENVER_AREA_TRAILS_2;

create or replace view mels_smoothie_challenge_db.trails.trails_and_boundaries
AS
select feature_name
, to_geography(geometry) as my_linestring
, st_xmin(my_linestring) as min_eastwest
, st_xmax(my_linestring) as max_eastwest
, st_ymin(my_linestring) as min_northsouth
, st_ymax(my_linestring) as max_northsouth
, trail_length
from DENVER_AREA_TRAILS
union all
select feature_name
, to_geography(geometry) as my_linestring
, st_xmin(my_linestring) as min_eastwest
, st_xmax(my_linestring) as max_eastwest
, st_ymin(my_linestring) as min_northsouth
, st_ymax(my_linestring) as max_northsouth
, trail_length
from DENVER_AREA_TRAILS_2;

select 'POLYGON(('|| 
    min(min_eastwest)||' '||max(max_northsouth)||','|| 
    max(max_eastwest)||' '||max(max_northsouth)||','||
    max(max_eastwest)||' '||min(min_northsouth)||','|| 
    min(min_eastwest)||' '||min(min_northsouth)||'))' as my_polygon 
from trails_and_boundaries;

    
