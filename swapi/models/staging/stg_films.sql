select
    {{ extract_swapi_id('url') }} as film_id,
    url,
    episode_id,
    trim(title) as title,
    replace(opening_crawl, chr(13) || chr(10), chr(10)) as opening_crawl,
    trim(director) as director,
    {{ split_csv_to_array('producer') }} as producers,
    release_date,
    created,
    edited,
    _ingested_at
from {{ source('raw', 'films') }}
