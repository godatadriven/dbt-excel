{#
Returns the sum of an expression evaluated for each row in a table.

Example:

    Input: 'Orders', 'Quantity * Sales'

    | Quantity | Sales  |
    |----------|--------|
    | 2        | 10     |
    | 1        | 20     |
    | 3        | 5      |

    select {{ sumx('Orders', 'Quantity * Sales') }}

    Output:
    55

Arguments:
    table: The table containing the rows for which the expression will be evaluated, required.
    expression: The expression to be evaluated for each row of the table, required.
#}

{% macro sumx(table, expression) %}
    (
        select sum({{ expression }})
        from {{ table }}
    )
{% endmacro %}
