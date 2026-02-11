CREATE VIEW vw_player_season_base AS
SELECT 
	p.personId,
	p.name,
	p.season,

	COUNT(DISTINCT p.gameId) AS total_games_played,
	SUM(p.numMinutes) AS total_minutes,

	SUM(p.fieldGoalsAttempted) AS FGA,
	SUM(p.freeThrowsAttempted) AS FTA,
	SUM(p.assists) AS assists,
	SUM(p.turnovers) AS turnovers,
	SUM(p.points) AS points,

	SUM(p.plusMinusPoints) AS total_plus_minus,
	AVG(p.plusMinusPoints) AS average_plus_minus

FROM players_stats_clean p
JOIN games_clean g
ON g.gameId = p.gameId
WHERE g.game_type_clean = 'Regular'
	  AND 
	  p.numMinutes > 0
GROUP BY
	p.personId,
	p.name,
	p.season;

--PLAYER USAGE PROXIES
CREATE VIEW vw_player_usage AS
SELECT 
	personId,
	name,
	season,
	total_games_played,
	total_minutes,
	
	FGA,
	FTA,
	assists,
	turnovers,
	points,

	ROUND(
		(FGA + 0.44 * FTA)/NULLIF(total_minutes, 0),
		4
	)AS shot_usage_per_minute,

	ROUND(
		(assists + points + turnovers)/NULLIF(total_minutes, 0),
		4
	) AS offensive_action_per_minute

FROM vw_player_season_base
WHERE total_minutes > 500

SELECT *
FROM vw_player_usage
ORDER BY shot_usage_per_minute DESC;


--PLAYER IMPACT METRICS
CREATE VIEW vw_player_impact AS
SELECT
	personId,
	name,
	season,
	total_games_played,
	total_minutes,

	total_plus_minus,

	ROUND(
		CAST(total_plus_minus AS FLOAT)
		/ NULLIF(total_minutes ,0),
		4
	) AS impact_per_minute,

	ROUND(average_plus_minus, 2) AS average_plus_minus
FROM vw_player_season_base
WHERE total_minutes > 500


SELECT * 
FROM vw_player_impact
ORDER BY impact_per_minute DESC;


--PLAYER USAGE VS IMPACT
CREATE VIEW vw_usage_vs_impact AS
SELECT 
	u.personId,
	u.name,
	u.season,

	u.shot_usage_per_minute,
	u.offensive_action_per_minute,
	i.impact_per_minute

FROM vw_player_usage u
JOIN 
vw_player_impact i 
ON u.personId = i.personId
AND u.season = i.season;

SELECT
	*
FROM vw_usage_vs_impact
ORDER BY impact_per_minute DESC;

