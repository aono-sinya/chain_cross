# Besu / コントラクトデプロイ情報をロード
require "json"

DEPLOYMENT_PATH = "/shared/deployment.json"

CHAIN_CONFIG = if File.exist?(DEPLOYMENT_PATH)
  JSON.parse(File.read(DEPLOYMENT_PATH))
else
  Rails.logger.warn("[chain] deployment.json not found yet. Run contracts deploy script.")
  {}
end

MANAGER_ABI  = File.exist?("/shared/CollabManager.abi.json")  ? JSON.parse(File.read("/shared/CollabManager.abi.json"))  : []
CURRENCY_ABI = File.exist?("/shared/CollabCurrency.abi.json") ? JSON.parse(File.read("/shared/CollabCurrency.abi.json")) : []

