{{ config(materialized='view') }}

select
    pickup_location_id,
    trip_count,
    passenger_count,
    avg_distance_miles,
    avg_duration_minutes,
    avg_speed_mph,
    total_fare,
    total_tips,
    total_revenue,
    avg_trip_amount,
    tip_rate_pct

from {{ ref('int_kpi_aggregates') }}

where aggregation_level = 'ZONE'