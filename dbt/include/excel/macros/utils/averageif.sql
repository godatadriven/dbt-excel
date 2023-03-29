{#
Calculates the average of values in a range based on a true or false condition.

Example:

    Input: 'B2:B4', 'Product A', 'A2:A4'

    | Quantity |  Product  |
    |----------|-----------|
    | 2        | Product A |
    | 4        | Product A |
    | 3        | Product B |

    select {{ averageif('B2:B4', 'Product A', 'A2:A4') }}

    Output:
    3

Arguments:
    range: Range of cells that you want evaluated by criteria, required.
    criteria: Text that defines which cells will be added, required.
    sum_range: The actual cells to aggregate, required.
#}

{% macro averageif(range, criteria, average_range) %}
    (
        select avg({{ average_range }})
        from {{ table }}
        where range = criteria
    )
{% endmacro %}
