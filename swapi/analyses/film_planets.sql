select
    f.episode_id,
    f.title as film_title,
    pl.name as planet_name
from {{ ref('stg_films') }} f
join {{ ref('int_film_planets') }} fp on f.film_id = fp.film_id
join {{ ref('stg_planets') }} pl on fp.planet_id = pl.planet_id
