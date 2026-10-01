# Analyse réflexive — Projet NYC Yellow Taxi

## 1. Contexte du projet

Ce projet avait pour objectif de construire une chaîne de traitement de données complète à partir des données NYC Yellow Taxi.

L'architecture mise en place repose sur plusieurs couches :

```text
Amazon S3
    ↓
Snowflake External Stage
    ↓
RAW
    ↓
STAGING
    ↓
FINAL
    ↓
dbt
    ↓
Streamlit
```

Le projet utilise une année complète de données, soit l'année 2025.

Le volume traité représente environ **48,7 millions de lignes brutes**, ramenées à environ **44,18 millions de trajets valides** après application des règles de qualité.

---

## 2. Difficultés rencontrées et solutions apportées

### Qualité des données

La première difficulté a été liée à la qualité des données sources.

Les données NYC Taxi contiennent notamment :

- des montants négatifs ;
- des distances égales à zéro ;
- des distances aberrantes supérieures à 1000 miles ;
- des dates de fin de trajet antérieures ou égales aux dates de départ ;
- des valeurs manquantes sur certaines colonnes.

J'ai donc défini des règles de contrôle explicites dans la couche STAGING.

Les lignes présentant les anomalies considérées comme invalidantes sont rejetées, tandis que les valeurs manquantes sont conservées lorsqu'elles n'empêchent pas l'analyse.

Cette approche permet de distinguer une donnée réellement incohérente d'une donnée simplement incomplète.

Le taux de rejet obtenu est d'environ **9,32 %**, soit :

```text
48 722 579 lignes RAW
4 541 544 lignes rejetées
44 181 035 lignes valides
```

Cette étape m'a permis de comprendre l'importance de mesurer et de justifier les règles de qualité plutôt que de simplement supprimer les données problématiques.

---

### Gestion d'un volume important de données

Le deuxième enjeu concernait le volume de données.

Scanner plus de 44 millions de lignes pour chaque analyse ou chaque graphique aurait été coûteux et peu performant.

J'ai donc choisi de créer des agrégations dans la couche FINAL :

```text
DAILY_KPIS
ZONE_KPIS
HOURLY_PATTERNS
```

Cela permet au dashboard de travailler sur quelques centaines de lignes au lieu de rescanner l'ensemble de la table STAGING.

J'ai également utilisé un warehouse Snowflake `XSMALL` avec :

```text
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
```

afin de limiter la consommation de crédits Snowflake.

---

### Mise en place du chargement externe

Au début du projet, les fichiers étaient chargés depuis un stage interne Snowflake.

En relisant le brief et les bonnes pratiques, j'ai identifié que l'architecture demandée reposait sur un stage externe.

J'ai donc fait évoluer l'architecture pour utiliser :

```text
Amazon S3
    ↓
IAM Role
    ↓
Snowflake Storage Integration
    ↓
External Stage
```

Les fichiers Parquet 2025 et le référentiel des zones sont maintenant stockés dans un bucket S3 privé.

L'accès entre Snowflake et AWS est réalisé avec une Storage Integration et un rôle IAM.

Aucune clé AWS n'est stockée directement dans les scripts SQL.

Cette évolution m'a permis de mieux comprendre la séparation entre stockage objet, data warehouse et gestion des identités cloud.

---

### Gestion des droits Snowflake

Une autre amélioration importante concernait le workflow GitHub Actions.

Initialement, dbt utilisait le rôle Snowflake :

```text
ACCOUNTADMIN
```

Ce rôle possède beaucoup plus de privilèges que nécessaire pour une pipeline CI.

J'ai donc créé un rôle dédié :

```text
DBT_CI_ROLE
```

auquel seuls les droits nécessaires à l'exécution de dbt ont été accordés.

Cette modification applique le principe du moindre privilège et améliore la sécurité de l'architecture.

---

### Enrichissement géographique

Le référentiel `taxi_zone_lookup.csv` permet d'associer les identifiants de zones des courses avec un arrondissement et un nom de zone.

Une difficulté est apparue lors de la jointure car le nom de colonne chargé dans Snowflake devait correspondre au champ :

```text
LocationID
```

Après correction du schéma RAW et de la jointure, les informations géographiques ont pu être intégrées correctement dans les KPIs par zone.

Cela m'a rappelé qu'une erreur de nommage ou de typage dans une donnée de référence peut avoir des conséquences sur toute la chaîne analytique.

---

## 3. Choix techniques et justification

### Architecture RAW / STAGING / FINAL

J'ai séparé les données en trois couches.

**RAW** conserve les données sources aussi proches que possible de leur état d'origine.

**STAGING** applique le typage, le nettoyage et les enrichissements nécessaires.

**FINAL** contient des tables adaptées directement aux usages analytiques.

