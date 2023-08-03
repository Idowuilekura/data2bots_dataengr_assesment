# data2bots_dataengr_assesment
This is the repository for documenting my solution to the Data2bots data engineering assesment 

## ABC Limited data engineering pipeline 
Data2bots consults for ABC company, a fast moving company that deals in day to day goods. The company has been generating massive amount of data and wish to leverage on data enginenring and analytics for their day to day activities. EVeryday the company's data lake receives orders, reviews for their products and the shipment details. In order for the company to get actionanble information from theses files, the company stakeholders has dedicated the task of ingesting the three files into a data warehouse, write queries for getting information about orders that were made on a public holidays per month, total late shipment & undelivered items, and the best performing product. 

### Choosing tools for the project
Given that the files will be coming in daily, Apache Airflow was choosen for orchestrating the task, Python for automating the process, SQL for writing the queires. To ensure version control and scalability of the Analytical QUeries, Data Build Tools (DBT) was used for the analytical development. To ensure that the project can run on any system, Docker was used for contanirizing the entire workflow. 

### Understading the different processes 
For building the data pipeline, there were different stages that was considered such as the 
- Extract
- Load
- Analytics and Transformation
- Exporting the Best Products 
- Dockerizing the entire workflow 

#### Extract Proceess
For the extracting process, the process entails connecting to the S3 bucket, downloading each files and storing on the local system. There was an issue that I encountered while downloading the orders data, there was spelling error in the name, I had to list the files in the directory in order to solve this. 

#### Loading Process 
For the loading process, given that the files will come daily, the analytic process required an ingestion date to be attached to it. I thought it wise to recreate the tables when ever the data is ingested into the data warehouse. 

#### Analytic Process 