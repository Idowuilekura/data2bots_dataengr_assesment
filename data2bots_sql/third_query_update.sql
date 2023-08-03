WITH product_and_reviews AS (
    SELECT prod.product_id AS product_id, rev.review AS product_reviews
    FROM idowilek6169_staging.reviews AS rev 
    INNER JOIN if_common.dim_products AS prod
    ON rev.product_id = prod.product_id
),
						products_total_reviews AS (SELECT product_id, SUM(product_reviews) total_reviews
												   FROM product_and_reviews 
												   GROUP BY product_id 
												   ORDER BY SUM(product_reviews) DESC),
					product_with_highest_review AS (SELECT product_id, total_reviews
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
	CAST(ROUND((review_count/ (SELECT SUM(review_count) FROM highest_product_review_count)) * 100,2) AS FLOAT) AS percentage_review_distribution
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
	SELECT ord.product_id,ord.order_date, COUNT(ord.order_date) number_of_orders
	FROM idowilek6169_staging.orders ord
		INNER JOIN product_with_highest_review pwhr
		ON ord.product_id = pwhr.product_id
	GROUP BY ord.product_id, ord.order_date
	ORDER BY COUNT(order_date) DESC
		LIMIT 1
	), most_ordered_date_on_public_holiday AS (
		SELECT hprmod.product_id,d_date.working_day, d_date.calendar_dt
	FROM highest_product_reviews_most_ordered_date hprmod
	INNER JOIN if_common.dim_dates d_date 
	ON d_date.calendar_dt = CAST(hprmod.order_date AS date)
	), highest_product_review_name AS (
	SELECT  pwhr.product_id,dp.product_name
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
															  FROM products_with_shipment_date)
	
	SELECT * FROM products_with_early_or_late_shipments;