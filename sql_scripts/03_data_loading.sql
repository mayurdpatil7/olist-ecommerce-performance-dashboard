USE olist_ecommerce;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
order_id,
customer_id,
order_status,
@order_purchase_timestamp,
@order_approved_at,
@order_delivered_carrier_date,
@order_delivered_customer_date,
@order_estimated_delivery_date
)
SET
order_purchase_timestamp = STR_TO_DATE(NULLIF(@order_purchase_timestamp,''), '%d-%m-%Y %H:%i'),
order_approved_at = STR_TO_DATE(NULLIF(@order_approved_at,''), '%d-%m-%Y %H:%i'),
order_delivered_carrier_date = STR_TO_DATE(NULLIF(@order_delivered_carrier_date,''), '%d-%m-%Y %H:%i'),
order_delivered_customer_date = STR_TO_DATE(NULLIF(@order_delivered_customer_date,''), '%d-%m-%Y %H:%i'),
order_estimated_delivery_date = STR_TO_DATE(NULLIF(@order_estimated_delivery_date,''), '%d-%m-%Y %H:%i');

SELECT COUNT(*) FROM orders;
SELECT order_purchase_timestamp FROM orders LIMIT 5;

SET FOREIGN_KEY_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 0;

---order_items_ETL 
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
order_id,
order_item_id,
product_id,
seller_id,
@shipping_limit_date,
price,
freight_value
)
SET
shipping_limit_date = STR_TO_DATE(NULLIF(@shipping_limit_date,''), '%d-%m-%Y %H:%i');

SET FOREIGN_KEY_CHECKS = 1;
SELECT COUNT(*) FROM order_items;
SELECT shipping_limit_date FROM order_items LIMIT 5;

SELECT COUNT(*) AS invalid_items
FROM order_items oi
LEFT JOIN orders o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

/* order_payment_LOADING */

SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) FROM sellers;

/* Quick Sanity Check */
SELECT * FROM sellers LIMIT 5;

SET FOREIGN_KEY_CHECKS = 0;

SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
product_id,
product_category_name,
@product_name_length,
@product_description_length,
@product_photos_qty,
@product_weight_g,
@product_length_cm,
@product_height_cm,
@product_width_cm
)
SET
product_name_length =
NULLIF(@product_name_length,''),

product_description_length =
NULLIF(@product_description_length,''),

product_photos_qty =
NULLIF(@product_photos_qty,''),

product_weight_g =
NULLIF(@product_weight_g,''),

product_length_cm =
NULLIF(@product_length_cm,''),

product_height_cm =
NULLIF(@product_height_cm,''),

product_width_cm =
NULLIF(@product_width_cm,'');

SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) FROM products;

/* Loading of order Review dataset */

SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
review_id,
order_id,
review_score,
review_comment_title,
review_comment_message,
@review_creation_date,
@review_answer_timestamp
)
SET
review_creation_date =
STR_TO_DATE(NULLIF(@review_creation_date,''), '%d-%m-%Y %H:%i'),

review_answer_timestamp =
STR_TO_DATE(NULLIF(@review_answer_timestamp,''), '%d-%m-%Y %H:%i');

SET FOREIGN_KEY_CHECKS = 1;
SELECT COUNT(*) FROM order_reviews;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/* VERIFICATION */
SELECT COUNT(*) FROM product_category_translation;
SELECT * FROM product_category_translation LIMIT 5;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/* VERIFICATION */
SELECT COUNT(*) FROM geolocation;
SELECT * FROM geolocation LIMIT 5;