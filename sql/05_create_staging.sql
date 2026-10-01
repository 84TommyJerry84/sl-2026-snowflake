USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA STAGING;

CREATE TABLE IF NOT EXISTS NYC_TAXI_DB.STAGING.YELLOW_TRIPS AS
WITH typed AS (
    SELECT
        VendorID,
        TO_TIMESTAMP_NTZ(tpep_pickup_datetime, 6) AS pickup_datetime,
        TO_TIMESTAMP_NTZ(tpep_dropoff_datetime, 6) AS dropoff_datetime,
        passenger_count,
        trip_distance,
        RatecodeID,
        store_and_fwd_flag,
        PULocationID,
        DOLocationID,
        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount,
        congestion_surcharge,
        Airport_fee,
        cbd_congestion_fee
    FROM NYC_TAXI_DB.RAW.YELLOW_TRIPS
    WHERE tpep_pickup_datetime >= 1735689600000000
      AND tpep_pickup_datetime < 1767225600000000
),
valid AS (
    SELECT
        *,
        DATEDIFF('SECOND', pickup_datetime, dropoff_datetime) AS duration_seconds
    FROM typed
    WHERE NOT (
        COALESCE(fare_amount < 0, FALSE)
        OR COALESCE(total_amount < 0, FALSE)
        OR COALESCE(trip_distance = 0, FALSE)
        OR COALESCE(trip_distance > 1000, FALSE)
        OR COALESCE(dropoff_datetime <= pickup_datetime, FALSE)
    )
)
SELECT
    VendorID,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    RatecodeID,
    store_and_fwd_flag,
    PULocationID,
    DOLocationID,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    Airport_fee,
    cbd_congestion_fee,
    duration_seconds,
    ROUND(duration_seconds / 60.0, 2) AS duration_minutes,
    ROUND(trip_distance / NULLIF(duration_seconds / 3600.0, 0), 2) AS average_speed_mph,
    ROUND(100.0 * tip_amount / NULLIF(fare_amount, 0), 2) AS tip_rate_pct,
    CASE
        WHEN trip_distance IS NULL THEN 'UNKNOWN'
        WHEN trip_distance < 2 THEN 'SHORT'
        WHEN trip_distance < 5 THEN 'MEDIUM'
        WHEN trip_distance < 10 THEN 'LONG'
        ELSE 'VERY_LONG'
    END AS distance_category,
    CASE
        WHEN pickup_datetime IS NULL THEN 'UNKNOWN'
        WHEN DATE_PART('HOUR', pickup_datetime) < 6 THEN 'NIGHT'
        WHEN DATE_PART('HOUR', pickup_datetime) < 12 THEN 'MORNING'
        WHEN DATE_PART('HOUR', pickup_datetime) < 18 THEN 'AFTERNOON'
        ELSE 'EVENING'
    END AS time_period,
    CASE
        WHEN pickup_datetime IS NULL THEN 'UNKNOWN'
        WHEN DAYOFWEEKISO(pickup_datetime) IN (6, 7) THEN 'WEEKEND'
        ELSE 'WEEKDAY'
    END AS day_type
FROM valid;
