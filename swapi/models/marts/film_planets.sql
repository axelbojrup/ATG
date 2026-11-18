select
    f.film_id,
    f.episode_id,
    f.title as film_title,
    pl.planet_id,
    pl.name as planet_name,
    pl.climates,
    pl.terrains
from {{ ref('dim_films') }} f
join {{ ref('int_film_planets') }} fp
    on f.film_id = fp.film_id
join {{ ref('dim_planets') }} pl
    on fp.planet_id = pl.planet_id
