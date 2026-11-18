select
    p.person_id,
    p.name,
    p.height_cm,
    p.mass_kg,
    p.hair_colors,
    p.skin_colors,
    p.eye_colors,
    p.birth_year_bby,
    p.gender,
    p.homeworld_planet_id,
    pl.name as homeworld_name,
    p.species_id,
    sp.name as species_name,
    sp.classification as species_classification
from {{ ref('stg_people') }} p
left join {{ ref('stg_planets') }} pl
    on p.homeworld_planet_id = pl.planet_id
left join {{ ref('stg_species') }} sp
    on p.species_id = sp.species_id
