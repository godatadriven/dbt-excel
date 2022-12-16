{% macro spark__options_clause() -%}
options (
  'dataAddress' = 'Sheet1!A1',
  'header' = 'True'
)
{%- endmacro -%}
