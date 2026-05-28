# ChainCross

Hyperledger Besu 上のプライベートチェーンで、複数のソーシャルゲームタイトルが参加する「コラボイベント」を管理するサービスのローカル開発スキャフォールドです。

## 構成

| サービス | 役割 | ポート |
|---------|------|--------|
| `besu` | Hyperledger Besu (dev モード単一ノード, JSON-RPC) | 8545 / 8546 |
| `contracts` | Foundry (forge build/create でビルド・デプロイ) | - |
| `firestore` | Firebase Firestore エミュレータ | 8080 / 4000 (UI) |
| `bigquery` | BigQuery エミュレータ (`goccy/bigquery-emulator`) | 9050 / 9060 |
| `admin` | Rails 7 管理画面 | 3000 |
| `worker` | Rails イベントワーカー(チェーン → BigQuery) | - |
| `game-a` | ゲームタイトル A モック (Node.js) | 4001 |
| `game-b` | ゲームタイトル B モック (Node.js) | 4002 |

## ドメインモデル

- **Title**: 参加ゲームタイトル
- **Collab**: コラボイベント(開始/終了日時、参加タイトル、デプロイされたコラボ通貨アドレス)
- **Quest**: 各タイトルに紐づくクエスト。達成で `rewardAmount` のコラボ通貨が付与される
- **Reward**: 各タイトルに紐づく報酬。`cost` のコラボ通貨を消費して交換
- **Player**: 各タイトルの内部ユーザを `bytes32` (例: keccak256("title-a:user-123")) でオンチェーン管理

通貨の有効期間 = コラボ期間。コラボ終了後にコントラクト側で残高は使用不可になり、`sweep` で破棄(消滅)されます。

## 起動

```powershell
docker compose up --build
# 初回のみコントラクトをデプロイ
docker compose exec contracts ./deploy.sh
# (Windows ホストで実行ビットが落ちている場合は: docker compose exec contracts bash deploy.sh)
# 管理画面: http://localhost:3000
# Firestore UI: http://localhost:4000
```

詳細な操作は `docs/` 配下と各サービスの README を参照してください。

## テスト

```powershell
# Solidity (Foundry) - 初回は forge-std を自動取得
docker compose exec contracts bash test.sh

# Rails (Minitest) - Firestore / BigQuery / Besu はフェイク
docker compose exec admin bin/rails test
```

## 使用バージョン (2026-05-28 時点、公式レジストリで確認済み)

| コンポーネント | バージョン | 確認元 |
|---|---|---|
| Hyperledger Besu | 26.5.0 | Docker Hub `hyperledger/besu` |
| Ruby | 4.0.5 | `ruby:4.0.5-trixie` |
| Bundler | 4.0.12 | rubygems.org |
| Rails | 8.1.3 | rubygems.org |
| Puma | 8.0.2 | rubygems.org |
| Propshaft | 1.3.2 | rubygems.org |
| google-cloud-firestore | 3.2.0 | rubygems.org |
| google-cloud-bigquery | 1.64.0 | rubygems.org |
| eth (Ruby) | 0.5.17 | rubygems.org |
| faraday | 2.14.2 | rubygems.org |
| concurrent-ruby | 1.3.6 | rubygems.org |
| Node.js | 24.16.0 (Krypton LTS) | nodejs.org/dist |
| Foundry (forge/anvil/cast) | latest (`ghcr.io/foundry-rs/foundry:latest`) | ghcr.io |
| Express | 5.2.1 | npmjs.com |
| Solidity | 0.8.28 | pragma |

> JS 依存を最小化するため、コントラクト周りは Foundry (Rust 製、JS 不要) を採用しています。デプロイは `contracts/deploy.sh` から `forge create` + `forge inspect` で完結します。Node.js は `game-mock` (タイトル疑似 API) のみで使用しています。

