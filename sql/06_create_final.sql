USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA FINAL;

-- Agrégation unique afin de ne scanner STAGING qu'une fois
CREATE TABLE IF NOT EXISTS NYC_TAXI_DB.FINAL.KPI_AGGREGATES AS
SELECT
    CASE
        WHEN GROUPING(TO_DATE(pickup_datetime)) = 0 THEN 'DAILY'
        WHEN GROUPING(PULocationID) = 0 THEN 'ZONE'
        WHEN GROUPING(DATE_PART('HOUR', pickup_datetime)) = 0 THEN 'HOURLY'
    END AS aggregation_level,
    TO_DATE(pickup_datetime) AS trip_date,
    PULocationID AS pickup_location_id,
    DATE_PART('HOUR', pickup_datetime) AS pickup_hour,
    day_type,
    COUNT(*) AS trip_count,
    SUM(passenger_count) AS passenger_count,
    ROUND(AVG(trip_distance), 2) AS avg_distance_miles,
    ROUND(AVG(duration_seconds) / 60.0, 2) AS avg_duration_minutes,
    ROUND(SUM(trip_distance) / NULLIF(SUM(duration_seconds) / 3600.0, 0), 2) AS avg_speed_mph,
    ROUND(SUM(fare_amount), 2) AS total_fare,
    ROUND(SUM(tip_amount), 2) AS total_tips,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_trip_amount,
    ROUND(100.0 * SUM(tip_amount) / NULLIF(SUM(fare_amount), 0), 2) AS tip_rate_pct
FROM NYC_TAXI_DB.STAGING.YELLOW_TRIPS
GROUP BY GROUPING SETS (
    (TO_DATE(pickup_datetime)),
    (PULocationID),
    (DATE_PART('HOUR', pickup_datetime), day_type)
);

CREATE TABLE IF NOT EXISTS NYC_TAXI_DB.FINAL.DAILY_KPIS AS
SELECT
    trip_date,
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
FROM NYC_TAXI_DB.FINAL.KPI_AGGREGATES
WHERE aggregation_level = 'DAILY';

CREATE TABLE IF NOT EXISTS NYC_TAXI_DB.FINAL.ZONE_KPIS AS
SELECT
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
FROM NYC_TAXI_DB.FINAL.KPI_AGGREGATES
WHERE aggregation_level = 'ZONE';

CREATE TABLE IF NOT EXISTS NYC_TAXI_DB.FINAL.HOURLY_PATTERNS AS
SELECT
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
FROM NYC_TAXI_DB.FINAL.KPI_AGGREGATES
WHERE aggregation_level = 'HOURLY';
