select
    starship_id,
    name,
    model,
    manufacturers,
    cost_in_credits,
    length_m,
    max_atmosphering_speed,
    crew_min,
    crew_max,
    passengers,
    cargo_capacity_kg,
    consumables_raw,
    hyperdrive_rating,
    mglt,
    starship_class
from {{ ref('stg_starships') }}
