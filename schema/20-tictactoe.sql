-- 20-tictactoe.sql — 三目並べ（3×3）
-- 依存: 00-board.sql が先に読み込まれていること
--
-- 切替:
--   .read schema/switch.sql
--   .read schema/20-tictactoe.sql

-- 盤面初期化
DELETE FROM gomoku_board;
DELETE FROM gomoku_moves;
INSERT INTO gomoku_board (x, y)
WITH RECURSIVE seq(v) AS (SELECT 1 UNION ALL SELECT v+1 FROM seq WHERE v < 3)
SELECT a.v, b.v FROM seq a CROSS JOIN seq b;

-- 着手（共通ロジック）
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
        WHEN 'B' THEN '#' WHEN 'W' THEN 'o' ELSE '.'
    END, ' ') AS board_line
FROM gomoku_board GROUP BY y ORDER BY y;

-- 勝敗判定（3×3, 3並び。全パターン列挙）
CREATE VIEW IF NOT EXISTS gomoku_win AS
WITH
lines AS (
    -- 横3行
    SELECT stone FROM gomoku_board WHERE y=1 GROUP BY stone HAVING COUNT(*)=3 AND stone!='.'
    UNION SELECT stone FROM gomoku_board WHERE y=2 GROUP BY stone HAVING COUNT(*)=3 AND stone!='.'
    UNION SELECT stone FROM gomoku_board WHERE y=3 GROUP BY stone HAVING COUNT(*)=3 AND stone!='.'
    -- 縦3列
    UNION SELECT stone FROM gomoku_board WHERE x=1 GROUP BY stone HAVING COUNT(*)=3 AND stone!='.'
    UNION SELECT stone FROM gomoku_board WHERE x=2 GROUP BY stone HAVING COUNT(*)=3 AND stone!='.'
    UNION SELECT stone FROM gomoku_board WHERE x=3 GROUP BY stone HAVING COUNT(*)=3 AND stone!='.'
    -- 斜め2本
    UNION SELECT b1.stone FROM gomoku_board b1 JOIN gomoku_board b2 ON b2.x=2 AND b2.y=2 AND b2.stone=b1.stone
                               JOIN gomoku_board b3 ON b3.x=3 AND b3.y=3 AND b3.stone=b1.stone
          WHERE b1.x=1 AND b1.y=1 AND b1.stone!='.'
    UNION SELECT b1.stone FROM gomoku_board b1 JOIN gomoku_board b2 ON b2.x=2 AND b2.y=2 AND b2.stone=b1.stone
                               JOIN gomoku_board b3 ON b3.x=1 AND b3.y=3 AND b3.stone=b1.stone
          WHERE b1.x=3 AND b1.y=1 AND b1.stone!='.'
)
SELECT stone, 'WIN!' AS result, 3 AS line FROM lines;

-- ゲーム状態
CREATE VIEW IF NOT EXISTS gomoku_state AS
SELECT COALESCE((SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END
          FROM gomoku_moves ORDER BY move_no DESC LIMIT 1), 'B') AS turn,
    (SELECT COUNT(*) FROM gomoku_moves) AS move_count,
    CASE WHEN EXISTS (SELECT 1 FROM gomoku_win)
         THEN (SELECT stone||'_WIN' FROM gomoku_win LIMIT 1)
         WHEN (SELECT COUNT(*) FROM gomoku_moves) >= 9 THEN 'DRAW'
         ELSE 'PLAYING' END AS status;
