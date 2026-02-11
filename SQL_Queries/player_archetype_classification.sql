SELECT
    personId,
    name,
    season,
    shot_usage_per_minute,
    offensive_action_per_minute,
    impact_per_minute
INTO #usage_vs_impact
FROM vw_usage_vs_impact;

WITH season_thresholds AS (
    SELECT
        season,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY shot_usage_per_minute)
            OVER (PARTITION BY season) AS median_usage,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY impact_per_minute)
            OVER (PARTITION BY season) AS median_impact,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY season) AS rn
    FROM #usage_vs_impact
)
SELECT
    p.*,
    CASE
        WHEN p.shot_usage_per_minute >= t.median_usage
         AND p.impact_per_minute >= t.median_impact
            THEN 'Star Driver'
        WHEN p.shot_usage_per_minute >= t.median_usage
         AND p.impact_per_minute < t.median_impact
            THEN 'Inefficient Dominator'
        WHEN p.shot_usage_per_minute < t.median_usage
         AND p.impact_per_minute >= t.median_impact
            THEN 'Elite Role Player'
        ELSE 'Low-Impact Role Player'
    END AS archetype
INTO dbo.player_archetypes
FROM #usage_vs_impact p
JOIN season_thresholds t
  ON p.season = t.season
 AND t.rn = 1;