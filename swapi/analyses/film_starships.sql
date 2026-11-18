select
    f.episode_id,
    f.title as film_title,
    s.name as starship_name,
    s.starship_class
from {{ ref('stg_films') }} f
join {{ ref('int_film_starships') }} fs on f.film_id = fs.film_id
join {{ ref('stg_starships') }} s on fs.starship_id = s.starship_id
