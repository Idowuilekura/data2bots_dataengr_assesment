import boto3
from botocore import UNSIGNED
from botocore.client import Config
from pathlib import Path
from typing import Tuple, List, Dict
import os 

s3 = boto3.client('s3', config=Config(signature_version= UNSIGNED))
airflow_home = os.getenv('AIRFLOW_HOME')

bucket_name = "d2b-internal-assessment-bucket"



# response = s3.list_objects(Bucket=bucket_name, Prefix="orders_data")

# s3.download_file(bucket_name, "orders_data/orders.csv", str(orders_folder_name/ "orders.csv"))

data_local_folder_name = Path(airflow_home+'/'+ 'orders_data')

data_local_folder_name.mkdir(exist_ok=True)

def extract_data_save_locally(s3, bucket_name: str, data_to_download_name:str, data_local_folder_name: str ):
    # orders_folder_name = Path('orders_data')
    # orders_folder_name.mkdir(exist_ok=True)
    
    # s3 = s3_client('s3', config=Config(signature_version= UNSIGNED)) 
    response = s3.list_objects(Bucket=bucket_name, Prefix="orders_data")
    output_path = str(data_local_folder_name+'/'+ data_to_download_name + '.csv')
    s3.download_file(bucket_name, "orders_data/"+data_to_download_name+'.csv',output_path)
    
    return output_path 

def extract_save_data_all(data_to_download: List,ti) -> Dict:
    """"This function will call the extract data save locally data for each of the orders, reviews and shipment information """
    output_path_dictionary = {}
    for data_name in data_to_download:
        data_outputh_path = extract_data_save_locally(s3, bucket_name= bucket_name, data_to_download_name = data_name, data_local_folder_name=str(data_local_folder_name))
        
        output_path_dictionary[data_name] = data_outputh_path
    
    ti.xcom_push(key='output_path_dictionary', value=output_path_dictionary)
        
    return output_path_dictionary
        
        
        
    
    
    
    
