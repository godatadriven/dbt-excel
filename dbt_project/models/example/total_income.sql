
-- Use the `ref` function to select from other models

select
    sum(income) as total_income
from
    {{ source('mock_data', 'people') }}
