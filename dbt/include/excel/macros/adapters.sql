
{% macro excel__create_table_as(temporary, relation, compiled_code, language='sql') -%}
  {%- if language == 'sql' -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none }}

    create {% if temporary: -%}temporary{%- endif %} table
      {{ relation.include(database=(not temporary and adapter.use_database()), schema=(not temporary)) }}
    as (
      {{ compiled_code }}
    );
  {%- elif language == 'python' -%}
    {{ py_write_table(temporary=temporary, relation=relation, compiled_code=compiled_code) }}
  {%- else -%}
      {% do exceptions.raise_compiler_error("excel__create_table_as macro didn't get supported language, it got %s" % language) %}
  {%- endif -%}
{% endmacro %}

{% macro py_write_table(temporary, relation, compiled_code) -%}
{{ compiled_code }}

def materialize(df, con):
    # For the DuckDBPyRelation checks
    import excel

    # make sure pandas exists before using it
    try:
        import pandas
        pandas_available = True
    except ImportError:
        pandas_available = False

    # make sure pyarrow exists before using it
    try:
        import pyarrow
        pyarrow_available = True
    except ImportError:
        pyarrow_available = False

    if isinstance(df, excel.DuckDBPyRelation):
        if pyarrow_available:
            df = df.arrow()
        elif pandas_available:
            df = df.df()
        else:
            raise Exception("No pandas or pyarrow available to materialize DuckDBPyRelation")
    elif not (
      (pandas_available and isinstance(df, pandas.DataFrame))
      or (pyarrow_available and isinstance(df, pyarrow.Table))
    ):
        raise Exception( str(type(df)) + " is not a supported type for dbt Python materialization")

    con.execute('create table {{ relation.include(database=adapter.use_database()) }} as select * from df')
{% endmacro %}

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
