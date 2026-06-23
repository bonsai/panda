-- switch.sql — ゲーム切替（DROP + 盤面クリア）
--
-- 使い方:
--   .read schema/switch.sql
--   .read schema/10-gomoku.sql      -- 五目並べ
--   または
--   .read schema/20-tictactoe.sql   -- 三目並べ
--   または
--   .read schema/30-othello.sql     -- オセロ

DROP VIEW IF EXISTS gomoku_display;
DROP VIEW IF EXISTS gomoku_state;
DROP VIEW IF EXISTS gomoku_win;
DROP VIEW IF EXISTS gomoku_place;
DROP TRIGGER IF EXISTS trg_gomoku_place;
DELETE FROM gomoku_moves;
DELETE FROM gomoku_board;
