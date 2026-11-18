select
    {{ extract_swapi_id('url') }} as vehicle_id,
    url,
    {{ clean_null('name') }} as name,
    {{ clean_null('model') }} as model,
    {{ split_csv_to_array('manufacturer') }} as manufacturers,
    {{ parse_numeric('cost_in_credits', 'bigint') }} as cost_in_credits,
    {{ parse_numeric('length', 'double') }} as length_m,
    {{ parse_numeric('max_atmosphering_speed', 'bigint') }} as max_atmosphering_speed,
    {{ parse_numeric('crew', 'bigint') }} as crew,
    {{ parse_numeric('passengers', 'bigint') }} as passengers,
    {{ parse_numeric('cargo_capacity', 'bigint') }} as cargo_capacity_kg,
    {{ clean_null('consumables') }} as consumables_raw,
    {{ clean_null('vehicle_class') }} as vehicle_class,
    created,
    edited,
    _ingested_at
from {{ source('raw', 'vehicles') }}
