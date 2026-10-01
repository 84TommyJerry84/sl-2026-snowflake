USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;

-- Profil qualité sur l'année analytique 2025.
-- Une valeur NULL n'est pas automatiquement considérée comme invalide.
-- Les motifs de rejet peuvent se chevaucher : une ligne peut présenter
-- plusieurs anomalies simultanément.

WITH base_2025 AS (
    SELECT
        *,
        TO_TIMESTAMP_NTZ(tpep_pickup_datetime, 6) AS pickup_datetime,
        TO_TIMESTAMP_NTZ(tpep_dropoff_datetime, 6) AS dropoff_datetime
    FROM NYC_TAXI_DB.RAW.YELLOW_TRIPS
    WHERE tpep_pickup_datetime >= 1735689600000000
      AND tpep_pickup_datetime < 1767225600000000
)

SELECT
    -- ------------------------------------------------------------
    -- Volume global
    -- ------------------------------------------------------------
    COUNT(*) AS total_lignes,

    -- ------------------------------------------------------------
    -- Rejets
    -- ------------------------------------------------------------
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
    ) AS taux_rejet_pct,

    -- ------------------------------------------------------------
    -- Détail des anomalies
    -- ------------------------------------------------------------
    COUNT_IF(fare_amount < 0)
        AS montants_fare_negatifs,

    COUNT_IF(total_amount < 0)
        AS montants_total_negatifs,

    COUNT_IF(trip_distance = 0)
        AS distances_zero,

    COUNT_IF(trip_distance > 1000)
        AS distances_superieures_1000,

    COUNT_IF(dropoff_datetime <= pickup_datetime)
        AS dates_incoherentes,

    -- ------------------------------------------------------------
    -- Valeurs manquantes
    -- ------------------------------------------------------------

    COUNT_IF(passenger_count IS NULL)
        AS null_passenger_count,

    ROUND(
        100.0 * COUNT_IF(passenger_count IS NULL) / COUNT(*),
        2
    ) AS pct_null_passenger_count,

    COUNT_IF(RatecodeID IS NULL)
        AS null_ratecodeid,

    ROUND(
        100.0 * COUNT_IF(RatecodeID IS NULL) / COUNT(*),
        2
    ) AS pct_null_ratecodeid,

    COUNT_IF(store_and_fwd_flag IS NULL)
        AS null_store_and_fwd_flag,

    ROUND(
        100.0 * COUNT_IF(store_and_fwd_flag IS NULL) / COUNT(*),
        2
    ) AS pct_null_store_and_fwd_flag,

    COUNT_IF(congestion_surcharge IS NULL)
        AS null_congestion_surcharge,

    ROUND(
        100.0 * COUNT_IF(congestion_surcharge IS NULL) / COUNT(*),
        2
    ) AS pct_null_congestion_surcharge,

    COUNT_IF(Airport_fee IS NULL)
        AS null_airport_fee,

    ROUND(
        100.0 * COUNT_IF(Airport_fee IS NULL) / COUNT(*),
        2
    ) AS pct_null_airport_fee,

    COUNT_IF(cbd_congestion_fee IS NULL)
        AS null_cbd_congestion_fee,

    ROUND(
        100.0 * COUNT_IF(cbd_congestion_fee IS NULL) / COUNT(*),
        2
    ) AS pct_null_cbd_congestion_fee,

    -- Contrôle des colonnes importantes pour l'analyse

    COUNT_IF(trip_distance IS NULL)
        AS null_trip_distance,

    COUNT_IF(fare_amount IS NULL)
        AS null_fare_amount,

    COUNT_IF(total_amount IS NULL)
        AS null_total_amount,

    COUNT_IF(PULocationID IS NULL)
        AS null_pickup_location,

    COUNT_IF(DOLocationID IS NULL)
        AS null_dropoff_location

FROM base_2025;