select
    f.film_id,
    f.episode_id,
    f.title as film_title,
    sp.species_id,
    sp.name as species_name,
    sp.classification
from {{ ref('dim_films') }} f
join {{ ref('int_film_species') }} fs
    on f.film_id = fs.film_id
join {{ ref('dim_species') }} sp
    on fs.species_id = sp.species_id
