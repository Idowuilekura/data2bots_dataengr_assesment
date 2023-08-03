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
											FROM highest_reviews_distribution_join_default)