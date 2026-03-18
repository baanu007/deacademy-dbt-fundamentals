{{
    config(
        materialized='incremental',
        unique_key='Date_id',
        incremental_strategy='merge',
        schema='RAW'
    )
}}

WITH date_source AS (
    SELECT DISTINCT
        DATE        AS Store_Date,
        ISHOLIDAY
    FROM {{ source('raw', 'FACT_RAW') }}
),

final AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY Store_Date)   AS Date_id,
        Store_Date,
        CASE
            WHEN ISHOLIDAY = TRUE THEN 'Yes'
            ELSE 'No'
        END                                       AS Isholiday,
        CURRENT_TIMESTAMP                         AS Insert_date,
        CURRENT_TIMESTAMP                         AS Update_date
    FROM date_source
)

SELECT * FROM final

{% if is_incremental() %}
    WHERE Store_Date NOT IN (SELECT Store_Date FROM {{ this }})
{% endif %}