/* DATA CLEANING & VALIDATION */

/* FOREIGN KEY HANDLING */
SET FOREIGN_KEY_CHECKS = 0;

/* ENABLE FOREIGN KEYS AGAIN */
SET FOREIGN_KEY_CHECKS = 1;

/* DATA VALIDATION */

/* Check 1: Orders without customers */
SELECT COUNT(*) AS invalid_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/* Check 2: Order_items without orders */
SELECT COUNT(*) AS invalid_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

/* Check 3: Payments without orders */
SELECT COUNT(*) AS invalid_payments
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

/* Check 4: Reviews without orders */
SELECT COUNT(*) AS invalid_reviews
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

