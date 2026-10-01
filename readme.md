# Brief NYC Yellow Taxi — Snowflake / dbt

Projet Data Engineering réalisé à partir des données **NYC Yellow Taxi**.

L’objectif est de construire une chaîne complète d’ingestion, nettoyage, transformation, contrôle qualité et restitution avec **Snowflake**, **dbt Core**, **GitHub Actions** et **Streamlit**.

---

## Architecture

```text
Fichiers Parquet NYC Taxi
        +
taxi_zone_lookup.csv
        |
        v
Snowflake Stage
        |
        v
RAW
YELLOW_TRIPS
TAXI_ZONES
        |
        v
STAGING
Nettoyage + enrichissements
        |
        v
FINAL
DAILY_KPIS
ZONE_KPIS
HOURLY_PATTERNS
        |
        +----------+
        |          |
       dbt     Streamlit
        |
 GitHub Actions
```

La période analytique retenue est **l'année 2025 complète**.

---

## Volumes et qualité des données

Données RAW 2025 :

```text
48 722 579 lignes
```

Principales règles de rejet :

```text
fare_amount < 0
total_amount < 0
trip_distance = 0
trip_distance > 1000
dropoff_datetime <= pickup_datetime
```

Résultat :

| Indicateur | Valeur |
|---|---:|
| Lignes RAW 2025 | 48 722 579 |
| Lignes rejetées | 4 541 544 |
| Lignes valides | 44 181 035 |
| Taux de rejet | 9,32 % |

Les valeurs manquantes sont analysées et documentées mais ne provoquent pas systématiquement le rejet d'une course.

---

## Enrichissements

La couche STAGING ajoute notamment :

- durée du trajet ;
- vitesse moyenne ;
- taux de pourboire ;
- catégorie de distance ;
- période de la journée ;
- distinction `WEEKDAY / WEEKEND`.

La couche FINAL contient les agrégations nécessaires à l'analyse :

```text
DAILY_KPIS         365 lignes
ZONE_KPIS          262 lignes
HOURLY_PATTERNS     48 lignes
```

L'objectif est d'éviter de rescanner les 44 millions de trajets pour chaque visualisation.

---

## dbt Core

Le projet dbt est disponible dans :

```text
nyc_taxi/
```

Organisation :

```text
models/
├── staging/
│   └── stg_yellow_trips.sql
├── intermediate/
│   └── int_kpi_aggregates.sql
└── marts/
    ├── mart_daily_kpis.sql
    ├── mart_hourly_patterns.sql
    └── mart_zone_kpis.sql
```

Résultats :

```text
dbt run
PASS=5
ERROR=0
```

```text
dbt test
PASS=11
ERROR=0
```

Les tests contrôlent notamment :

- les valeurs nulles ;
- l'unicité ;
- les valeurs autorisées ;
- les volumes attendus des marts.

La documentation dbt est générée avec :

```bash
dbt docs generate
dbt docs serve
```

---

## GitHub Actions

Le workflow CI est situé dans :

```text
.github/workflows/dbt.yml
```

Il :

1. installe Python et dbt ;
2. se connecte à Snowflake via GitHub Secrets ;
3. vérifie la connexion ;
4. exécute `dbt build`.

Le workflow a été testé avec succès.

---

## Dashboard Streamlit

Un dashboard **Streamlit in Snowflake** permet de visualiser les principales métriques :

- 44 181 035 trajets valides ;
- environ 1,28 milliard de dollars de chiffre d'affaires ;
- revenu moyen par trajet ;
- distance et durée moyennes ;
- taux de pourboire ;
- évolution quotidienne ;
- top des zones de prise en charge ;
- heure de pointe ;
- comparaison semaine / week-end ;
- taux de rejet des données.

Le dashboard interroge principalement les tables agrégées de la couche FINAL afin de limiter le coût et le temps de calcul.

---

## Principaux choix techniques

- Warehouse Snowflake `XSMALL`
- `AUTO_SUSPEND = 60`
- période analytique limitée à 2025
- agrégations matérialisées dans FINAL
- vues dbt pour limiter les recalculs
- `threads = 1` dans dbt
- secrets Snowflake non versionnés dans Git

---

## Exécution dbt

```powershell
cd nyc_taxi

dbt debug
dbt run
dbt test
```

ou :

```powershell
dbt build
```

---

## Structure du dépôt

```text
sl-2026-snowflake/
├── .github/
│   └── workflows/
│       └── dbt.yml
├── data/
├── nyc_taxi/
├── carto_data.ipynb
├── .gitignore
└── readme.md
```

Les fichiers Parquet volumineux ne sont pas versionnés dans Git.

---

## Résultat

Le projet permet de passer de :

```text
48,7 millions de lignes RAW
```

à :

```text
44,18 millions de trajets nettoyés
```

puis à des tables analytiques légères, testées et directement exploitables par le dashboard.
