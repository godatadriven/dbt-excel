{#
Calculates the average (arithmetic mean) of a set of expressions evaluated over a table.

Example:

    Input: 'Orders', 'Quantity * Sales'

    | Quantity | Sales  |
    |----------|--------|
    | 2        | 10     |
    | 1        | 20     |
    | 3        | 5      |

    select {{ averagex('Orders', 'Quantity * Sales') }}
    
    Output:
    18.33

Arguments:
    table: The table containing the rows for which the expression will be evaluated, required.
    expression: The expression to be evaluated for each row of the table, required.
#}

{% macro averagex(table, expression) %}
    (
        select avg({{ expression }})
        from {{ table }}
    )
{% endmacro %}