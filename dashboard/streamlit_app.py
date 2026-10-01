import os

import streamlit as st


st.set_page_config(
    page_title="NYC Yellow Taxi - 2025",
    layout="wide",
)

st.title("NYC Yellow Taxi — Analyse 2025")
st.caption("Snowflake • dbt • Streamlit")


# Connexion native Streamlit in Snowflake
conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

session = conn.session()


@st.cache_data(ttl=600)
def load_daily():
    return session.sql("""
        SELECT
            trip_date,
            trip_count,
            avg_distance_miles,
            avg_duration_minutes,
            total_fare,
            total_tips,
            total_revenue,
            avg_trip_amount
        FROM NYC_TAXI_DB.FINAL.DAILY_KPIS
        ORDER BY trip_date
    """).to_pandas()


@st.cache_data(ttl=600)
def load_hourly():
    return session.sql("""
        SELECT
            pickup_hour,
            day_type,
            trip_count,
            avg_distance_miles,
            avg_duration_minutes,
            avg_speed_mph,
            total_revenue,
            avg_trip_amount,
            tip_rate_pct
        FROM NYC_TAXI_DB.FINAL.HOURLY_PATTERNS
        ORDER BY pickup_hour, day_type
    """).to_pandas()


@st.cache_data(ttl=600)
def load_zones():
    return session.sql("""
        SELECT
            k.pickup_location_id,
            z.borough,
            z.zone,
            z.service_zone,
            k.trip_count,
            k.total_revenue,
            k.avg_trip_amount
        FROM NYC_TAXI_DB.FINAL.ZONE_KPIS k
        LEFT JOIN NYC_TAXI_DB.RAW.TAXI_ZONES z
            ON k.pickup_location_id = z.LocationID
        ORDER BY k.trip_count DESC
    """).to_pandas()


daily = load_daily()
hourly = load_hourly()
zones = load_zones()


# ------------------------------------------------------------------
# KPIs principaux
# ------------------------------------------------------------------

total_trips = int(daily["TRIP_COUNT"].sum())
total_revenue = float(daily["TOTAL_REVENUE"].sum())
total_fare = float(daily["TOTAL_FARE"].sum())
total_tips = float(daily["TOTAL_TIPS"].sum())

avg_trip_amount = total_revenue / total_trips if total_trips > 0 else 0

avg_distance = (
    (daily["AVG_DISTANCE_MILES"] * daily["TRIP_COUNT"]).sum() / total_trips
    if total_trips > 0
    else 0
)

avg_duration = (
    (daily["AVG_DURATION_MINUTES"] * daily["TRIP_COUNT"]).sum() / total_trips
    if total_trips > 0
    else 0
)

tip_rate = 100 * total_tips / total_fare if total_fare > 0 else 0

st.subheader("Indicateurs clés")

c1, c2, c3 = st.columns(3)

c1.metric("Trajets valides", f"{total_trips:,}")

c2.metric("Chiffre d'affaires", f"${total_revenue / 1_000_000_000:.2f} Md")

c3.metric("Revenu moyen / trajet", f"${avg_trip_amount:.2f}")

c4, c5, c6 = st.columns(3)

c4.metric("Distance moyenne", f"{avg_distance:.2f} miles")

c5.metric("Durée moyenne", f"{avg_duration:.1f} min")

c6.metric("Taux de pourboire", f"{tip_rate:.1f} %")


# ------------------------------------------------------------------
# Évolution quotidienne
# ------------------------------------------------------------------

st.divider()
st.subheader("Évolution quotidienne")

daily_chart = daily[["TRIP_DATE", "TRIP_COUNT", "TOTAL_REVENUE"]].set_index("TRIP_DATE")

st.write("Nombre de trajets")
st.line_chart(daily_chart["TRIP_COUNT"])

st.write("Chiffre d'affaires")
st.line_chart(daily_chart["TOTAL_REVENUE"])


# ------------------------------------------------------------------
# Analyse géographique
# ------------------------------------------------------------------

st.divider()
st.subheader("Zones de prise en charge")

top_zones = zones.dropna(subset=["ZONE"]).head(15)

st.bar_chart(top_zones.set_index("ZONE")["TRIP_COUNT"])


# ------------------------------------------------------------------
# Indicateurs opérationnels
# ------------------------------------------------------------------

st.divider()
st.subheader("Indicateurs opérationnels")

top_zone = (
    zones.dropna(subset=["ZONE"]).sort_values("TRIP_COUNT", ascending=False).iloc[0]
)

peak_hour_data = hourly.groupby("PICKUP_HOUR")["TRIP_COUNT"].sum()

peak_hour = int(peak_hour_data.idxmax())

i1, i2, i3 = st.columns(3)

i1.metric("Zone la plus active", str(top_zone["ZONE"]))

i2.metric("Trajets dans cette zone", f"{int(top_zone['TRIP_COUNT']):,}")

i3.metric("Heure de pointe", f"{peak_hour:02d}h")


# ------------------------------------------------------------------
# Semaine / week-end
# ------------------------------------------------------------------

st.divider()
st.subheader("Semaine vs week-end")

day_type = hourly.groupby("DAY_TYPE")["TRIP_COUNT"].sum()

st.bar_chart(day_type)


# ------------------------------------------------------------------
# Qualité des données
# ------------------------------------------------------------------

st.divider()
st.subheader("Qualité des données")

raw_2025 = 48_722_579
valid_2025 = 44_181_035

rejected_2025 = raw_2025 - valid_2025
rejection_rate = rejected_2025 / raw_2025 * 100

q1, q2, q3 = st.columns(3)

q1.metric("Lignes analysées", f"{raw_2025:,}")

q2.metric("Lignes rejetées", f"{rejected_2025:,}")

q3.metric("Taux de rejet", f"{rejection_rate:.2f} %")


# ------------------------------------------------------------------
# Données détaillées
# ------------------------------------------------------------------

st.divider()
st.subheader("Top zones")

st.dataframe(
    top_zones[
        [
            "PICKUP_LOCATION_ID",
            "BOROUGH",
            "ZONE",
            "TRIP_COUNT",
            "TOTAL_REVENUE",
            "AVG_TRIP_AMOUNT",
        ]
    ],
    width="stretch",
)
