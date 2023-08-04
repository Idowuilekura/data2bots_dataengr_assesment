
{{ config(materialized = 'table') }} 

WITH product_and_reviews AS (
    SELECT prod.product_id AS product_id, rev.review AS product_reviews
    FROM {{ ref('stg_reviews')}} AS rev
    INNER JOIN {{ ref('stg_dim_products')}} AS prod
    ON rev.product_id = prod.product_id
),
						products_total_reviews AS (SELECT product_id, SUM(product_reviews) total_reviews
												   FROM product_and_reviews 
												   GROUP BY product_id 
												   ORDER BY SUM(product_reviews) DESC),
					product_with_highest_review AS (SELECT product_id,total_reviews tt_review_points
													FROM products_total_reviews 
													LIMIT 1 ),
													
	highest_review_product_and_reviews AS (
	SELECT pwhr.product_id, rev.review
	FROM idowilek6169_staging.reviews AS rev
	INNER JOIN product_with_highest_review AS pwhr
	ON rev.product_id = pwhr.product_id
	),
	highest_product_review_count AS (
	SELECT product_id,review reviews, COUNT(review) review_count
	FROM highest_review_product_and_reviews
	GROUP BY product_id, review),
	
	highest_reviews_distribution AS (SELECT product_id, reviews, review_count, 
	CAST(ROUND((CAST(review_count AS DECIMAL)/ (SELECT SUM(review_count) FROM highest_product_review_count)) * 100,2) AS FLOAT) AS percentage_review_distribution
									FROM highest_product_review_count),
	series_reviews_default_count AS (SELECT generate_series(1,6) reviews_default, 0 review_count_default),
	
	-- for checking for reviews with no count
	highest_reviews_distribution_join_default AS (SELECT hrd.*, srdc.*
												  FROM series_reviews_default_count srdc
												  LEFT JOIN highest_reviews_distribution hrd
												 ON hrd.reviews = srdc.reviews_default),
	
						
	highest_product_reviews_distribution AS (SELECT MAX(product_id) product_id,  
	MAX(CASE WHEN reviews = 1 AND percentage_review_distribution IS NOT NULL THEN percentage_review_distribution
	   ELSE 0.0 END)  AS pct_one_star_review,
	MAX(CASE WHEN reviews = 2 AND percentage_review_distribution IS NOT NULL THEN percentage_review_distribution
	   ELSE 0.0 END) AS pct_two_star_review,
	   MAX(CASE WHEN reviews = 3 AND percentage_review_distribution IS NOT NULL THEN percentage_review_distribution
	   ELSE 0.0 END) AS pct_three_star_review,
	   MAX(CASE WHEN reviews = 4 AND percentage_review_distribution IS NOT NULL THEN percentage_review_distribution
	   ELSE 0.0 END) AS pct_four_star_review,
	   MAX(CASE WHEN reviews = 5 AND percentage_review_distribution IS NOT NULL THEN percentage_review_distribution
	   ELSE 0.0 END) AS pct_five_star_review
											FROM highest_reviews_distribution_join_default),
											
	highest_product_reviews_most_ordered_date AS ( 
	SELECT ord.product_id,CAST(ord.order_date AS date) most_ordered_day, COUNT(ord.order_date) number_of_orders
	FROM idowilek6169_staging.orders ord
		INNER JOIN product_with_highest_review pwhr
		ON ord.product_id = pwhr.product_id
	GROUP BY ord.product_id, ord.order_date
	ORDER BY COUNT(ord.order_date) DESC
		LIMIT 1
	), most_ordered_date_on_public_holiday AS (
		SELECT hprmod.product_id,
CASE WHEN d_date.day_of_the_week_num IN (1,2,3,4,5) AND d_date.working_day = FALSE THEN TRUE
		ELSE FALSE END AS is_public_holiday
	FROM highest_product_reviews_most_ordered_date hprmod
	INNER JOIN if_common.dim_dates d_date 
	ON d_date.calendar_dt = CAST(hprmod.most_ordered_day AS date)
	
	), highest_product_review_name AS (
	SELECT  pwhr.product_id,dp.product_name product_name
	FROM product_with_highest_review AS pwhr
	INNER JOIN if_common.dim_products AS dp 
	ON pwhr.product_id = dp.product_id ),
	
	shipment_details_highest_product_review AS (SELECT pwhr.product_id,CAST(ord.order_date AS date), ord.order_id,CAST(sd.shipment_date AS date), sd.delivery_date 
		FROM product_with_highest_review pwhr
		INNER JOIN idowilek6169_staging.orders ord
		ON pwhr.product_id = ord.product_id
	INNER JOIN idowilek6169_staging.shipment_deliveries sd
	ON ord.order_id = sd.order_id ),
	
	products_with_shipment_date AS (SELECT product_id,order_date, order_id,shipment_date, delivery_date 
								   FROM shipment_details_highest_product_review
								   WHERE shipment_date IS NOT NULL),
								   
								   products_with_early_or_late_shipments AS (
								   SELECT product_id, order_date, shipment_date, delivery_date, order_id,
									CASE WHEN ((shipment_date >= (order_date +6)) AND delivery_date IS NULL) THEN 'late shipment' 
									ELSE 'early shipment' END AS shipment_information
															  FROM products_with_shipment_date),
									early_shipment_late_shipment_count AS (SELECT product_id,shipment_information, COUNT(shipment_information) shipment_details_count
																	  FROM products_with_early_or_late_shipments
																	  GROUP BY product_id, shipment_information),
												late_or_early_shipment_default_count AS (SELECT 'early shipment' AS shipment_information_default , 0.0 shipment_default_count
																						UNION SELECT 'late shipment', 0.0
																						UNION SELECT 'no shipment', 0.0),
									early_shipment_late_shipment_with_default_count AS (SELECT loesdc.*, eslcs.*
																						
																						FROM late_or_early_shipment_default_count loesdc
																					   LEFT JOIN early_shipment_late_shipment_count eslcs
																						ON loesdc.shipment_information_default = eslcs.shipment_information
																					   ),
																						   
																					
																					   
												early_shipment_late_shipment_distribution AS (SELECT MAX(product_id) product_id, 
											MAX(CASE WHEN shipment_information_default LIKE '%early shipment%' AND shipment_details_count IS NOT NULL 
													THEN ROUND((CAST(shipment_details_count AS DECIMAL)/(SELECT COUNT(*) FROM products_with_early_or_late_shipments)) * 100,2)
													ELSE 0.0  END) AS pct_early_shipments, 
													MAX(CASE WHEN shipment_information_default LIKE '%late shipment%' AND shipment_details_count IS NOT NULL 
													THEN ROUND((CAST(shipment_details_count AS DECIMAL)/(SELECT COUNT(*) FROM products_with_early_or_late_shipments)) * 100,2)
													ELSE 0.0 END) AS pct_late_shipments
																							  
													FROM early_shipment_late_shipment_with_default_count
																							  
																							 ),								   
	all_details_joined AS (SELECT hprd.*, eslsd.*, hprmod.*, pwhr.*, modoph.*, hprn.*
	FROM highest_product_reviews_distribution hprd
	INNER JOIN early_shipment_late_shipment_distribution eslsd 
	ON hprd.product_id = eslsd.product_id 
	INNER JOIN highest_product_reviews_most_ordered_date hprmod
	ON hprmod.product_id = eslsd.product_id
	INNER JOIN product_with_highest_review pwhr
	ON pwhr.product_id = eslsd.product_id
	INNER JOIN most_ordered_date_on_public_holiday modoph
	ON eslsd.product_id = modoph.product_id 
	INNER JOIN highest_product_review_name hprn 
	ON eslsd.product_id = hprn.product_id)
	
	SELECT CURRENT_DATE AS ingestion_date,CAST(product_name AS VARCHAR), most_ordered_day, 
	CAST(is_public_holiday AS BOOLEAN), CAST(tt_review_points AS INTEGER),
	CAST(pct_one_star_review AS NUMERIC),
	CAST(pct_two_star_review AS NUMERIC),
	CAST(pct_three_star_review AS NUMERIC), 
	CAST(pct_four_star_review AS NUMERIC),
	CAST(pct_five_star_review AS NUMERIC), 
	CAST(pct_early_shipments AS NUMERIC),
	CAST(pct_late_shipments AS NUMERIC)
	FROM all_details_joined