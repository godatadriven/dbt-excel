{% macro enforce_string(column) %} 

lower(cast({{ column }} as text))

{% endmacro %}