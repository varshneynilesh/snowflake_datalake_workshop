ALTER VIEW MELS_SMOOTHIE_CHALLENGE_DB.TRAILS.CHERRY_CREEK_TRAIL
RENAME TO MELS_SMOOTHIE_CHALLENGE_DB.TRAILS.V_CHERRY_CREEK_TRAIL;

CREATE OR REPLACE EXTERNAL TABLE MELS_SMOOTHIE_CHALLENGE_DB.TRAILS.T_CHERRY_CREEK_TRAIL(
	my_filename varchar(50) as (metadata$filename::varchar(50))
) 
location= @MELS_SMOOTHIE_CHALLENGE_DB.TRAILS.trails_parquet
auto_refresh = true
file_format = (type = parquet);


select get_ddl('view','mels_smoothie_challenge_db.trails.v_cherry_creek_trail');

create or replace view V_CHERRY_CREEK_TRAIL(
	POINT_ID,
	TRAIL_NAME,
	LNG,
	LAT,
	COORD_PAIR
) as
SELECT  
 $1:sequence_1 as point_id,
 $1:trail_name::varchar as trail_name,
 $1:latitude::number(11,8) as lng,
 $1:longitude::number(11,8) as lat,
 lng||' '||lat as coord_pair
FROM @trails_parquet
(file_format => ff_parquet)
ORDER BY point_id;

create or replace external table mels_smoothie_challenge_db.trails.T_CHERRY_CREEK_TRAIL(
	POINT_ID number as ($1:sequence_1::number),
	TRAIL_NAME varchar(100) as  ($1:trail_name::varchar),
	LNG number(11,8) as ($1:latitude::number(11,8)),
	LAT number(11,8) as ($1:longitude::number(11,8)),
	COORD_PAIR varchar(50) as (lng::varchar||' '||lat::varchar)
) 
location= @mels_smoothie_challenge_db.trails.trails_parquet
auto_refresh = true
file_format = mels_smoothie_challenge_db.trails.ff_parquet;


CREATE MATERIALIZED VIEW mels_smoothie_challenge_db.trails.SMV_CHERRY_CREEK_TRAIL
AS
SELECT * FROM mels_smoothie_challenge_db.trails.T_CHERRY_CREEK_TRAIL;

SELECT 
* FROM mels_smoothie_challenge_db.trails.SMV_CHERRY_CREEK_TRAIL;
