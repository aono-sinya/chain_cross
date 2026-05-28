#!/usr/bin/env bash
# Foundry テスト実行スクリプト。forge-std が無ければ取得する。
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d lib/forge-std ]; then
  echo "==> installing forge-std"
  if [ ! -d .git ]; then
    git init -q .
    git config user.email ci@local
    git config user.name ci
  fi
  forge install foundry-rs/forge-std
fi

echo "==> forge test"
exec forge test -vvv "$@"

