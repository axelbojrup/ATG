select
    p.person_id,
    p.name as person_name,
    v.vehicle_id,
    v.name as vehicle_name,
    v.model,
    v.vehicle_class
from {{ ref('dim_people') }} p
join {{ ref('int_person_vehicles') }} pv
    on p.person_id = pv.person_id
join {{ ref('dim_vehicles') }} v
    on pv.vehicle_id = v.vehicle_id
