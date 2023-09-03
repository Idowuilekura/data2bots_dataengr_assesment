
-- A join of the order and shipment 
WITH orders_shipment_data AS (SELECT ord.order_id, CAST(ord.order_date AS date) AS order_date, 
								  CAST(sd.shipment_date AS date) AS shipment_date, 
								  CAST(sd.delivery_date AS date) AS delivery_date
								  FROM idowilek6169_staging.orders AS ord
								  INNER JOIN idowilek6169_staging.shipment_deliveries AS sd
								  ON ord.order_id = sd.order_id),
								  				late_orders_with_shipments AS (SELECT order_id, order_date, shipment_date, delivery_date
															  FROM orders_shipment_data 
															  WHERE (shipment_date >= (order_date +6)) AND delivery_date IS NULL),
								count_of_late_shipment_orders AS (SELECT 1 common_number, COALESCE(COUNT(order_id),0) AS tt_late_shipments
																 FROM late_orders_with_shipments ),
																 
undelivered_shipment_orders AS (SELECT order_id
							   FROM orders_shipment_data 
							   WHERE (delivery_date IS NULL) AND 
								(shipment_date IS NULL) AND (order_date + 15) = CAST('2022-09-05' AS date)),
								
								count_of_undelivered_shipment_orders AS (SELECT 1 common_number, COALESCE(COUNT(order_id),0) AS tt_undelivered_items
																 FROM undelivered_shipment_orders )
									
		SELECT CURRENT_DATE AS ingestion_date,colso.tt_late_shipments,  couso.tt_undelivered_items
		FROM count_of_late_shipment_orders colso
		INNER JOIN count_of_undelivered_shipment_orders couso 
		ON colso.common_number = couso.common_number;