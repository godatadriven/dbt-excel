
{% macro excel__create_schema(relation) -%}
  {%- call statement('create_schema') -%}
    create schema if not exists {{ relation.without_identifier().include(database=adapter.use_database()) }}
  {%- endcall -%}
{% endmacro %}

{% macro excel__drop_schema(relation) -%}
  {%- call statement('drop_schema') -%}
    drop schema if exists {{ relation.without_identifier().include(database=adapter.use_database()) }} cascade
  {%- endcall -%}
{% endmacro %}

{% macro excel__list_schemas(database) -%}
  {% set sql %}
    select schema_name
    from information_schema.schemata
  {% endset %}
  {{ return(run_query(sql)) }}
{% endmacro %}

{% macro excel__check_schema_exists(information_schema, schema) -%}
  {% set sql -%}
        select count(*)
        from information_schema.schemata
        where schema_name='{{ schema }}'
  {%- endset %}
  {{ return(run_query(sql)) }}
{% endmacro %}

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

{% macro excel__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  create view {{ relation.include(database=adapter.use_database()) }} as (
    {{ sql }}
  );
{% endmacro %}

{% macro excel__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
      select
          column_name,
          data_type,
          character_maximum_length,
          numeric_precision,
          numeric_scale

      from information_schema.columns
      where table_name = '{{ relation.identifier }}'
        {% if relation.schema %}
        and table_schema = '{{ relation.schema }}'
        {% endif %}
      order by ordinal_position

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}

{% macro excel__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      '{{ schema_relation.database }}' as database,
      table_name as name,
      table_schema as schema,
      CASE table_type
        WHEN 'BASE TABLE' THEN 'table'
        WHEN 'VIEW' THEN 'view'
        WHEN 'LOCAL TEMPORARY' THEN 'table'
        END as type
    from information_schema.tables
    where table_schema = '{{ schema_relation.schema }}'
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro excel__drop_relation(relation) -%}
  {% call statement('drop_relation', auto_begin=False) -%}
    drop {{ relation.type }} if exists {{ relation.include(database=adapter.use_database()) }} cascade
  {%- endcall %}
{% endmacro %}

{% macro excel__truncate_relation(relation) -%}
  {% call statement('truncate_relation') -%}
    DELETE FROM {{ relation.include(database=adapter.use_database()) }} WHERE 1=1
  {%- endcall %}
{% endmacro %}

{% macro excel__rename_relation(from_relation, to_relation) -%}
  {% set target_name = adapter.quote_as_configured(to_relation.identifier, 'identifier') %}
  {% call statement('rename_relation') -%}
    alter {{ to_relation.type }} {{ from_relation }} rename to {{ target_name }}
  {%- endcall %}
{% endmacro %}

{% macro excel__make_temp_relation(base_relation, suffix) %}
    {% set tmp_identifier = base_relation.identifier ~ suffix ~ py_current_timestring() %}
    {% do return(base_relation.incorporate(
                                  path={
                                    "identifier": tmp_identifier,
                                    "schema": none,
                                    "database": none
                                  })) -%}
{% endmacro %}

{% macro excel__current_timestamp() -%}
  now()
{%- endmacro %}

{% macro excel__snapshot_string_as_time(timestamp) -%}
    {%- set result = "'" ~ timestamp ~ "'::timestamp" -%}
    {{ return(result) }}
{%- endmacro %}

{% macro excel__snapshot_get_time() -%}
  {{ current_timestamp() }}::timestamp
{%- endmacro %}

{% macro excel__get_incremental_default_sql(arg_dict) %}
  {% do return(get_incremental_delete_insert_sql(arg_dict)) %}
{% endmacro %}

{% macro excel__get_incremental_delete_insert_sql(arg_dict) %}
  {% do return(get_delete_insert_merge_sql(arg_dict["target_relation"].include(database=adapter.use_database()), arg_dict["temp_relation"], arg_dict["unique_key"], arg_dict["dest_columns"])) %}
{% endmacro %}

{% macro excel__get_incremental_append_sql(arg_dict) %}
  {% do return(get_insert_into_sql(arg_dict["target_relation"].include(database=adapter.use_database()), arg_dict["temp_relation"], arg_dict["dest_columns"])) %}
{% endmacro %}

{% macro location_exists(location) -%}
  {% do return(adapter.location_exists(location)) %}
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

{% macro register_glue_table(register, glue_database, relation, location, format) -%}
  {% if location.startswith("s3://") and register == true %}
    {%- set column_list = adapter.get_columns_in_relation(relation) -%}
    {% do adapter.register_glue_table(glue_database, relation.identifier, column_list, location, format) %}
  {% endif %}
{% endmacro %}
