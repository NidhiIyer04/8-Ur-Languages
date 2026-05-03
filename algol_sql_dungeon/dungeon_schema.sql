DROP TABLE IF EXISTS runs CASCADE;

CREATE TABLE runs (
    id SERIAL PRIMARY KEY,
    player_name TEXT NOT NULL,
    room_reached INT NOT NULL,
    clues INT NOT NULL,
    coins INT NOT NULL,
    warnings INT NOT NULL,
    won INT NOT NULL,
    expelled INT NOT NULL,
    played_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_runs_player ON runs(player_name);
CREATE INDEX idx_runs_room ON runs(room_reached);
CREATE INDEX idx_runs_won ON runs(won);

DROP VIEW IF EXISTS leaderboard;

CREATE VIEW leaderboard AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY won DESC,
                 room_reached DESC,
                 clues DESC,
                 coins DESC
    ) AS rank,
    player_name,
    room_reached,
    clues,
    coins,
    warnings,
    won,
    expelled,
    played_at::date AS played
FROM runs;

DROP VIEW IF EXISTS best_runs;

CREATE VIEW best_runs AS
SELECT DISTINCT ON (player_name)
    player_name,
    room_reached,
    clues,
    coins,
    won,
    played_at
FROM runs
ORDER BY player_name, won DESC, room_reached DESC, clues DESC;
