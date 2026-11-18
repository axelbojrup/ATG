select
    {{ extract_swapi_id('url') }} as person_id,
    url,
    {{ clean_null('name') }} as name,
    {{ parse_numeric('height', 'bigint') }} as height_cm,
    {{ parse_numeric('mass', 'double') }} as mass_kg,
    {{ split_csv_to_array('hair_color') }} as hair_colors,
    {{ split_csv_to_array('skin_color') }} as skin_colors,
    {{ split_csv_to_array('eye_color') }} as eye_colors,
    try_cast(
        replace(upper({{ clean_null('birth_year') }}), 'BBY', '')
        as double
    ) as birth_year_bby,
    {{ clean_null('gender') }} as gender,
    {{ extract_swapi_id('homeworld') }} as homeworld_planet_id,
    case
        when len(species) > 0 then {{ extract_swapi_id('species[1]') }}
        else null
    end as species_id,
    created,
    edited,
    _ingested_at
from {{ source('raw', 'people') }}
