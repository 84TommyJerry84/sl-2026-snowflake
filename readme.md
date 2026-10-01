# NYC Yellow Taxi — Snowflake / dbt

Projet Data Engineering réalisé à partir des données **NYC Yellow Taxi** sur l'année **2025**.

L'objectif est de construire une chaîne complète d'ingestion, nettoyage, transformation, contrôle qualité et restitution avec **Amazon S3, Snowflake, dbt Core, GitHub Actions et Streamlit**.

---

## Architecture

```text
Fichiers Parquet NYC Taxi + taxi_zone_lookup.csv
                    |
                    v
            Amazon S3 privé
                    |
                    v
           IAM Role / Storage Integration
                    |
                    v
          Snowflake External Stage
                    |
                    v
        RAW -> STAGING -> FINAL
                    |
             +------+------+
             |             |
            dbt        Streamlit
             |
      GitHub Actions
```

### Couches Snowflake

- **RAW** : données sources chargées sans transformation métier.
- **STAGING** : nettoyage, filtrage, typage et enrichissements.
- **FINAL** : tables analytiques agrégées pour les usages métier et le dashboard.

---

## Données et qualité

Période analysée : **2025 complète**.

| Indicateur | Valeur |
|---|---:|
| Lignes RAW | 48 722 579 |
| Lignes rejetées | 4 541 544 |
| Lignes valides | 44 181 035 |
| Taux de rejet | 9,32 % |

Principales règles de rejet :

```text
fare_amount < 0
total_amount < 0
trip_distance = 0
trip_distance > 1000
dropoff_datetime <= pickup_datetime
```

Les valeurs manquantes sont **mesurées et documentées**, mais ne provoquent pas automatiquement le rejet d'une course.

La couche STAGING ajoute notamment :

- durée du trajet ;
- vitesse moyenne ;
- taux de pourboire ;
- catégorie de distance ;
- période de la journée ;
- distinction `WEEKDAY / WEEKEND`.

---

## Tables analytiques

Le schéma `FINAL` contient notamment :

```text
DAILY_KPIS         365 lignes
ZONE_KPIS          262 lignes
HOURLY_PATTERNS     48 lignes
```

Ces agrégations permettent d'éviter de rescanner les 44 millions de trajets pour chaque visualisation.

---

## dbt Core

Le projet dbt se trouve dans :

```text
nyc_taxi/
```

Structure principale :

```text
models/
├── staging/
├── intermediate/
└── marts/
```

Résultats obtenus :

```text
dbt run   : 5 modèles exécutés avec succès
dbt test  : 11 tests réussis
```

Les tests vérifient notamment :

- les valeurs nulles ;
- l'unicité ;
- les valeurs autorisées ;
- les volumes attendus des marts.

Documentation dbt :

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
3. exécute `dbt debug` ;
4. exécute `dbt build`.

Le workflow utilise un rôle Snowflake dédié :

```text
DBT_CI_ROLE
```

afin d'appliquer le principe du moindre privilège.

Le workflow peut être lancé manuellement et est également planifié mensuellement.

---

## Dashboard Streamlit

Le code du dashboard est versionné dans :

```text
dashboard/
├── streamlit_app.py
└── pyproject.toml
```

Le dashboard affiche notamment :

- le nombre de trajets valides ;
- le chiffre d'affaires ;
- le revenu moyen par trajet ;
- la distance et la durée moyennes ;
- le taux de pourboire ;
- l'évolution quotidienne ;
- les zones les plus actives ;
- l'heure de pointe ;
- la comparaison semaine / week-end ;
- les indicateurs de qualité des données.

---

## Exécution du projet

### 1. Préparer l'infrastructure Snowflake

Exécuter les scripts SQL dans l'ordre :

```text
sql/01_setup_snowflake.sql
sql/02_create_raw_tables.sql
sql/03_load_raw.sql
sql/04_profile_quality.sql
sql/05_create_staging.sql
sql/06_create_final.sql
sql/07_load_taxi_zones.sql
sql/08_enrich_final.sql
```

Le fichier `01_setup_snowflake.sql` contient des placeholders :

```text
<AWS_ROLE_ARN>
<BUCKET_NAME>
```

à remplacer par les valeurs de l'environnement.

### 2. Exécuter dbt

```bash
cd nyc_taxi
dbt debug
dbt build
```

### 3. Générer la documentation dbt

```bash
dbt docs generate
dbt docs serve
```

---

## Structure du dépôt

```text
sl-2026-snowflake/
├── .github/
│   └── workflows/
│       └── dbt.yml
├── dashboard/
├── data/
├── docs/
│   └── analyse_reflexive.md
├── nyc_taxi/
├── sql/
├── carto_data.ipynb
├── .gitignore
└── readme.md
```

Les fichiers Parquet volumineux ne sont pas versionnés dans Git.

---

## Principaux choix techniques

- stockage objet dans **Amazon S3** ;
- accès S3 via **IAM Role + Snowflake Storage Integration** ;
- **External Stage** Snowflake ;
- warehouse `XSMALL` avec `AUTO_SUSPEND = 60` ;
- architecture `RAW / STAGING / FINAL` ;
- tables FINAL agrégées pour limiter les coûts ;
- modèles dbt matérialisés en vues ;
- secrets non versionnés dans Git ;
- rôle `DBT_CI_ROLE` dédié à la CI.

---

## Résultat

Le projet permet de passer de **48,7 millions de lignes brutes** à **44,18 millions de trajets nettoyés**, puis à des tables analytiques légères, testées et directement exploitables dans Streamlit.
