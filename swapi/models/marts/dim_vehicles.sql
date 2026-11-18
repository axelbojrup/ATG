select
    vehicle_id,
    name,
    model,
    manufacturers,
    cost_in_credits,
    length_m,
    max_atmosphering_speed,
    crew,
    passengers,
    cargo_capacity_kg,
    consumables_raw,
    vehicle_class
from {{ ref('stg_vehicles') }}
