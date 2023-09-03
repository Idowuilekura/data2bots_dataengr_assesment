{{ config(materialized = 'view') }} 


SELECT * 
    FROM {{ source('staging_source', 'dim_dates')}}