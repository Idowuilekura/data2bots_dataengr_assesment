# Data2bots Data Engineering Assessment Solution

## ABC Limited Data Engineering Pipeline

This repository documents the solution for the Data2bots data engineering assessment for ABC Limited. ABC Limited is a fast-moving company dealing in day-to-day goods and generates a massive amount of data. The company aims to leverage data engineering and analytics to gain actionable insights from their data. Every day, the company's data lake receives orders, product reviews, and shipment details. The stakeholders have assigned the task of ingesting these files into a data warehouse and writing specific queries to extract valuable information.

### Tools Selection

To address the requirements, the following tools have been selected:

1. Apache Airflow: For orchestrating the data pipeline and automating the entire process.
2. Python: For writing scripts to automate data ingestion and processing.
3. SQL: For writing queries to extract information about orders on public holidays per month, total late shipments, undelivered items, and the best performing product.
4. Data Build Tools (DBT): For version control and scalability of the analytical queries.
5. Docker: For containerizing the entire workflow, ensuring portability and ease of deployment on different systems.

### Understanding the Different Processes

The data pipeline consists of several stages, each serving a specific purpose:

#### 1. Extract Process

The first stage involves connecting to the S3 bucket, downloading each file, and storing them on the local system. While implementing the extract process, an issue was encountered with the orders data due to a spelling error in the file name. To overcome this, a file listing mechanism was employed to locate and download the files successfully.

#### 2. Load Process

The loading process is crucial to attach an ingestion date to each record in the data warehouse, as the files arrive daily. To maintain data integrity and ensure consistency, the tables are recreated whenever new data is ingested into the data warehouse. All data were loaded into the staging schema on the data warehouse.

#### 3. Analytic Process

This stage focuses on performing analytics and transformations on the ingested data. Specific SQL queries are written to retrieve information on orders made on public holidays per month, total late shipments, undelivered items, and the best-performing product. By using DBT, the analytical development process becomes more streamlined and supports version control, making it scalable and easier to manage.

The different analytical queries are explained below:

##### 1. Aggregate of Orders Made on Public Holidays per Month

To get the aggregate of orders made on public holidays per month, a SQL query was used to select public holiday dates from the `if_common.dim_dates` table and join it with all orders using an inner join based on the date. This ensures that only orders made on public holidays are selected. The orders made on public holidays are then aggregated by utilizing the SQL `COUNT` function and grouping them by month number. To account for months without any public holiday orders, the query generates a series of values from 1 to 12 with corresponding zeros. The default order count is left-joined with the aggregated table to ensure that months without public holiday orders have null values. Finally, a case statement is used to unpivot the table and create the final result, with the ingestion date set as the current date since the ingestion and analytics are performed daily.

##### 2. Total Number of Late and Undelivered Shipments

To determine the total number of late and undelivered shipments, the query first joins the orders table with the shipment table using the `order_id` as a key with an inner join. This ensures that only orders with shipment information are selected. The query then uses the `COUNT` function with a `WHERE` filter to count orders where the shipment date is greater than 6 days after the order date and the delivery date is null, signifying an undelivered shipment. Similarly, the count of undelivered shipments is obtained by filtering for shipments with a null shipment date and the current date is 15 days after the order date. The two results are joined together using a common key of `1`.

##### 3. Best Performing Product

The query for the best performing product retrieves various information, including the highest number of reviews, the date the product was ordered, if it was ordered on a public holiday, the total review points, the percentage distribution of the review points, and the percentage distribution of early shipments to late shipments for the particular product.

When determining the product with the highest reviews, two methods were considered:

- Counting the number of reviews for each product and finding the maximum count. This approach would identify the product that received the most reviews.

- Summing all the reviews for each product and finding the maximum sum. This approach was chosen to ensure that only one product emerges as the best performer, even in the rare case of two products having the same sum of reviews. In such a scenario, this approach guarantees a unique product as the result.

After careful consideration, and selecting the preffered method. The implementation involved summing all the reviews, grouping the results by the product_id, arranging the data based on the sum of reviews in descending order, and finally selecting the product with the highest sum.

By opting for the second approach, the solution ensures a clear and unambiguous outcome when identifying the product with the highest reviews. In cases where multiple products share the same review count, this approach guarantees a single product as the best performer, providing a more definitive and accurate result
To determine the product with the highest reviews, the query first joins each product with the specific reviews using an inner join based on the `product_id`. The result is then grouped by the product ID, and the products are arranged in descending order of the sum of their reviews. The product with the highest sum of reviews is selected.

The next part of the query involves calculating the distribution of reviews for the product. This is done by counting the number of reviews per review type and dividing each count by the total count of all reviews for the product with the highest number of reviews. The query ensures that no review type has a null value by generating a series of values from 1 to 5 with a default value of zero.

The default review distribution is then joined with the original distribution, and a case statement is used to replace any null percentage distribution with a value of 0.0.

The most ordered date for the product is obtained by joining the order table with the product with the highest reviews using the `product_id` as the key. The resulting table is grouped by the order date, and the count of orders made per day is calculated. The result is ordered in descending order of the count of orders, and the first result is selected. To check if the most ordered date falls on a public holiday, the `if_common.dim_date` table is joined with the most ordered day, and a case statement is used to check if the day is a public holiday or not. If the day is a public holiday, the column value is set to `True`; otherwise, it is set to `False`.

The name of the product is obtained by joining the product with the highest reviews with the `if_common.dim_products` table, and the product name is selected based on the `product_id`.

For the percentage of late to early shipments, the query first selects only shipment details that do not contain `null` as the shipment date, indicating delivered products. The delivered shipments are then classified as late or early shipments based on whether the shipment date is greater than the order date + 6 days. The query also ensures that neither the early nor late shipment counts are zero, in case there are no late or early shipments. Default values of 0.0 are used for the early shipment and late shipment counts.

#### 4. Exporting the Best Products

To provide the stakeholders with actionable insights, the analysis results of the best-performing product are exported to a user-friendly CSV format, allowing for easy visualization and decision-making. The best product CSV is read using Python SQLAlchemy and then exported to the public S3 bucket.

#### 5. Dockerizing the Entire Workflow

To ensure the entire workflow can run on any system, Docker is employed to containerize the data engineering pipeline. This allows for easy distribution, seamless execution, and consistency across different environments.

Overall, the implemented data engineering pipeline enables ABC Limited to efficiently process and analyze their data, providing valuable insights for their day-to-day activities and business decisions.



#### Things that were not implemented due to time
- Writing test for the pipeline and using CI/CD
- using Kubernetes for orchestrating the Docker container 

