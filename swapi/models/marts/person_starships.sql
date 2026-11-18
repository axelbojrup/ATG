select
    p.person_id,
    p.name as person_name,
    s.starship_id,
    s.name as starship_name,
    s.model,
    s.starship_class
from {{ ref('dim_people') }} p
join {{ ref('int_person_starships') }} ps
    on p.person_id = ps.person_id
join {{ ref('dim_starships') }} s
    on ps.starship_id = s.starship_id
