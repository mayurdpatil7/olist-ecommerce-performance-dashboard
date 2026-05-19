USE olist_ecommerce;

CREATE INDEX idx_orders_order_id
ON orders(order_id);

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX idx_orders_status
ON orders(order_status);

CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

CREATE INDEX idx_products_product_id
ON products(product_id);

CREATE INDEX idx_products_category
ON products(product_category_name);

CREATE INDEX idx_category_translation
ON product_category_translation(product_category_name);