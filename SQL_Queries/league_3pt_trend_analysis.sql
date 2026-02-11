--LEAGUE WIDE 3PT ATTEMPTS PER SEASON
SELECT 
	t.season,
	COUNT(DISTINCT t.gameId) * 2 AS team_games,
	SUM(t.fieldGoalsAttempted) AS fga,
	SUM(t.threePointersAttempted) AS x3pa,
	ROUND(CAST(SUM(t.threePointersAttempted) AS FLOAT)
	/ NULLIF(SUM(t.fieldGoalsAttempted), 0), 4) AS three_point_rate,
	ROUND((SUM(fieldGoalsMade) + 0.5 * SUM(threePointersMade))
	/ NULLIF(SUM(fieldGoalsAttempted), 0), 4) AS eFG_percent
INTO league_3pt_volume_by_season
FROM team_stats_clean t
JOIN games_clean g
ON t.gameId = g.gameId
WHERE g.game_type_clean = 'Regular'
GROUP BY t.season

SELECT * FROM league_3pt_volume_by_season
ORDER BY season desc

--LEAGUE WIDE 3P%, 2P% AND FG% PER SEASON
SELECT 
	t.season,
	SUM(t.fieldGoalsAttempted) AS FGA,
	SUM(t.threePointersAttempted) AS x3PA,
	SUM(t.threePointersMade) AS x3PM,
	(SUM(t.fieldGoalsAttempted)-SUM(t.threePointersAttempted)) AS x2P_A,
	(SUM(t.fieldGoalsMade)-SUM(t.threePointersMade)) AS x2P_M,
	ROUND(CAST(SUM(t.threePointersMade) AS FLOAT)
	/ NULLIF(SUM(t.threePointersAttempted), 0), 4) AS x3P_percent,
	ROUND(CAST((SUM(fieldGoalsMade) - SUM(threePointersMade)) AS FLOAT)
    / NULLIF((SUM(fieldGoalsAttempted) - SUM(threePointersAttempted)), 0),4) AS x2P_percent,
	ROUND(CAST(SUM(t.fieldGoalsMade) AS FLOAT)
	/ NULLIF(SUM(t.fieldGoalsAttempted), 0), 4) AS FG_percent
FROM team_stats_clean t
JOIN games_clean g
ON t.gameId = g.gameId
WHERE g.game_type_clean = 'Regular'
GROUP BY t.season
ORDER BY t.season desc


--LEAGUE WIDE 3P INFLECTION YEAR-OVER-YEAR
CREATE VIEW vw_league_3pt_yoy_inflection AS
WITH base AS (
    SELECT
        season,
        three_point_rate,
        three_point_rate - LAG(three_point_rate) OVER (ORDER BY season) AS yoy_change
    FROM league_3pt_volume_by_season
)
SELECT
    season,
    three_point_rate,
    ROUND(yoy_change, 4) AS yoy_change,
    CASE
        WHEN yoy_change >= 0.02 THEN 'Inflection'
        ELSE 'Normal'
    END AS change_flag
FROM base;


