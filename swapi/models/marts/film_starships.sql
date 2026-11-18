select
    f.film_id,
    f.episode_id,
    f.title as film_title,
    s.starship_id,
    s.name as starship_name,
    s.starship_class
from {{ ref('dim_films') }} f
join {{ ref('int_film_starships') }} fs
    on f.film_id = fs.film_id
join {{ ref('dim_starships') }} s
    on fs.starship_id = s.starship_id
