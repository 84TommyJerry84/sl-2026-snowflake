USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;

WITH base_2025 AS (
    SELECT
        *,
        TO_TIMESTAMP_NTZ(tpep_pickup_datetime, 6) AS pickup_datetime,
        TO_TIMESTAMP_NTZ(tpep_dropoff_datetime, 6) AS dropoff_datetime
    FROM NYC_TAXI_DB.RAW.YELLOW_TRIPS
    WHERE TO_TIMESTAMP_NTZ(tpep_pickup_datetime, 6) >= '2025-01-01'
      AND TO_TIMESTAMP_NTZ(tpep_pickup_datetime, 6) < '2026-01-01'
)
SELECT
    COUNT(*) AS total_lignes,
    COUNT_IF(
        COALESCE(fare_amount < 0, FALSE)
        OR COALESCE(total_amount < 0, FALSE)
        OR COALESCE(trip_distance = 0, FALSE)
        OR COALESCE(trip_distance > 1000, FALSE)
        OR COALESCE(dropoff_datetime <= pickup_datetime, FALSE)
    ) AS lignes_rejetees,
    ROUND(
        100.0 * COUNT_IF(
            COALESCE(fare_amount < 0, FALSE)
            OR COALESCE(total_amount < 0, FALSE)
            OR COALESCE(trip_distance = 0, FALSE)
            OR COALESCE(trip_distance > 1000, FALSE)
            OR COALESCE(dropoff_datetime <= pickup_datetime, FALSE)
        ) / COUNT(*),
        2
    ) AS taux_rejet
FROM base_2025;
