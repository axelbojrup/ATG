select
    planet_id,
    name,
    rotation_period_hours,
    orbital_period_days,
    diameter_km,
    climates,
    gravity_standard,
    gravity_raw,
    terrains,
    surface_water_pct,
    population
from {{ ref('stg_planets') }}
