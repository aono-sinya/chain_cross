# 動作確認手順 (ローカル)

## 1. 起動

```powershell
Copy-Item .env.example .env
docker compose up --build -d
```

`besu` のヘルスチェックが通るのを待ちます (`docker compose ps` で確認)。

## 2. コントラクトをデプロイ

```powershell
docker compose exec contracts ./deploy.sh
# Windows でパーミッションが落ちる場合:
# docker compose exec contracts bash deploy.sh
```

内部では Foundry が以下を実行します:

1. `forge build` でコンパイル
2. `forge create contracts/CollabManager.sol:CollabManager --rpc-url $BESU_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json`
3. `forge inspect ... abi` で ABI を抽出
4. `/shared/{deployment.json, CollabManager.abi.json, CollabCurrency.abi.json}` に出力
反映には Rails を再起動するのが確実です。

```powershell
docker compose restart admin worker
```

## 3. サンプルデータ投入

ブラウザで http://localhost:3000 にアクセス。

1. **Titles** で `title-a` / `title-b` を登録 (endpoint は `http://game-a:4001` 等)
2. **Collabs** で「春のコラボ」など登録(start_at, end_at, 参加タイトル)
3. コラボの詳細画面で **Deploy on Besu** を実行 → `CollabCurrency` が新規デプロイされ、両タイトルが有効化される
4. **+ New Quest** / **+ New Reward** で各タイトル用のクエスト/報酬を登録

## 4. ゲームモック経由で取引を発生させる

```powershell
# クエスト達成 (Game A プレイヤーが quest-xxx をクリア)
curl -X POST http://localhost:4001/quests/clear `
  -H "Content-Type: application/json" `
  -d '{"collabId":"<COLLAB_ID>","questId":"<QUEST_ID>","playerId":"user-001"}'

# 残高確認
curl http://localhost:4001/players/user-001/balance/<COLLAB_ID>

# 報酬交換
curl -X POST http://localhost:4001/rewards/redeem `
  -H "Content-Type: application/json" `
  -d '{"collabId":"<COLLAB_ID>","rewardId":"<REWARD_ID>","playerId":"user-001"}'
```

## 5. BigQuery 側のログ確認

```powershell
# tx_logs テーブルを query
curl "http://localhost:9050/bigquery/v2/projects/chaincross-local/queries" `
  -H "Content-Type: application/json" `
  -d '{"query":"SELECT * FROM chaincross.tx_logs ORDER BY occurred_at DESC LIMIT 20","useLegacySql":false}'
```

## 6. コラボ期間終了後の通貨消滅

`end_at` を過ぎたら、Collab 詳細画面の **Sweep** ボタンを押す。
オンチェーンでは `CollabCurrency.sweep()` が呼ばれ `totalSupply=0` & `swept=true` となり、`effectiveBalanceOf` は常に 0 を返すようになります。

## トラブルシュート

- Besu の RPC が空の場合: `docker compose logs besu` を確認(初期ブロックの生成に数秒かかる)
- Firestore の書き込みエラー: `FIRESTORE_EMULATOR_HOST` が設定されているか
- BigQuery エラー: `bigquery` コンテナが起動しているか、`tx_logs` テーブルは初期化時に作成

## テスト

### Solidity (Foundry)

```powershell
docker compose exec contracts ./test.sh
# Windows でパーミッション落ち: docker compose exec contracts bash test.sh
# 個別実行: docker compose exec contracts bash test.sh --match-test test_Sweep_AfterEnd_Succeeds_AndZerosBalance
```

初回実行時に `forge-std` を自動取得します(以降は `contracts/lib/forge-std/` にキャッシュ)。

### Rails (Minitest)

```powershell
docker compose exec admin bin/rails test
```

Firestore / BigQuery / Besu には接続せず、in-memory のフェイク実装で動作します(`RAILS_ENV=test` を自動判定)。

