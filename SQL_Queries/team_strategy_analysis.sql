CREATE VIEW vw_team_strategy AS
SELECT 
	t.team,
	t.teamId,
	t.season,

	COUNT(DISTINCT t.gameId) AS games_played,
	SUM(CASE WHEN t.win = 1 THEN 1 ELSE 0 END) AS wins,

	ROUND(
		CAST(SUM(CASE WHEN t.win = 1 THEN 1 ELSE 0 END) AS FLOAT)
		/ NULLIF(COUNT(DISTINCT t.gameId), 0),
	4) AS win_pct,


	SUM(t.fieldGoalsAttempted) AS FGA,
	SUM(t.threePointersAttempted) AS x3PA,

	ROUND(
		CAST(SUM(t.threePointersAttempted) AS FLOAT)
		/ NULLIF(SUM(t.fieldGoalsAttempted), 0),
	4) AS three_point_rate

FROM team_stats_clean t
JOIN games_clean g
	ON t.gameId = g.gameId
WHERE g.game_type_clean = 'Regular'
GROUP BY
	t.team,
	t.teamId,
	t.season;


CREATE VIEW vw_team_strategy_modern AS
SELECT 
	t.team,
	t.teamId,
	t.season,

	COUNT(DISTINCT t.gameId) AS games_played,
	SUM(CASE WHEN t.win = 1 THEN 1 ELSE 0 END) AS wins,

	--WIN PERCENTAGE
	ROUND(
		CAST(SUM(CASE WHEN t.win = 1 THEN 1 ELSE 0 END) AS FLOAT)
		/ NULLIF(COUNT(DISTINCT t.gameId), 0),
	4) AS win_pct,

	SUM(t.fieldGoalsAttempted) AS FGA,
	SUM(t.threePointersAttempted) AS x3PA,

	--THREE POINT RATE
	ROUND(
		CAST(SUM(t.threePointersAttempted) AS FLOAT)
		/ NULLIF(SUM(t.fieldGoalsAttempted), 0),
	4) AS three_point_rate,

	SUM(t.teamScore) AS total_points,
	SUM(t.benchPoints) AS bench_points,
	SUM(t.pointsInThePaint) AS paint_points,

	--PAINT POINTS SHARE
	ROUND(
		CAST(SUM(t.pointsInThePaint) AS FLOAT)
		/ NULLIF(SUM(t.teamScore), 0),
	4) AS paints_point_share,

	--BENCH POINTS SHARE
	ROUND(
		CAST(SUM(t.benchPoints) AS FLOAT)
		/ NULLIF(SUM(t.teamScore), 0),
	4) AS bench_point_share

FROM team_stats_clean t
JOIN games_clean g
	ON t.gameId = g.gameId
WHERE g.game_type_clean = 'Regular'
AND t.season IN (2024, 2025)
GROUP BY
	t.team,
	t.teamId,
	t.season;

SELECT 
	*
FROM vw_team_strategy_modern
ORDER BY three_point_rate DESC;



--TEAM ARCHETYPE
CREATE VIEW vw_team_strategy_archetypes_core AS
WITH ranked AS (
    SELECT
        team,
        teamId,
        season,
        win_pct,
        three_point_rate,

        NTILE(3) OVER (
            PARTITION BY season
            ORDER BY three_point_rate DESC
        ) AS three_pt_bucket

    FROM vw_team_strategy
)
SELECT
    team,
    teamId,
    season,
    win_pct,
    three_point_rate,

    CASE
        WHEN three_pt_bucket = 1 THEN 'Three-Point Heavy'
        WHEN three_pt_bucket = 2 THEN 'Balanced'
        ELSE 'Paint-Focused'
    END AS team_strategy

FROM ranked;


--TEAM STRATEGY
CREATE VIEW vw_team_strategy_global AS
WITH base AS (
    SELECT
        season,
        team,
        teamId,
        three_point_rate,
        win_pct
    FROM vw_team_strategy
)
SELECT
    season,
    team,
    teamId,
    three_point_rate,
    win_pct,
    NTILE(3) OVER (ORDER BY three_point_rate) AS strategy_bucket,
    CASE 
        WHEN NTILE(3) OVER (ORDER BY three_point_rate) = 3 THEN 'Three-Point Heavy'
        WHEN NTILE(3) OVER (ORDER BY three_point_rate) = 2 THEN 'Balanced'
        ELSE 'Paint-Focused'
    END AS team_strategy
FROM base;