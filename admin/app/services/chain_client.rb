# Besu と通信し CollabManager を操作する薄いラッパ
require "eth"
require "digest"

class ChainClient
  GAS_LIMIT = 3_000_000

  def initialize
    @client = Eth::Client.create(ENV.fetch("BESU_RPC_URL", "http://besu:8545"))
    @key    = Eth::Key.new(priv: ENV.fetch("DEPLOYER_PRIVATE_KEY"))
    # eth gem 0.5.x では setter 形式の gas_limit= が廃止されている。
    # 必要なら Eth::Tx.estimate_intrinsic_gas や呼び出し側で gas_limit: を指定する。
    @manager_address = CHAIN_CONFIG["collabManager"]
    @manager = Eth::Contract.from_abi(
      name: "CollabManager", address: @manager_address, abi: MANAGER_ABI
    ) if @manager_address && MANAGER_ABI.any?
  end

  attr_reader :client, :key, :manager, :manager_address

  # 文字列ID -> bytes32 (keccak256)
  def id_to_bytes32(str)
    "0x" + Digest::SHA3.hexdigest(str.to_s, 256)
  rescue
    # SHA3 が無い環境用フォールバック: Eth::Util.keccak256
    "0x" + Eth::Util.bin_to_hex(Eth::Util.keccak256(str.to_s))
  end

  def player_bytes32(title_id, player_id)
    id_to_bytes32("#{title_id}:#{player_id}")
  end

  def create_collab(collab_id:, name:, symbol:, start_at:, end_at:)
    tx = client.transact_and_wait(
      manager, "createCollab",
      id_to_bytes32(collab_id), name, symbol,
      start_at.to_i, end_at.to_i,
      sender_key: key
    )
    tx
  end

  def set_title_enabled(collab_id:, title_id:, enabled: true)
    client.transact_and_wait(
      manager, "setTitleEnabled",
      id_to_bytes32(collab_id), id_to_bytes32(title_id), enabled,
      sender_key: key
    )
  end

  def mint_for_quest(collab_id:, title_id:, player_id:, quest_id:, amount:)
    client.transact_and_wait(
      manager, "mintForQuest",
      id_to_bytes32(collab_id),
      id_to_bytes32(title_id),
      player_bytes32(title_id, player_id),
      id_to_bytes32(quest_id),
      amount.to_i,
      sender_key: key
    )
  end

  def redeem_reward(collab_id:, title_id:, player_id:, reward_id:, cost:)
    client.transact_and_wait(
      manager, "redeemReward",
      id_to_bytes32(collab_id),
      id_to_bytes32(title_id),
      player_bytes32(title_id, player_id),
      id_to_bytes32(reward_id),
      cost.to_i,
      sender_key: key
    )
  end

  def balance_of(collab_id:, title_id:, player_id:)
    client.call(manager, "balanceOf",
                id_to_bytes32(collab_id),
                player_bytes32(title_id, player_id))
  end

  def sweep_collab(collab_id:)
    client.transact_and_wait(manager, "sweepCollab",
                             id_to_bytes32(collab_id), sender_key: key)
  end
end

