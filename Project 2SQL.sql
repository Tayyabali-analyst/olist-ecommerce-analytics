--SELECT COUNT(*) FROM olist_merged_cleaned;


--Which product categories generate the most revenue?
SELECT product_category_name,
       COUNT(DISTINCT order_id) AS total_orders,
       SUM(price) AS total_revenue
FROM olist_merged_cleaned
GROUP BY product_category_name
ORDER BY total_revenue DESC;

--Which Brazilian state has the highest total revenue?

SELECT customer_state,
       SUM(price) AS total_revenue
FROM olist_merged_cleaned
GROUP BY customer_state
ORDER BY total_revenue DESC;

---problem3 (expert-level): Which product categories have both above-average order value AND above-average review scores — the "premium & loved" categories?

SELECT product_category_name,
       AVG(price) AS avg_order_value,
       AVG(review_score) AS avg_review_score
FROM olist_merged_cleaned
GROUP BY product_category_name
HAVING AVG(price) > (SELECT AVG(price) FROM olist_merged_cleaned)
   AND AVG(review_score) > (SELECT AVG(review_score) FROM olist_merged_cleaned);

   ---Rank sellers by total revenue within each state — who's the #1 seller in every state?
   SELECT customer_state,
       seller_id,
       total_revenue,
       seller_rank
FROM (
    SELECT customer_state,
           seller_id,
           SUM(price) AS total_revenue,
           RANK() OVER (PARTITION BY customer_state ORDER BY SUM(price) DESC) AS seller_rank
    FROM olist_merged_cleaned
    GROUP BY customer_state, seller_id
) AS ranked_sellers
WHERE seller_rank = 1
ORDER BY total_revenue DESC;


---Which month had the highest total revenue, and how does revenue trend across all months?

SELECT FORMAT(order_purchase_timestamp, 'yyyy-MM') AS order_month,
       SUM(price) AS total_revenue
FROM olist_merged_cleaned
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month;

----Does payment installment count relate to review score?

SELECT payment_installments,
       COUNT(*) AS total_orders,
       AVG(review_score) AS avg_review_score
FROM olist_merged_cleaned
GROUP BY payment_installments
ORDER BY payment_installments;


---Which customers are your most valuable ("VIP") vs. at-risk of churning — based on how Recently they bought, how Frequently, and how Much they spent?

IF OBJECT_ID('customer_rfm_base', 'U') IS NOT NULL
    DROP TABLE customer_rfm_base;
GO

SELECT customer_unique_id,
       MAX(order_purchase_timestamp) AS last_purchase_date,
       COUNT(DISTINCT order_id) AS frequency,
       SUM(price) AS monetary_value,
       DATEDIFF(DAY, MAX(order_purchase_timestamp), '2018-10-01') AS recency_days
INTO customer_rfm_base
FROM olist_merged_cleaned
GROUP BY customer_unique_id;
GO

IF OBJECT_ID('vw_customer_rfm', 'V') IS NOT NULL
    DROP VIEW vw_customer_rfm;
GO

CREATE VIEW vw_customer_rfm AS
SELECT customer_unique_id,
       recency_days,
       frequency,
       monetary_value,
       (NTILE(4) OVER (ORDER BY recency_days ASC) +
        NTILE(4) OVER (ORDER BY frequency DESC) +
        NTILE(4) OVER (ORDER BY monetary_value DESC)) AS rfm_total_score
FROM customer_rfm_base;
GO

SELECT TOP 10 * FROM vw_customer_rfm;