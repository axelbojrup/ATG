select
    p.name as person_name,
    v.name as vehicle_name,
    v.vehicle_class
from {{ ref('stg_people') }} p
join {{ ref('int_person_vehicles') }} pv on p.person_id = pv.person_id
join {{ ref('stg_vehicles') }} v on pv.vehicle_id = v.vehicle_id