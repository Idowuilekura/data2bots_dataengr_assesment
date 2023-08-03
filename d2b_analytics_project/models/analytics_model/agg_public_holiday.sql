{{ config(materialized = 'table') }} 




WITH public_holiday_dates AS ( SELECT  calendar_dt, month_of_the_year_num, working_day
							  FROM {{ ref('stg_dim_dates')}} 
						  WHERE day_of_the_week_num IN (1,2,3,4,5) AND working_day = false
						  ),
						  
						  
	orders_on_public_holiday AS (SELECT ord.order_id, phd.month_of_the_year_num
								FROM 
								 public_holiday_dates AS phd 
                                 INNER JOIN {{ref('stg_orders') }} AS ord  
								 ON CAST(ord.order_date AS date) = CAST(phd.calendar_dt AS date)),
								aggregrate_orders_on_public_holiday AS (SELECT COUNT(*) total_orders, month_of_the_year_num
	FROM orders_on_public_holiday
	GROUP BY month_of_the_year_num
	ORDER BY 2 ASC ),
								
				series_month_and_default_count AS (SELECT generate_series(1,12) month_number, 0 order_count_default),
				
				
			series_month_orders_joined AS (SELECT aooph.*,smadc.*
			
			FROM series_month_and_default_count AS smadc 
			LEFT JOIN aggregrate_orders_on_public_holiday AS aooph
			ON aooph.month_of_the_year_num = smadc.month_number)
			
			SELECT CURRENT_DATE AS ingestion_date,MAX(CASE WHEN month_number = 1 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END ) AS tt_order_hol_jan, 
			MAX(CASE WHEN month_number = 2 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_feb,
			MAX(CASE WHEN month_number = 3 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_mar,
			MAX(CASE WHEN month_number = 4 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_apr,
			MAX(CASE WHEN month_number = 5 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_may,
			MAX(CASE WHEN month_number = 6 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_jun,
			MAX(CASE WHEN month_number = 7 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_jul,
			MAX(CASE WHEN month_number = 8 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_aug,
			MAX(CASE WHEN month_number = 9 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_sep,
			MAX(CASE WHEN month_number = 10 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_oct,
			MAX(CASE WHEN month_number = 11 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_nov,
			MAX(CASE WHEN month_number = 12 AND total_orders IS NOT NULL THEN total_orders
			ELSE order_count_default END) AS tt_order_hol_dec
			
			FROM series_month_orders_joined
			
							