{% macro clean_null(column_name) -%}
    nullif(
        case
            when lower(trim(cast({{ column_name }} as varchar))) in ('unknown', 'none', 'n/a', 'indefinite', '')
            then null
            else trim(cast({{ column_name }} as varchar))
        end,
        ''
    )
{%- endmacro %}

{% macro extract_swapi_id(url_column) -%}
    try_cast(
        nullif(regexp_extract(cast({{ url_column }} as varchar), '/([0-9]+)/?$', 1), '')
        as bigint
    )
{%- endmacro %}

{% macro parse_numeric(column_name, target_type='double') -%}
    try_cast(
        replace({{ clean_null(column_name) }}, ',', '')
        as {{ target_type }}
    )
{%- endmacro %}

{% macro split_csv_to_array(column_name) -%}
    case
        when {{ clean_null(column_name) }} is null then null
        else list_transform(
            string_split({{ clean_null(column_name) }}, ','),
            lambda x: trim(x)
        )
    end
{%- endmacro %}

{% macro unnest_swapi_bridge(source_table, left_id_col, array_col, right_id_col) -%}
select
    {{ extract_swapi_id('url') }} as {{ left_id_col }},
    {{ extract_swapi_id('t.target_url') }} as {{ right_id_col }}
from {{ source('raw', source_table) }},
    unnest({{ array_col }}) as t(target_url)
{%- endmacro %}
