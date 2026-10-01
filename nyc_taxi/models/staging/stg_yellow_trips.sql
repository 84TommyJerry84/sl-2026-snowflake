{{ config(materialized='view') }}

select
    vendorid,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    ratecodeid,
    store_and_fwd_flag,
    pulocationid,
    dolocationid,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    duration_seconds,
    duration_minutes,
    average_speed_mph,
    tip_rate_pct,
    distance_category,
    time_period,
    day_type

from {{ source('snowflake_staging', 'yellow_trips') }}