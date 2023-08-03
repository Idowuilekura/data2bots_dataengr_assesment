import os

def run_dbt_task(dbt_directory: str) -> None:
    get_cwd = os.getcwd()
    
    os.chdir(dbt_directory)
    
    os.system('dbt build --target analytic')