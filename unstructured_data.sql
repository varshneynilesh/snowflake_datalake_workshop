USE DATEBASE ZENAS_ATHLEISURE_DB;

USE SCHEMA ZENAS_ATHLEISURE_DB.PRODUCTS;

LIST @ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING;

LIST @ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_SNEAKERS;

SELECT metadata$filename, COUNT(metadata$file_row_number)
    FROM @ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING
GROUP BY 1;

--Directory Tables
select * from directory(@ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING);

alter stage ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING set directory = (enable = true);

alter stage ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING refresh;

select * from directory(@ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING);

select UPPER(RELATIVE_PATH) as uppercase_filename
, REPLACE(uppercase_filename,'/') as no_slash_filename
, REPLACE(no_slash_filename,'_',' ') as no_underscores_filename
, REPLACE(no_underscores_filename,'.PNG') as just_words_filename
from directory(@ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING);


select REPLACE(REPLACE(REPLACE(UPPER(RELATIVE_PATH),'/'),'_',' '),'.PNG') as product_name
from directory(@ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING);

create or replace TABLE ZENAS_ATHLEISURE_DB.PRODUCTS.SWEATSUITS (
	COLOR_OR_STYLE VARCHAR(25),
	DIRECT_URL VARCHAR(200),
	PRICE NUMBER(5,2)
);

insert into  ZENAS_ATHLEISURE_DB.PRODUCTS.SWEATSUITS 
          (COLOR_OR_STYLE, DIRECT_URL, PRICE)
values
('90s', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/90s_tracksuit.png',500)
,('Burgundy', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/burgundy_sweatsuit.png',65)
,('Charcoal Grey', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/charcoal_grey_sweatsuit.png',65)
,('Forest Green', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/forest_green_sweatsuit.png',65)
,('Navy Blue', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/navy_blue_sweatsuit.png',65)
,('Orange', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/orange_sweatsuit.png',65)
,('Pink', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/pink_sweatsuit.png',65)
,('Purple', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/purple_sweatsuit.png',65)
,('Red', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/red_sweatsuit.png',65)
,('Royal Blue',	'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/royal_blue_sweatsuit.png',65)
,('Yellow', 'https://uni-klaus.s3.us-west-2.amazonaws.com/clothing/yellow_sweatsuit.png',65);

-- join directory table with normal table
SELECT 
    color_or_style,
    direct_url,
    price,
    size as image_size,
    last_modified
FROM zenas_athleisure_db.products.sweatsuits s
JOIN directory(@zenas_athleisure_db.products.uni_klaus_clothing) d
ON (split_part(direct_url,'/',-1)) =  replace(relative_path,'/');

CREATE OR REPLACE VIEW zenas_athleisure_db.products.catalog
AS
SELECT 
    color_or_style,
    direct_url,
    price,
    size as image_size,
    last_modified image_last_modified,
    sizes_available
FROm zenas_athleisure_db.products.sweatsuits s
JOIN directory(@zenas_athleisure_db.products.uni_klaus_clothing) d
ON (split_part(direct_url,'/',-1)) =  replace(relative_path,'/')
cross join zenas_athleisure_db.products.sweatsuit_sizes;


-- Add a table to map the sweat suits to the sweat band sets
CREATE TABLE zenas_athleisure_db.products.upsell_mapping
(
    sweatsuit_color_or_style varchar(25),
    upsell_product_code varchar(10)
);

--populate the upsell table
INSERT INTO zenas_athleisure_db.products.upsell_mapping
(sweatsuit_color_or_style,upsell_product_code 
)
VALUES
('Charcoal Grey','SWT_GRY')
,('Forest Green','SWT_FGN')
,('Orange','SWT_ORG')
,('Pink', 'SWT_PNK')
,('Red','SWT_RED')
,('Yellow', 'SWT_YLW');


CREATE VIEW zenas_athleisure_db.products.catalog_for_website as 
SELECT 
    color_or_style,
    price,
    direct_url,
    size_list,
    coalesce('BONUS: ' ||  headband_description || ' & ' || wristband_description, 'Consider White, Black or Grey Sweat Accessories') as upsell_product_desc
FROM
(   SELECT 
        color_or_style, 
        price, 
        direct_url, 
        image_last_modified,
        image_size,
        listagg(sizes_available, ' | ') within group (order by sizes_available) as size_list
    FROM zenas_athleisure_db.products.catalog
    GROUP BY color_or_style, price, direct_url, image_last_modified, image_size
) c
LEFT JOIN upsell_mapping u
ON u.sweatsuit_color_or_style = c.color_or_style
LEFT JOIN sweatband_coordination sc
ON sc.product_code = u.upsell_product_code
LEFT JOIN sweatband_product_line spl
ON spl.product_code = sc.product_code
WHERE price < 200 -- high priced items like vintage sweatsuits aren't a good fit for this website
AND image_size < 1000000 -- large images need to be processed to a smaller size
;




