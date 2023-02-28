{#
Returns the average (arithmetic mean) of the values in a column. 
Handles text and non-numeric values.
When is this a good idea? Not sure. Lol.

Example:

    Input: `example`

    | example |
    |---------|
    | 10      | 
    | 10s     |
    | 30      |
    | True    |

    select 
        {{ averagea('example') }}
    from public.test
    
    Output:

    10.25

Arguments:
    column: Column name, required
#}

{% macro averagea(column) %} 
    avg(
        case 
            -- If boolean, cast as number. 1 for True and 0 for False.
            when lower(cast({{ column }} as string)) in ('y', 'yes', 't', 'true') then 1.0
            when lower(cast({{ column }} as string)) in ('n', 'no', 'f', 'false') then 0.0

            -- If integer, turn into float
            when regexp_contains(lower(cast({{ column }} as string)), r'^([0-9]+)$') then cast({{ column }} as float64)

            -- If float, turn into float
            when regexp_contains(lower(cast({{ column }} as string)), r'^[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?$') then cast({{ column }} as float64)

            -- If it contains a non-digit nor dot character, cast into 0.0
            when regexp_contains(lower(cast({{ column }} as string)), r'[^0-9.]') then 0.0  
        end
    )
{% endmacro %}


