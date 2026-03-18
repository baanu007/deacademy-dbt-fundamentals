-- walmart_date_dim.sql
-- This model creates a clean dimension table for dates
-- Source: FACT_RAW (contains all the dates and holiday flags)

{{
    config(
        materialized='table',
        unique_key='DATE_ID'
    )
}}

WITH date_source AS (
    -- Pull all unique dates from the fact table
    SELECT DISTINCT
        DATE,
        ISHOLIDAY
    FROM {{ source('raw', 'FACT_RAW') }}
),

final AS (
    SELECT
        -- Generate a unique integer ID for each date
        ROW_NUMBER() OVER (ORDER BY DATE)   AS DATE_ID,
        DATE                                AS STORE_DATE,
        CASE 
            WHEN ISHOLIDAY = TRUE THEN 'Yes'
            ELSE 'No'
        END                                 AS ISHOLIDAY,
        CURRENT_TIMESTAMP                   AS INSERT_DATE,
        CURRENT_TIMESTAMP                   AS UPDATE_DATE
    FROM date_source
)

SELECT * FROM final