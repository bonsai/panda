# Panda Recap

SQLite だけで作った五目並べ・三目並べ・オセロ。
`INSERT INTO gomoku_place(x,y)` が唯一の操作、再帰CTEで勝敗判定。

## 構成

```
schema/
├── 00-board.sql       テーブル定義（全ゲーム共通）
├── 10-gomoku.sql      五目並べ 15×15, 5並び
├── 20-tictactoe.sql   三目並べ 3×3, 全パターン列挙
├── 30-othello.sql     オセロ 8×8, 8方向フリップ
└── switch.sql         ゲーム切替
setup.ps1              sqlite3自動インストール + アニメーションデモ
docs/
├── PRD.md             要件定義
└── adr/ADR-001-halfwidth-display.md  半角ASCII統一
.github/workflows/test.yml  CIテスト（push時自動）
```

## Issues

| # | タイトル | 状態 |
|---|---------|------|
| 1 | 全角ズレ問題 | ✅ Closed |
| 2 | Undo機能 | ⏳ Open |
| 3 | 棋譜保存/リプレイ | ⏳ Open |
| 4 | 盤面サイズ選択 | ⏳ Open |
| 5 | オセロ版 | ✅ 実装済 |
| 6 | CIテスト | ✅ 実装済 |

## 感想

**面白いところ:**
- 再帰CTEで勝敗判定をSQLだけで完結
- 3ゲームが同じテーブル構造で動く設計
- sqlite3 以外に依存がゼロ
- オセロの8方向フリップをトリガー8連打で実現

**気になること:**
- 需要の不明確さ — 誰が何のために使うのか
- ドキュメントに対してコード量がまだ少ない
- プロダクトとしての体温が低い（作ったことが目的化）
- 勝敗判定が最終手のみ参照するエッジケース
