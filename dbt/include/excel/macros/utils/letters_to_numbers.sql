{% macro letters_to_numbers(letter) %}

ascii(upper(letter)) - 64

{% endmacro %}