Cette séparation améliore la lisibilité du pipeline, facilite le débogage et permet de rejouer les transformations sans modifier la donnée source.

---

### Snowflake

Snowflake a été utilisé comme Data Warehouse afin de centraliser le stockage analytique et les transformations SQL.

Son fonctionnement avec séparation du stockage et du calcul permet également de contrôler plus facilement les coûts de calcul.

---

### dbt Core

Le projet dbt est organisé selon trois niveaux :

```text
staging
intermediate
marts
```

dbt est utilisé pour structurer la couche analytique, versionner les modèles SQL, exécuter des tests et générer la documentation.

Les tests contrôlent notamment :

```text
not_null
unique
accepted_values
volumétrie attendue
```

Le traitement principal des 44 millions de lignes reste réalisé dans les scripts SQL Snowflake du tronc commun.

dbt intervient ensuite pour industrialiser et tester la couche analytique.

---

### GitHub Actions

GitHub Actions permet d'automatiser :

```text
dbt debug
dbt build
tests dbt
```

La connexion Snowflake repose sur des GitHub Secrets afin qu'aucun mot de passe ne soit versionné dans le repository.

Le workflow peut être exécuté manuellement et est également planifié mensuellement.

---

### Streamlit

Streamlit in Snowflake est utilisé pour présenter les principaux KPIs.

Le dashboard utilise principalement les tables agrégées du schéma FINAL.

Cette architecture évite de réaliser des calculs lourds à chaque chargement de la page.

---

## 4. Compétences acquises

Ce projet m'a permis de travailler sur plusieurs dimensions du métier de Data Engineer :

- ingestion de fichiers Parquet et CSV ;
- stockage objet avec Amazon S3 ;
- IAM et gestion des droits cloud ;
- Snowflake et architecture de Data Warehouse ;
- stages externes et Storage Integration ;
- nettoyage et contrôle qualité en SQL ;
- création de KPIs et agrégations ;
- dbt Core ;
- tests de données ;
- documentation dbt ;
- automatisation avec GitHub Actions ;
- gestion des secrets ;
- visualisation avec Streamlit ;
- optimisation des coûts et des volumes.

Le projet m'a surtout permis de comprendre qu'un pipeline de données ne se limite pas à transformer des données.

Il faut également prendre en compte la qualité, la sécurité, les coûts, la documentation, la reproductibilité et l'exploitation.

---

## 5. Compétences à approfondir

Plusieurs sujets pourraient être approfondis dans une version plus avancée du projet.

Je souhaiterais notamment approfondir l'orchestration de pipelines plus complexes, les stratégies de chargement incrémental, l'utilisation avancée de dbt, ainsi que la gestion des environnements de développement, de recette et de production.

Une autre amélioration possible serait de déplacer davantage de logique de transformation dans dbt afin que celui-ci pilote directement une plus grande partie de la chaîne de transformation.

Enfin, la mise en place d'une supervision plus complète permettrait de suivre automatiquement les volumes chargés, les taux de rejet, les échecs de pipeline et la consommation Snowflake.

---

## 6. Parallèle avec un contexte professionnel

Ce projet reproduit plusieurs problématiques rencontrées dans un environnement Data Engineering réel.

Les données sources ne sont pas parfaitement propres et doivent être contrôlées avant leur exploitation.

Les volumes nécessitent de réfléchir aux performances et aux coûts.

Les accès aux systèmes doivent respecter le principe du moindre privilège.

Les secrets ne doivent pas être présents dans le code.

Les transformations doivent être testées, documentées et versionnées.

Enfin, les données produites doivent pouvoir être exploitées facilement par les utilisateurs métier.

L'évolution du projet illustre également une situation professionnelle réaliste : une première solution fonctionnelle n'est pas nécessairement la solution finale.

Par exemple, le passage d'un stage interne Snowflake à un stockage S3 avec stage externe, ou le remplacement d'`ACCOUNTADMIN` par un rôle dédié, sont des améliorations apportées après une première implémentation fonctionnelle.

Cette démarche d'itération, de revue et d'amélioration continue fait partie intégrante du métier de Data Engineer.

---

## Conclusion

Ce projet m'a permis de mettre en œuvre une chaîne Data Engineering complète :

```text
Source
→ S3
→ Snowflake RAW
→ STAGING
→ FINAL
→ dbt
→ GitHub Actions
→ Streamlit
```

Au-delà de la réalisation technique, le principal apprentissage a été de comprendre l'importance d'une architecture reproductible, sécurisée, testée et documentée.

Les difficultés rencontrées pendant le projet ont permis de faire évoluer progressivement la solution vers une architecture plus proche des pratiques rencontrées dans un contexte professionnel.
