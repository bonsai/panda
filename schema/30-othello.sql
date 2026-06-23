-- 30-othello.sql — オセロ（8×8）
-- 依存: 00-board.sql が先に読み込まれていること

DELETE FROM gomoku_board;
DELETE FROM gomoku_moves;
INSERT INTO gomoku_board (x, y)
WITH RECURSIVE seq(v) AS (SELECT 1 UNION ALL SELECT v+1 FROM seq WHERE v < 8)
SELECT a.v, b.v FROM seq a CROSS JOIN seq b;

UPDATE gomoku_board SET stone='B', move_no=0 WHERE x=4 AND y=4;
UPDATE gomoku_board SET stone='W', move_no=0 WHERE x=5 AND y=5;
UPDATE gomoku_board SET stone='B', move_no=0 WHERE x=5 AND y=4;
UPDATE gomoku_board SET stone='W', move_no=0 WHERE x=4 AND y=5;

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

    -- 8方向フリップ: 最初に出現する同色石を端点とし、その手前まで反転
    -- E
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE y=NEW.y AND x BETWEEN NEW.x+1 AND (SELECT coalesce(MIN(x)-1,0) FROM gomoku_board
        WHERE x>NEW.x AND y=NEW.y AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1))
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- W
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE y=NEW.y AND x BETWEEN (SELECT coalesce(MAX(x)+1,99) FROM gomoku_board
        WHERE x<NEW.x AND y=NEW.y AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)) AND NEW.x-1
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- S
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE x=NEW.x AND y BETWEEN NEW.y+1 AND (SELECT coalesce(MIN(y)-1,0) FROM gomoku_board
        WHERE y>NEW.y AND x=NEW.x AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1))
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- N
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE x=NEW.x AND y BETWEEN (SELECT coalesce(MAX(y)+1,99) FROM gomoku_board
        WHERE y<NEW.y AND x=NEW.x AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)) AND NEW.y-1
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- SE
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE (x-y)=(NEW.x-NEW.y) AND x BETWEEN NEW.x+1 AND (SELECT coalesce(MIN(x)-1,0) FROM gomoku_board
        WHERE (x-y)=(NEW.x-NEW.y) AND x>NEW.x AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1))
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- NW
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE (x-y)=(NEW.x-NEW.y) AND x BETWEEN (SELECT coalesce(MAX(x)+1,99) FROM gomoku_board
        WHERE (x-y)=(NEW.x-NEW.y) AND x<NEW.x AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)) AND NEW.x-1
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- NE
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE (x+y)=(NEW.x+NEW.y) AND x BETWEEN NEW.x+1 AND (SELECT coalesce(MIN(x)-1,0) FROM gomoku_board
        WHERE (x+y)=(NEW.x+NEW.y) AND x>NEW.x AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1))
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
    -- SW
    UPDATE gomoku_board SET stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)
    WHERE (x+y)=(NEW.x+NEW.y) AND x BETWEEN (SELECT coalesce(MAX(x)+1,99) FROM gomoku_board
        WHERE (x+y)=(NEW.x+NEW.y) AND x<NEW.x AND stone=(SELECT stone FROM gomoku_moves ORDER BY move_no DESC LIMIT 1)) AND NEW.x-1
    AND stone=(SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END FROM gomoku_moves ORDER BY move_no DESC LIMIT 1);
END;

CREATE VIEW IF NOT EXISTS gomoku_display AS
SELECT printf('%2d', y) || ' ' ||
    group_concat(CASE stone WHEN 'B' THEN '#' WHEN 'W' THEN 'o' ELSE '.' END, ' ') AS board_line
FROM gomoku_board GROUP BY y ORDER BY y;

CREATE VIEW IF NOT EXISTS gomoku_win AS
SELECT 'B' AS stone, 'WIN!' AS result, COUNT(*) AS line
FROM gomoku_board WHERE stone='B'
HAVING (SELECT COUNT(*) FROM gomoku_board WHERE stone='B')
     > (SELECT COUNT(*) FROM gomoku_board WHERE stone='W')
UNION ALL
SELECT 'W', 'WIN!', COUNT(*)
FROM gomoku_board WHERE stone='W'
HAVING (SELECT COUNT(*) FROM gomoku_board WHERE stone='W')
     > (SELECT COUNT(*) FROM gomoku_board WHERE stone='B');

CREATE VIEW IF NOT EXISTS gomoku_state AS
SELECT COALESCE((SELECT CASE stone WHEN 'B' THEN 'W' ELSE 'B' END
          FROM gomoku_moves ORDER BY move_no DESC LIMIT 1), 'B') AS turn,
    (SELECT COUNT(*) FROM gomoku_moves) AS move_count,
    CASE WHEN EXISTS (SELECT 1 FROM gomoku_win)
         THEN (SELECT stone||'_WIN' FROM gomoku_win LIMIT 1)
         ELSE 'PLAYING' END AS status,
    (SELECT COUNT(*) FROM gomoku_board WHERE stone='B') AS black,
    (SELECT COUNT(*) FROM gomoku_board WHERE stone='W') AS white;
