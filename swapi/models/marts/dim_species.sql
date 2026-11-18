select
    sp.species_id,
    sp.name,
    sp.classification,
    sp.designation,
    sp.average_height_cm,
    sp.skin_colors,
    sp.hair_colors,
    sp.eye_colors,
    sp.average_lifespan_years,
    sp.homeworld_planet_id,
    pl.name as homeworld_name,
    sp.language
from {{ ref('stg_species') }} sp
left join {{ ref('stg_planets') }} pl
    on sp.homeworld_planet_id = pl.planet_id
