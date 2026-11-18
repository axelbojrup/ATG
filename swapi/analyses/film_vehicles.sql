select
    f.episode_id,
    f.title as film_title,
    v.name as vehicle_name,
    v.vehicle_class
from {{ ref('stg_films') }} f
join {{ ref('int_film_vehicles') }} fv on f.film_id = fv.film_id
join {{ ref('stg_vehicles') }} v on fv.vehicle_id = v.vehicle_id
