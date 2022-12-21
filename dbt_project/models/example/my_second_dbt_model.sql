
-- Use the `ref` function to select from other models

select *
from {{ ref('my', 'excel_source') }}
where id = 1
