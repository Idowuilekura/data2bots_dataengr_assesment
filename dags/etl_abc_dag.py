from airflow import DAG 
from airflow.operators.python import PythonOperator
# from airflow.operators.bash import BashOperator
import os
from datetime import datetime, timedelta 
import pandas as pd
from sqlalchemy import create_engine
database_name = "d2b_accessment"
database_user = "idowilek6169"
database_password = "DhcdlXrJBW"
database_host = "34.89.230.185"
staging_schema_name = 'idowilek6169_staging'
analytic_schema = 'idowilek6169_analytics'
username = 'idowilek6169'

connection_string = f"postgresql://{database_user}:{database_password}@{database_host}/{database_name}"

postgres_engine = create_engine(connection_string)

from extract_data import extract_save_data_all

from load_data import load_data_warehouse

from run_dbt_analytics import run_dbt_task
from export_data import export_best_performing_data
from test_loading import test_loading_task


# from extract_weather import extract_weather_info_save_local
# from transform_weather import read_local_transform_weather
# from load_to_postgres import load_data_to_postgres 



airflow_home = os.getenv('AIRFLOW_HOME')


default_args = {
    'owner': 'idowu',
    'retries': 2,
    'retry_delay': timedelta(minutes=2)
}

abc_etl_dag = DAG(
    dag_id = 'abc_data2bot_etl_dag',
    description = 'Dag for loading the data for abc company',
    start_date = datetime(2023, 8,3),
    schedule_interval = '@daily',
    default_args = default_args
)

# load_data_warehouse(ti, postgres_engine, staging_schema_name: str)
extract_data_task = PythonOperator(task_id='extract_data_task',
                       python_callable= extract_save_data_all, 
                       op_kwargs = {'data_to_download': ['orders','reviews','shipment_deliveries']}, dag=abc_etl_dag)

load_data_task = PythonOperator(task_id = 'load_data_task',
                                python_callable= load_data_warehouse,
                                op_kwargs = {'postgres_engine': postgres_engine, 'staging_schema_name':staging_schema_name }, dag=abc_etl_dag)

test_loaded_data_task = PythonOperator(task_id='test_loading_task', 
                                       python_callable=test_loading_task)
# run_dbt_task(dbt_directory: str)
# export_best_performing_data(schema: str, username:str, postgres_engine)

run_analytics_dbt = PythonOperator(task_id = 'run_dbt_analytics',
                                   python_callable = run_dbt_task, op_kwargs= {'dbt_directory':'/app/d2b_analytics_project'}, dag=abc_etl_dag)


export_best_performing_data_task = PythonOperator(task_id='export_best_data',
                                                  python_callable = export_best_performing_data, 
                                                  op_kwargs= {'schema':analytic_schema,'username': username, 'postgres_engine':postgres_engine},
                                                  dag= abc_etl_dag)

extract_data_task >> load_data_task >> test_loaded_data_task >> run_analytics_dbt >> export_best_performing_data_task


