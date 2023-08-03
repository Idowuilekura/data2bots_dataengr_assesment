import pandas as pd

import s3fs
import boto3 
from io import StringIO



def export_best_performing_data(schema: str, username:str, postgres_engine):

    # s3 = s3fs.S3FileSystem(anon=False)
    best_perfoming_data = pd.read_sql_query(f'SELECT * FROM {schema}.best_performing_product', con=postgres_engine)

    
    bucket_name = 'd2b-internal-assessment-bucket'
    export_path = f's3://d2b-internal-assessment-bucket/analytics_export/{username}/best_performing_product.csv'
    # Use 'w' for py3, 'wb' for py2
    # with s3.open(export_path,'w') as f:
    #     best_perfoming_data.to_csv(f, index=False)
    # best_perfoming_data = pd.read_sql_query(f'SELECT * FROM {schema}.best_performing_product', con=postgres_engine)
    
    
    
    best_perfoming_data.to_csv(export_path, index=False)

    # object_key = export_path

    # s3 = boto3.client('s3')
    
    # s3.put_object(Bucket=bucket_name, Key=object_key, Body=best_performing_csv_data, ACL='public-read')

    # public_url = f'https://{bucket_name}.s3.amazonaws.com/{object_key}'

    # return public_url

# import pandas as pd
# import boto3
# from io import StringIO

# # Replace with your AWS S3 bucket name and your username
# bucket_name = 'd2b-internal-assessment-bucket'
# username = 'your-username'

# # Your DataFrame
# data = {
#     'Column1': [1, 2, 3, 4, 5],
#     'Column2': ['A', 'B', 'C', 'D', 'E']
# }
# df = pd.DataFrame(data)

# # Convert DataFrame to CSV data (you can choose a different format if needed)
# csv_data = df.to_csv(index=False)

# # Replace with your AWS S3 object key (the filename)
# object_key = f'analytics_export/{username}/best_performing_product.csv'

# # Create an S3 client
# s3 = boto3.client('s3')

# # Upload the DataFrame to the public S3 bucket
# s3.put_object(Bucket=bucket_name, Key=object_key, Body=csv_data, ACL='public-read')

# # Generate the public URL to access the uploaded file
# public_url = f'https://{bucket_name}.s3.amazonaws.com/{object_key}'
    