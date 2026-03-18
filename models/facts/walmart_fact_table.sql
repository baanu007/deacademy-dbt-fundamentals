{{
    config(
        materialized='incremental',
        unique_key='Fact_id',
        incremental_strategy='merge',
        schema='RAW'
    )
}}

WITH fact_source AS (
    SELECT
        f.STORE,
        f.DATE,
        f.TEMPERATURE,
        f.FUEL_PRICE,
        f.MARKDOWN1,
        f.MARKDOWN2,
        f.MARKDOWN3,
        f.MARKDOWN4,
        f.MARKDOWN5,
        f.CPI,
        f.UNEMPLOYMENT,
        f.ISHOLIDAY,
        d.WEEKLY_SALES,
        d.DEPT
    FROM {{ source('raw', 'FACT_RAW') }} f
    LEFT JOIN {{ source('raw', 'DEPARTMENT_RAW') }} d
        ON f.STORE = d.STORE
        AND f.DATE = d.DATE
),

joined AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY fs.STORE, fs.DATE, fs.DEPT
        )                                       AS Fact_id,

        -- Foreign keys
        sd.Store_id,
        sd.Dept_id,
        dd.Date_id,

        -- Measures (exact names from document)
        fs.WEEKLY_SALES                         AS Store_Weekly_sales,
        fs.FUEL_PRICE                           AS Fuel_price,
        fs.TEMPERATURE                          AS Store_temperature,
        fs.UNEMPLOYMENT                         AS Unemployment,
        fs.CPI                                  AS CPI,
        fs.MARKDOWN1                            AS Markdown1,
        fs.MARKDOWN2                            AS Markdown2,
        fs.MARKDOWN3                            AS Markdown3,
        fs.MARKDOWN4                            AS Markdown4,
        fs.MARKDOWN5                            AS Markdown5,

        -- SCD2 version columns
        CURRENT_TIMESTAMP                       AS Vrsn_start_date,
        NULL::TIMESTAMP                         AS Vrsn_end_date,

        -- Audit columns
        CURRENT_TIMESTAMP                       AS Insert_date,
        CURRENT_TIMESTAMP                       AS Update_date

    FROM fact_source fs

    LEFT JOIN {{ ref('walmart_store_dim') }} sd
        ON fs.STORE = sd.Store_id
        AND fs.DEPT = sd.Dept_id

    LEFT JOIN {{ ref('walmart_date_dim') }} dd
        ON fs.DATE = dd.Store_Date
)

SELECT * FROM joined

{% if is_incremental() %}
    WHERE CONCAT(Store_id, '-', Dept_id, '-', Date_id) NOT IN (
        SELECT CONCAT(Store_id, '-', Dept_id, '-', Date_id)
        FROM {{ this }}
    )
{% endif %}
