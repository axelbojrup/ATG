select
    {{ extract_swapi_id('url') }} as species_id,
    url,
    {{ clean_null('name') }} as name,
    case lower({{ clean_null('classification') }})
        when 'mammals' then 'mammal'
        when 'reptilian' then 'reptile'
        when 'sentient' then null
        else lower({{ clean_null('classification') }})
    end as classification,
    case lower({{ clean_null('designation') }})
        when 'reptilian' then null
        else lower({{ clean_null('designation') }})
    end as designation,
    {{ parse_numeric('average_height', 'bigint') }} as average_height_cm,
    {{ split_csv_to_array('skin_colors') }} as skin_colors,
    {{ split_csv_to_array('hair_colors') }} as hair_colors,
    {{ split_csv_to_array('eye_colors') }} as eye_colors,
    {{ parse_numeric('average_lifespan', 'bigint') }} as average_lifespan_years,
    {{ extract_swapi_id('homeworld') }} as homeworld_planet_id,
    {{ clean_null('language') }} as language,
    created,
    edited,
    _ingested_at
from {{ source('raw', 'species') }}
