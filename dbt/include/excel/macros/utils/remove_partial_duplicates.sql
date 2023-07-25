{#
Remove partial duplicates using a ranking function.
Needless to say, you will arbitrarly lose rows.
It filters out any row besides the first one  per column.

Example:

    Input: `size`

    | size | color |
    |------+-------|
    | S    | red   |
    | S    | blue  |
    | S    | red   |
    | M    | red   |

    select *
    from public.test
    {{ remove_partial_duplicates('size') }}

    Output:

    | size | color |
    |------+-------+
    | S    | red   |
    | M    | red   |

Arguments:
    column: Column name, required
#}

{% macro remove_partial_duplicates(column_name) %}
qualify row_number() over (partition by {{ column_name }}) = 1
{% endmacro %}
