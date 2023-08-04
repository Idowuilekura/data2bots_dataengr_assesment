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

DBT Great Expectations was used for writing test to ensure that there are no nulls and that the correct data type are specified. 
#### 4. Exporting the Best Products

To provide the stakeholders with actionable insights, the analysis results of the best-performing product are exported to a user-friendly CSV format, allowing for easy visualization and decision-making. The best product CSV is read using Python SQLAlchemy and then exported to the public S3 bucket.

#### 5. Orchestrating the Pipeline with Airflow 
The pipeline was orchestrated and scheduled using Apache Airflow to ensure daily data retrieval and maintain pipeline reliability. By leveraging Airflow's capabilities, the pipeline was scheduled for daily execution, guaranteeing a consistent flow of data.

In the Airflow pipeline, the process flows through several stages. First, data extraction is performed to gather the required data. Once the extraction is complete, the data is loaded into the target destination. Subsequently, DBT (Data Build Tool) is utilized to execute the analytical processes on the loaded data. Finally, the pipeline concludes with the export of the refined data, ensuring that the best quality data is made available for further use. The pipeline is shown below: 

`extract_data >> load_data >> run_analytics_with_DBT >> export_best_data`
#### 6. Dockerizing the Entire Workflow

To ensure the entire workflow can run on any system, Docker is employed to containerize the data engineering pipeline. This allows for easy distribution, seamless execution, and consistency across different environments.

Overall, the implemented data engineering pipeline enables ABC Limited to efficiently process and analyze their data, providing valuable insights for their day-to-day activities and business decisions.


### Running the Pipeline

To run the pipeline, follow these steps after ensuring you have Docker installed on your system and have cloned this repository.

#### Step 1: Build the Extended Airflow Image

The Airflow image has been extended to include additional tools like DBT that are not installed in the base image. To build the extended image, navigate to the cloned repository folder in your terminal and run the following command:

```
docker build -t datatwobotsairflowimage:latest .
```

This command will build the image and tag it as `datatwobotsairflowimage:latest`.

#### Step 2: Initialize the Airflow Webserver

Before initializing the Airflow Webserver, you need to ensure that the `AIRFLOW_UID` environment variable is set to `5000`. To do this, run the following command:

```
echo -e "AIRFLOW_UID=$(id -u)" > .env
```

This command sets the `AIRFLOW_UID` to the current user's ID to ensure proper permissions within the Docker container.

Next, you should initialize the Airflow database by running the following command:

```
docker-compose up airflow-init
```

This command will create the necessary tables in the database for Airflow to work.

#### Step 3: Get Airflow Up and Running

To start the Airflow services and get it up and running, run the following command:

```
docker-compose up
```

This command will start all the services defined in the `docker-compose.yml` file. Airflow will be accessible through the web interface, which you can access using the specified URL.

To run the pipeline manually, follow these steps:

1. **Login into the Airflow Webserver**: Open your web browser and navigate to the Airflow Webserver using the provided URL: `http://your-airflow-server-address:8080`.

2. **Authenticate**: Enter the following credentials to log in to the Airflow Webserver:  
   Username: `airflow`  
   Password: `airflow`

3. **Access the DAG**: Once logged in, you will be taken to the Airflow dashboard. Look for the `abc_etl_dag` in the list of available Directed Acyclic Graphs (DAGs).

4. **Trigger the DAG**: Click on the `abc_etl_dag` to access its details. You will see various buttons and options related to the DAG.

5. **Manually Start the DAG**: Look for the play button or "Trigger DAG" button. Click on it to manually start the DAG execution.

6. **Monitor the Progress**: After triggering the DAG, you can monitor its progress in the Airflow UI. You will see the individual tasks being executed, and their statuses will be updated in real-time.

7. **View Results**: Once the DAG run is completed, you can view the results and logs of each task to check for any issues or errors that may have occurred during the execution.

Remember that the steps and options in the Airflow Webserver interface may vary slightly based on the version and configuration of your Airflow installation. Make sure you have the necessary permissions to trigger the DAG if you are running in a shared environment.

## Additional Notes

- The pipeline's configuration and Directed Acyclic Graphs (DAGs) can be modified in the `dags` folder within the cloned repository.
- Depending on the tasks in your pipeline, ensure that any required dependencies are installed to execute those tasks successfully.
- Monitoring and managing the pipeline can be done through the Airflow web interface.
- To stop the services, press `Ctrl + C` in the terminal where you started the pipeline.

Now, you should have the pipeline up and running with Airflow handling the workflows, orchestrating tasks, and ensuring your data processes are executed as defined in your DAGs. Happy data engineering!

#### Things that were not implemented due to time
- Writing test for the Extract and Load pipeline and using CI/CD with Airflow
- using Kubernetes for orchestrating the Docker container 

