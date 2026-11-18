select
    {{ extract_swapi_id('url') }} as starship_id,
    url,
    {{ clean_null('name') }} as name,
    {{ clean_null('model') }} as model,
    {{ split_csv_to_array('manufacturer') }} as manufacturers,
    {{ parse_numeric('cost_in_credits', 'bigint') }} as cost_in_credits,
    {{ parse_numeric('length', 'double') }} as length_m,
    try_cast(
        replace(lower({{ clean_null('max_atmosphering_speed') }}), 'km', '')
        as bigint
    ) as max_atmosphering_speed,
    case
        when {{ clean_null('crew') }} like '%-%' then
            try_cast(trim(split_part({{ clean_null('crew') }}, '-', 1)) as bigint)
        else {{ parse_numeric('crew', 'bigint') }}
    end as crew_min,
    case
        when {{ clean_null('crew') }} like '%-%' then
            try_cast(trim(split_part({{ clean_null('crew') }}, '-', 2)) as bigint)
        else {{ parse_numeric('crew', 'bigint') }}
    end as crew_max,
    {{ parse_numeric('passengers', 'bigint') }} as passengers,
    {{ parse_numeric('cargo_capacity', 'bigint') }} as cargo_capacity_kg,
    {{ clean_null('consumables') }} as consumables_raw,
    {{ parse_numeric('hyperdrive_rating', 'double') }} as hyperdrive_rating,
    {{ parse_numeric('MGLT', 'bigint') }} as mglt,
    {{ clean_null('starship_class') }} as starship_class,
    created,
    edited,
    _ingested_at
from {{ source('raw', 'starships') }}
