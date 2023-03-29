{%- macro get_column_names(relation) -%}

{%- set columns  = adapter.get_columns_in_relation(relation) -%}
{%- set columns_list = [] -%}

{%- for column in columns -%}
  {{ columns_list.append(columns_list.name) }}
{%- endfor -%}
{{ return(columns_list) }}

{%- endmacro -%}
