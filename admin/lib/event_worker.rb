# Besu から CollabManager のイベントをポーリングし BigQuery に流す常駐プロセス
# `bin/rails runner lib/event_worker.rb` で起動。
require "eth"

LAST_BLOCK_FILE = "/shared/.last_processed_block"

def last_processed
  return 0 unless File.exist?(LAST_BLOCK_FILE)
  File.read(LAST_BLOCK_FILE).to_i
end
def save_last(n); File.write(LAST_BLOCK_FILE, n.to_s); end

chain = ChainClient.new
unless chain.manager_address
  warn "[worker] deployment.json not ready, waiting..."
  loop do
    sleep 5
    break if File.exist?(DEPLOYMENT_PATH)
  end
  load Rails.root.join("config/initializers/chain.rb")
  chain = ChainClient.new
end

dataset = BIGQUERY.dataset(ENV.fetch("BIGQUERY_DATASET", "chaincross"))
table   = dataset.table("tx_logs")

# topic0 を計算
def topic(sig); "0x" + Eth::Util.bin_to_hex(Eth::Util.keccak256(sig)); end

EVENTS = {
  topic("QuestCleared(bytes32,bytes32,bytes32,bytes32,uint256)") => :quest_cleared,
  topic("RewardRedeemed(bytes32,bytes32,bytes32,bytes32,uint256)") => :reward_redeemed,
  topic("CollabCreated(bytes32,address,uint64,uint64)") => :collab_created,
  topic("CollabSwept(bytes32)") => :collab_swept,
}

puts "[worker] starting. manager=#{chain.manager_address}"

loop do
  begin
    head = chain.client.eth_block_number["result"].to_i(16)
    from = last_processed + 1
    if from <= head
      logs = chain.client.eth_get_logs([{
        fromBlock: "0x#{from.to_s(16)}",
        toBlock:   "0x#{head.to_s(16)}",
        address:   chain.manager_address
      }])["result"] || []

      rows = []
      logs.each do |log|
        t0 = log["topics"][0]
        kind = EVENTS[t0]
        next unless kind
        topics = log["topics"]
        data   = log["data"].to_s.sub(/\A0x/, "")
        # data は 32 byte ワードの連結
        words  = data.scan(/.{64}/)

        row = {
          "event_type"   => kind.to_s,
          "tx_hash"      => log["transactionHash"],
          "block_number" => log["blockNumber"].to_i(16),
          "occurred_at"  => Time.now.utc.iso8601
        }
        case kind
        when :quest_cleared
          row.merge!(
            "collab_id" => topics[1], "title_id" => topics[2], "player_id" => topics[3],
            "quest_id"  => "0x" + (words[0] || ""), "amount" => (words[1] || "0").to_i(16)
          )
        when :reward_redeemed
          row.merge!(
            "collab_id" => topics[1], "title_id" => topics[2], "player_id" => topics[3],
            "reward_id" => "0x" + (words[0] || ""), "amount" => (words[1] || "0").to_i(16)
          )
        when :collab_created
          row["collab_id"] = topics[1]
        when :collab_swept
          row["collab_id"] = topics[1]
        end
        rows << row
      end

      if rows.any?
        table.insert(rows)
        puts "[worker] inserted #{rows.size} rows (blocks #{from}..#{head})"
      end
      save_last(head)
    end
  rescue => e
    warn "[worker] error: #{e.class}: #{e.message}"
  end
  sleep 3
end

