#!/usr/bin/env bash
# Foundry でコントラクトをコンパイル & デプロイし、ABI と deployment.json を /shared に書き出す。
# 使い方: docker compose run --rm contracts ./deploy.sh
set -euo pipefail

: "${BESU_RPC_URL:?BESU_RPC_URL is required}"
: "${DEPLOYER_PRIVATE_KEY:?DEPLOYER_PRIVATE_KEY is required}"

cd "$(dirname "$0")"

echo "==> forge build"
forge build

echo "==> deploying CollabManager"
DEPLOY_JSON=$(forge create contracts/CollabManager.sol:CollabManager \
  --rpc-url "$BESU_RPC_URL" \
  --private-key "$DEPLOYER_PRIVATE_KEY" \
  --broadcast \
  --json)

echo "$DEPLOY_JSON"

MANAGER_ADDR=$(echo "$DEPLOY_JSON" | jq -r '.deployedTo')
DEPLOYER_ADDR=$(echo "$DEPLOY_JSON" | jq -r '.deployer')
TX_HASH=$(echo "$DEPLOY_JSON" | jq -r '.transactionHash')

if [ -z "$MANAGER_ADDR" ] || [ "$MANAGER_ADDR" = "null" ]; then
  echo "Deployment failed: cannot parse deployedTo" >&2
  exit 1
fi

mkdir -p /shared

echo "==> writing ABIs to /shared"
forge inspect contracts/CollabManager.sol:CollabManager  abi > /shared/CollabManager.abi.json
forge inspect contracts/CollabCurrency.sol:CollabCurrency abi > /shared/CollabCurrency.abi.json

echo "==> writing deployment.json"
cat > /shared/deployment.json <<EOF
{
  "chainId": ${CHAIN_ID:-2018},
  "collabManager": "${MANAGER_ADDR}",
  "deployer": "${DEPLOYER_ADDR}",
  "deployTx": "${TX_HASH}"
}
EOF

echo "==> done. CollabManager = ${MANAGER_ADDR}"

