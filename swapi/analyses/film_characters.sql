select
    f.episode_id,
    f.title as film_title,
    p.name as person_name
from {{ ref('stg_films') }} f
join {{ ref('int_film_characters') }} fc on f.film_id = fc.film_id
join {{ ref('stg_people') }} p on fc.person_id = p.person_id
