{% macro write_to_file(relation, location, format, delimiter=',') -%}
  {% if format == 'parquet' %}
    {% set copy_to %}
      copy {{ relation }} to '{{ location }}' (FORMAT 'parquet');
    {% endset %}

  {% elif format == 'csv' %}
    {% set copy_to %}
      copy {{ relation }} to '{{ location }}' (HEADER 1, DELIMITER '{{ delimiter }}');
    {% endset %}

  {% elif format == 'xlsx' %}
    {% set copy_to %}
      copy {{ relation }} to '{{ location }}.parquet' (FORMAT 'parquet');
    {% endset %}

  {% else %}
      {% do exceptions.raise_compiler_error("%s external format is not supported!" % format) %}
  {% endif %}

  {% call statement('write_to_file') -%}
    {{ copy_to }}
  {%- endcall %}

  {% if format == 'xlsx' %}
	{{ adapter.output_excel(location) }}
  {% endif %}
{% endmacro %}
