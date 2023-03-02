{% macro reckless_casting(column) %} 

{% set match_positive_boolean = ('y', 'yes', 't', 'true') %}
{% set match_negative_boolean = ('n', 'no', 'f', 'false') %}
{% set integer_regex = '^([0-9]+)$' %}
{% set float_regex = '^[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?$' %}
{% set text_regex = '[^0-9.]' %}
 
case 
    when {{ enforce_string(column) }} in {{ match_positive_boolean }} then 1.0
    when {{ enforce_string(column) }} in {{ match_negative_boolean }} then 0.0
    when regexp_matches({{ enforce_string(column) }}, '{{ integer_regex }}') then cast({{ column }} as real)
    when regexp_matches({{ enforce_string(column) }}, '{{ float_regex }}') then cast({{ column }} as real)
    when regexp_matches({{ enforce_string(column) }}, '{{ text_regex }}') then 0.0  
end

{% endmacro %}