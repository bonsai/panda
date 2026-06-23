-- 00-board.sql — 共通テーブル定義（全ゲームで共用）
--
-- 使い方（初回のみ .read する。ゲーム切替は switch.sql → 10/20/30 の順）:
--   sqlite3 panda.db ".read schema/00-board.sql"
--   sqlite3 panda.db ".read schema/10-gomoku.sql"

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
