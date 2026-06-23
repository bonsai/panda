# Panda PRD — SQL-only Gomoku & Dot Animation Engine

## Vision

SQLというデータの道具だけでインタラクティブなゲームとアニメーションを駆動する。
余計なランタイム不要、`sqlite3` ひとつで完結するミニマルな遊び場。

## コアコンセプト

- **SQL-only**: 外部コード不要。すべてSQLite SQL + トリガー + 再帰CTE
- **1行=1手**: `INSERT INTO gomoku_place` が唯一の操作インターフェース
- **ドットアニメーション**: 盤面更新をフレームとして、パラパラ漫画的に再生できる
- **ゼロセットアップ**: `sqlite3 panda.db ".read schema.sql"` で即起動

## Target Users

- SQLが好きで「無駄なこと」を真面目にやりたい人
- DB設計の勉強中で楽しいサンプルが欲しい人
- ターミナルで遊べる軽いゲームを探している人

## Features

### Phase 1 — Core (✅ Done)
- [x] 15×15 五目並べ
- [x] 自動ターン切替 (B/W)
- [x] 勝敗判定 (再帰CTE, 4方向5並び)
- [x] 占有チェック
- [x] 盤面表示ビュー (半角ASCII)
- [x] setup.ps1 (sqlite3自動インストール)
- [x] Start-Demo (FPS指定アニメーション再生)

### Phase 2 — Enhancement (🟡 Planned)
- [ ] **Undo**: 最後の手を取り消す (`DELETE FROM gomoku_moves` + 盤面再計算)
- [ ] **棋譜保存/読込**: ゲーム単位で保存、`gomoku_replay` で再現
- [ ] **盤面サイズ選択**: 9×9 / 13×13 / 15×15 / 19×19
- [ ] **ハンディキャップ**: 指定した石数を先に置いた状態で開始
- [ ] **リプレイアニメーション**: 過去の棋譜をフレーム単位で再生

### Phase 3 — Multi-Game (🔵 Future)
- [ ] **オセロ**: `gomoku_board` テーブルを共用、着手ルールと勝敗判定を差し替え
- [ ] **チェッカー**: 同様のパターンで拡張
- [ ] **dot-sql汎用エンジン**: プレーンなドットアニメーション作成機能

### Phase 4 — Platform (🟣 Future)
- [ ] **Web UI**: 薄いブラウザラッパー、裏はSQLiteのまま
- [ ] **AI対戦**: SQLのCTEで評価関数 (チャレンジ)
- [ ] **Oracle版**: PL/SQLパッケージとしてのpanda移植

## Architecture

```
User (sqlite3 CLI)
  │ INSERT INTO gomoku_place
  ▼
Trigger trg_gomoku_place
  ├── gomoku_moves (履歴)
  └── gomoku_board (盤面)
        │
        ▼
Views
  ├── gomoku_display  ── 盤面表示
  ├── gomoku_state    ── 状態 (ターン/手数/勝敗)
  └── gomoku_win      ── 勝敗判定 (再帰CTE)
```

- 外部依存: **sqlite3 のみ**
- データ: `panda.db` 1ファイル
- 言語: SQL (PowerShellは補助)

## Non-Goals

- Webアプリ化 (薄いラッパーは許容)
- マルチプレイヤーオンライン
- 二大巨塔 (囲碁・将棋) — ルールが複雑すぎる
- 画像出力
