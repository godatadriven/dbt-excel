{% materialization external, adapter="excel", supported_languages=['sql', 'python'] %}

  {%- set format = render(config.get('format', default='parquet')) -%}
  {%- set delimiter = render(config.get('delimiter', default=',')) -%}
  {%- set glue_register = config.get('glue_register', default=false) -%}
  {%- set glue_database = render(config.get('glue_database', default='default')) -%}

  {#
    For xlsx formats the default location is the same directory as the .sql file.
    If a `location` is passed in the config then this takes priority.
    For all other formats the `location` parameter is prioritised.
  #}
  {% if format == 'xlsx' and config.get('location', 'not passed') == 'not passed' %}
    {%- set location = render(model.original_file_path.split('.')[0] + '.' + format) -%}
  {% else %}
    {%- set location = render(config.get('location', default=external_location(this, format))) -%}
  {% endif %}

  -- set language - python or sql
  {%- set language = model['language'] -%}

  {%- set target_relation = this.incorporate(type='view') %}

  -- Continue as normal materialization
  {%- set existing_relation = load_cached_relation(this) -%}
  {%- set temp_relation =  make_intermediate_relation(this.incorporate(type='table'), suffix='__dbt_tmp') -%}
  {%- set intermediate_relation =  make_intermediate_relation(target_relation, suffix='__dbt_int') -%}
  -- the intermediate_relation should not already exist in the database; get_relation
  -- will return None in that case. Otherwise, we get a relation that we can drop
  -- later, before we try to use this name for the current operation
  {%- set preexisting_temp_relation = load_cached_relation(temp_relation) -%}
  {%- set preexisting_intermediate_relation = load_cached_relation(intermediate_relation) -%}
  /*
      See ../view/view.sql for more information about this relation.
  */
  {%- set backup_relation_type = 'table' if existing_relation is none else existing_relation.type -%}
  {%- set backup_relation = make_backup_relation(target_relation, backup_relation_type) -%}
  -- as above, the backup_relation should not already exist
  {%- set preexisting_backup_relation = load_cached_relation(backup_relation) -%}
  -- grab current tables grants config for comparision later on
  {% set grant_config = config.get('grants') %}

  -- drop the temp relations if they exist already in the database
  {{ drop_relation_if_exists(preexisting_intermediate_relation) }}
  {{ drop_relation_if_exists(preexisting_temp_relation) }}
  {{ drop_relation_if_exists(preexisting_backup_relation) }}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- build model
  {% call statement('create_table', language=language) -%}
    {{- create_table_as(False, temp_relation, compiled_code, language) }}
  {%- endcall %}

  -- write an temp relation into file
  {{ write_to_file(temp_relation, location, format, delimiter) }}
  -- create a view on top of the location
  {% if format == 'xlsx' %}
	  {% set location = location + '.parquet' %}
  {% endif %}
  {% call statement('main', language='sql') -%}
    create or replace view {{ intermediate_relation.include(database=adapter.use_database()) }} as (
        select * from '{{ location.replace(".xlsx", "") }}'
    );
  {%- endcall %}

  -- cleanup
  {% if existing_relation is not none %}
      {{ adapter.rename_relation(existing_relation, backup_relation) }}
  {% endif %}

  {{ adapter.rename_relation(intermediate_relation, target_relation) }}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  -- `COMMIT` happens here
  {{ adapter.commit() }}

  -- finally, drop the existing/backup relation after the commit
  {{ drop_relation_if_exists(backup_relation) }}
  {{ drop_relation_if_exists(temp_relation) }}

  -- register table into glue
  {% do register_glue_table(glue_register, glue_database, target_relation, location, format) %}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}
