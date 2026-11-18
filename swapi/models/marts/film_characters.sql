select
    f.film_id,
    f.episode_id,
    f.title as film_title,
    p.person_id,
    p.name as person_name,
    p.homeworld_name,
    p.species_name
from {{ ref('dim_films') }} f
join {{ ref('int_film_characters') }} fc
    on f.film_id = fc.film_id
join {{ ref('dim_people') }} p
    on fc.person_id = p.person_id
