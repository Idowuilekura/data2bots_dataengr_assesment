{{ config(materialized = 'view') }} 


SELECT * 
    FROM {{ source('if_common_source', 'dim_products')}}