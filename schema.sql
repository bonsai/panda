-- Panda: SQL-only Gomoku (五目並べ) on SQLite
-- 15×15 board, pure SQL. 1 INSERT = 1 move.
--
-- Usage:
--   sqlite3 panda.db ".read schema.sql"
--   sqlite3 panda.db
--     > INSERT INTO gomoku_place(x,y) VALUES(7,7);
--     > SELECT * FROM gomoku_display;
--     > SELECT * FROM gomoku_win;

CREATE TABLE IF NOT EXISTS gomoku_board (
    x       INT NOT NULL,
    y       INT NOT NULL,
    stone   CHAR(1) DEFAULT '.',
    move_no INT,
    PRIMARY KEY (x, y)
);

CREATE TABLE IF NOT EXISTS gomoku_moves (
    move_no   INTEGER PRIMARY KEY AUTOINCREMENT,
    x         INT NOT NULL,
    y         INT NOT NULL,
    stone     CHAR(1) NOT NULL,
    played_at TEXT DEFAULT (datetime('now','localtime'))
);

-- 盤面初期化 (15×15)
INSERT OR IGNORE INTO gomoku_board (x, y)
WITH RECURSIVE seq(v) AS (SELECT 1 UNION ALL SELECT v+1 FROM seq WHERE v < 15)
SELECT a.v, b.v FROM seq a CROSS JOIN seq b;

-- 着手用ビュー＋トリガー（INSERT 1行 = 1手、自動ターン切替＋占有チェック）
CREATE VIEW IF NOT EXISTS gomoku_place AS SELECT 0 AS x, 0 AS y WHERE 0;

CREATE TRIGGER IF NOT EXISTS trg_gomoku_place
INSTEAD OF INSERT ON gomoku_place
BEGIN
    SELECT RAISE(ABORT, 'Cell occupied')
    FROM gomoku_board WHERE x=NEW.x AND y=NEW.y AND stone!='.';
    INSERT INTO gomoku_moves (x, y, stone)
    SELECT NEW.x, NEW.y, COALESCE(
        (SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END
         FROM gomoku_moves ORDER BY move_no DESC LIMIT 1), 'B');
    UPDATE gomoku_board SET
        stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1),
        move_no=(SELECT MAX(move_no) FROM gomoku_moves)
    WHERE x=NEW.x AND y=NEW.y;
END;

-- 盤面表示
CREATE VIEW IF NOT EXISTS gomoku_display AS
SELECT printf('%2d', y) || ' ' ||
    group_concat(CASE stone
        WHEN 'B' THEN '●' WHEN 'W' THEN '○' ELSE ' .'
    END, ' ') AS board_line
FROM gomoku_board GROUP BY y ORDER BY y;

-- 勝敗判定（最終手から4方向を再帰CTEで走査）
CREATE VIEW IF NOT EXISTS gomoku_win AS
WITH RECURSIVE
last_stone AS (
    SELECT x, y, stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1
),
dirs(dx, dy) AS (VALUES (1,0), (0,1), (1,1), (1,-1)),
fwd(dx, dy, steps) AS (
    SELECT dx, dy, 0 FROM dirs
    UNION ALL
    SELECT f.dx, f.dy, f.steps+1 FROM fwd f, last_stone ls, gomoku_board b
    WHERE b.x=ls.x+f.dx*(f.steps+1) AND b.y=ls.y+f.dy*(f.steps+1)
      AND b.stone=ls.stone AND f.steps<4
),
rev(dx, dy, steps) AS (
    SELECT dx, dy, 0 FROM dirs
    UNION ALL
    SELECT r.dx, r.dy, r.steps+1 FROM rev r, last_stone ls, gomoku_board b
    WHERE b.x=ls.x-r.dx*(r.steps+1) AND b.y=ls.y-r.dy*(r.steps+1)
      AND b.stone=ls.stone AND r.steps<4
),
line(dx, dy, cnt) AS (
    SELECT f.dx, f.dy,
        (SELECT MAX(steps) FROM fwd WHERE dx=f.dx AND dy=f.dy) +
        (SELECT MAX(steps) FROM rev WHERE dx=f.dx AND dy=f.dy) + 1
    FROM (SELECT DISTINCT dx, dy FROM dirs) f
)
SELECT stone, 'WIN!' AS result, MAX(cnt) AS line
FROM last_stone ls, line WHERE cnt>=5 GROUP BY stone;

-- ゲーム状態
CREATE VIEW IF NOT EXISTS gomoku_state AS
SELECT COALESCE((SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END
          FROM gomoku_moves ORDER BY move_no DESC LIMIT 1), 'B') AS turn,
    (SELECT COUNT(*) FROM gomoku_moves) AS move_count,
    CASE WHEN EXISTS (SELECT 1 FROM gomoku_win)
         THEN (SELECT stone||'_WIN' FROM gomoku_win LIMIT 1)
         ELSE 'PLAYING' END AS status;
