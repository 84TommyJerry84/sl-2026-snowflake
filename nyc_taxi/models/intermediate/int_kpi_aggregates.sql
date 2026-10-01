{{ config(materialized='view') }}

select
    aggregation_level,
    trip_date,
    pickup_location_id,
    pickup_hour,
    day_type,
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

from {{ source('snowflake_final', 'kpi_aggregates') }}