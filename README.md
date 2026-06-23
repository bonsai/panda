# Panda 🐼

SQL-only Gomoku (五目並べ) on SQLite.

黒と白の石をSQLのINSERTひとつで打つ、パラパラ漫画スタイルの五目並べ。

## Quick start

```bash
sqlite3 panda.db ".read schema.sql"
sqlite3 panda.db
```

```sql
-- 盤面表示
SELECT * FROM gomoku_display;

-- 着手 (自動で黒白交互)
INSERT INTO gomoku_place(x,y) VALUES(7,7);
INSERT INTO gomoku_place(x,y) VALUES(8,8);

-- 状況確認
SELECT * FROM gomoku_state;
SELECT * FROM gomoku_win;
```

## Commands

| SQL | 内容 |
|-----|------|
| `INSERT INTO gomoku_place(x,y) VALUES(n,n)` | 着手（自動ターン切替） |
| `SELECT * FROM gomoku_display;` | 盤面表示 |
| `SELECT * FROM gomoku_state;` | 状況確認 |
| `SELECT * FROM gomoku_win;` | 勝敗判定 |
| `UPDATE gomoku_board SET stone='.', move_no=NULL; DELETE FROM gomoku_moves;` | リセット |

## How it works

- `gomoku_board`: 15×15 = 225 cells
- `gomoku_moves`: move history
- `gomoku_place`: trigger-based INSERT wrapper → auto stone color switching
- `gomoku_win`: recursive CTE checks 4 directions from the last move
- No external code, no PL, just SQLite SQL
