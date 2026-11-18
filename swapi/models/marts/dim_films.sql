select
    film_id,
    episode_id,
    title,
    director,
    producers,
    release_date,
    opening_crawl
from {{ ref('stg_films') }}
