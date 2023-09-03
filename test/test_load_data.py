import pandas as pd
# from extract_data import extract_save_data_all
from typing import List, Dict
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

def test_loaded_data(postgres_engine,staging_schema_name,table_name="orders") -> bool:
    data_pd = pd.read_sql_query(f'SELECT * FROM {staging_schema_name}.{table_name} LIMIT 5' ,con=postgres_engine).shape
    assert len(data_pd) != 1


    