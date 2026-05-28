# アーキテクチャ概要

## レイヤー構成

```
┌──────────────┐         ┌─────────────────────────────┐
│ Game A / B   │ HTTP    │ Rails Admin (3000)          │
│ (Node mock)  │ ──────▶ │  - 管理UI                    │
└──────────────┘         │  - /api/v1 (game-facing)    │
                          │  - Firestore (titles/      │
                          │     collabs/quests/rewards) │
                          └─────┬───────────────┬───────┘
                                │ JSON-RPC      │ Firestore SDK
                                ▼               ▼
                          ┌──────────────┐  ┌──────────────────┐
                          │ Besu (8545)  │  │ Firestore Emu    │
                          │ Dev mode     │  └──────────────────┘
                          │ CollabMgr +  │
                          │ CollabCcy    │
                          └──────┬───────┘
                                 │ eth_getLogs (polling)
                                 ▼
                          ┌──────────────┐
                          │ Worker       │
                          │ (Rails       │
                          │  runner)     │
                          └──────┬───────┘
                                 ▼
                          ┌──────────────────┐
                          │ BigQuery Emu     │
                          │ chaincross.tx_logs│
                          └──────────────────┘
```

## オンチェーンモデル

- `CollabManager` (シングルトン): すべてのコラボイベントを束ねるエントリポイント。adminのみ操作可
- `CollabCurrency` (コラボごとにデプロイ): ERC20 ライク。整数残高、期間外は mint/burn 不可。`sweep()` で残量消滅

## 通貨有効期間 = コラボ期間 の保証

`CollabCurrency` のモディファイア `whileActive` により、`block.timestamp < startAt || block.timestamp >= endAt` の場合 mint/burn はすべてリバート。
読取用 `effectiveBalanceOf` も期間外は 0 を返す。
さらに運営は終了後 `sweep()` を呼ぶことで明示的に `totalSupply` を 0 化し、`swept = true` を立てて状態として "消滅" を表現する。

## ログ → BigQuery

worker は `eth_getLogs` で `CollabManager` のイベントをポーリングし、`QuestCleared` / `RewardRedeemed` / `CollabCreated` / `CollabSwept` を `chaincross.tx_logs` テーブルに挿入する。
最終処理ブロックは `/shared/.last_processed_block` で永続化。

## 実本番への置き換えポイント

- Besu: dev モード → QBFT/IBFT2 のマルチノード構成。バリデータ鍵管理 (key vault / HSM)
- Firestore: エミュレータ → 本番 GCP プロジェクト + サービスアカウント
- BigQuery: エミュレータ → 本番 GCP, パーティション/クラスタリング付き
- Rails: Sidekiq + Redis を導入し、worker をジョブ化 / リトライ可能に
- 権限: タイトル毎の `msg.sender` 検証(現状は admin 代理発行モデル)

