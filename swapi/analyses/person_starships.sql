select
    p.name as person_name,
    s.name as starship_name,
    s.starship_class
from {{ ref('stg_people') }} p
join {{ ref('int_person_starships') }} ps on p.person_id = ps.person_id
join {{ ref('stg_starships') }} s on ps.starship_id = s.starship_id
