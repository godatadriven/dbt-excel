{{

config(
  materialized='table',
  file_format='excel',
)

}}

SELECT * FROM {{ source('test_data', 'sheet1') }}
