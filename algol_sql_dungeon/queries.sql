
SELECT * FROM leaderboard LIMIT 10;

SELECT * FROM best_runs;

SELECT player_name, COUNT(*) AS runs
FROM runs
GROUP BY player_name
ORDER BY runs DESC;

SELECT
ROUND(
100.0 * SUM(CASE WHEN won = 1 THEN 1 ELSE 0 END) / COUNT(*),
2
) AS win_rate_percent
FROM runs;

SELECT
ROUND(
100.0 * SUM(CASE WHEN expelled = 1 THEN 1 ELSE 0 END) / COUNT(*),
2
) AS expelled_percent
FROM runs;
