{{
    config(
        materialized='incremental',
        unique_key=['Store_id', 'Dept_id'],
        incremental_strategy='merge',
        schema='RAW'
    )
}}

WITH store_source AS (
    SELECT DISTINCT
        s.STORE       AS Store_id,
        d.DEPT        AS Dept_id,
        s.TYPE        AS Store_type,
        s.SIZE        AS Store_size
    FROM {{ source('raw', 'STORES_RAW') }} s
    LEFT JOIN {{ source('raw', 'DEPARTMENT_RAW') }} d
        ON s.STORE = d.STORE
),

final AS (
    SELECT
        Store_id,
        Dept_id,
        Store_type,
        Store_size,
        CURRENT_TIMESTAMP    AS Insert_date,
        CURRENT_TIMESTAMP    AS Update_date
    FROM store_source
)

SELECT * FROM final

{% if is_incremental() %}
    WHERE CONCAT(Store_id, '-', Dept_id) NOT IN (
        SELECT CONCAT(Store_id, '-', Dept_id)
        FROM {{ this }}
    )
{% endif %}