import pandas as pd
# from extract_data import extract_save_data_all
from typing import List, Dict
from sqlalchemy import create_engine




def load_data_warehouse(ti, postgres_engine, staging_schema_name: str) -> None:
    data_to_download_dict = ti.xcom_pull(task_ids='extract_data_task', key='output_path_dictionary')
    
    for keys,values in data_to_download_dict.items():
        data_df = pd.read_csv(values)
        
        if keys == 'orders':
            data_df['order_date'] = pd.to_datetime(data_df['order_date'])
        elif keys == 'shipment_deliveries':
            data_df['shipment_date'] = pd.to_datetime(data_df['shipment_date'])
            data_df['delivery_date'] = pd.to_datetime(data_df['delivery_date'])
        else:
            data_df = data_df
            
        # orders_table = 'orders'
        data_table_name = f"{keys}"

        from sqlalchemy import text

        # Execute the DROP statement with CASCADE
        drop_orders_table_query = text(f"DROP TABLE IF EXISTS idowilek6169_staging.{keys} CASCADE;")
        postgres_engine.execute(drop_orders_table_query)
        
        data_df.to_sql(name=data_table_name, con=postgres_engine, if_exists = 'replace', schema= staging_schema_name,index = False)
        
        

                    
        
        
            
        
            