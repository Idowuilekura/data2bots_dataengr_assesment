{{ config(materialized = 'view') }} 


SELECT * 
    FROM {{ source('staging_source', 'orders')}}

    