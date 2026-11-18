select
    {{ extract_swapi_id('url') }} as planet_id,
    url,
    {{ clean_null('name') }} as name,
    {{ parse_numeric('rotation_period', 'bigint') }} as rotation_period_hours,
    {{ parse_numeric('orbital_period', 'bigint') }} as orbital_period_days,
    {{ parse_numeric('diameter', 'bigint') }} as diameter_km,
    {{ split_csv_to_array('climate') }} as climates,
    {{ clean_null('gravity') }} as gravity_raw,
    try_cast(
        trim(replace({{ clean_null('gravity') }}, 'standard', ''))
        as double
    ) as gravity_standard,
    {{ split_csv_to_array('terrain') }} as terrains,
    {{ parse_numeric('surface_water', 'double') }} as surface_water_pct,
    {{ parse_numeric('population', 'bigint') }} as population,
    created,
    edited,
    _ingested_at
from {{ source('raw', 'planets') }}
