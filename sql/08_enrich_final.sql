USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA FINAL;

CREATE OR REPLACE TABLE NYC_TAXI_DB.FINAL.ZONE_KPIS AS
SELECT
    k.pickup_location_id,
    z.borough,
    z.zone,
    z.service_zone,
    k.trip_count,
    k.passenger_count,
    k.avg_distance_miles,
    k.avg_duration_minutes,
    k.avg_speed_mph,
    k.total_fare,
    k.total_tips,
    k.total_revenue,
    k.avg_trip_amount,
    k.tip_rate_pct
FROM NYC_TAXI_DB.FINAL.KPI_AGGREGATES k
LEFT JOIN NYC_TAXI_DB.RAW.TAXI_ZONES z
    ON k.pickup_location_id = z.LocationID
WHERE k.aggregation_level = 'ZONE';

-- Contrôle de la qualité de la jointure géographique
SELECT
    COUNT(*) AS total_zones,
    COUNT_IF(zone IS NULL) AS zones_non_trouvees
FROM NYC_TAXI_DB.FINAL.ZONE_KPIS;
