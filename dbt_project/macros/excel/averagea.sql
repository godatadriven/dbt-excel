{#
Returns the average (arithmetic mean) of the values in a column. 
Handles text and non-numeric values.
When is this a good idea? Not sure. Lol.

Example:

    Input: `Table`

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

avg({{ reckless_casting(column) }})

{% endmacro %}