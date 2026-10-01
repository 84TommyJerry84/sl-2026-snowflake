with row_counts as (

    select
        'mart_daily_kpis' as model_name,
        count(*) as actual_rows,
        365 as expected_rows
    from {{ ref('mart_daily_kpis') }}

    union all

    select
        'mart_hourly_patterns',
        count(*),
        48
    from {{ ref('mart_hourly_patterns') }}

    union all

    select
        'mart_zone_kpis',
        count(*),
        262
    from {{ ref('mart_zone_kpis') }}

)

select *
from row_counts
where actual_rows <> expected_rows