# in-memory な ChainClient スタブ。Solidity 側のロジックを最低限再現する。
# 本物の ChainClient とインタフェース互換。
class FakeChainClient
  attr_reader :calls

  def initialize
    @calls   = []
    @collabs = {}                       # collab_id => { start_at, end_at, swept, titles: Set, balances: Hash }
    @tx_seq  = 0
  end

  def manager_address; "0xManager"; end
  def manager;          :fake;       end
  def client;           :fake;       end
  def key;              :fake;       end

  def id_to_bytes32(s); "0x#{s}"; end
  def player_bytes32(t, p); "0xp:#{t}:#{p}"; end

  def create_collab(collab_id:, name:, symbol:, start_at:, end_at:)
    raise "exists" if @collabs.key?(collab_id)
    raise "bad period" unless end_at.to_i > start_at.to_i
    @collabs[collab_id] = {
      name: name, symbol: symbol,
      start_at: start_at.to_i, end_at: end_at.to_i,
      swept: false, titles: [], balances: Hash.new(0)
    }
    _tx(:create_collab, collab_id)
  end

  def set_title_enabled(collab_id:, title_id:, enabled: true)
    c = _require(collab_id)
    if enabled then c[:titles] |= [title_id] else c[:titles] -= [title_id] end
    _tx(:set_title_enabled, collab_id, title_id, enabled)
  end

  def mint_for_quest(collab_id:, title_id:, player_id:, quest_id:, amount:)
    c = _active(collab_id)
    raise "title disabled" unless c[:titles].include?(title_id)
    c[:balances][player_id] += amount.to_i
    _tx(:mint, collab_id, title_id, player_id, quest_id, amount)
  end

  def redeem_reward(collab_id:, title_id:, player_id:, reward_id:, cost:)
    c = _active(collab_id)
    raise "title disabled" unless c[:titles].include?(title_id)
    raise "insufficient" if c[:balances][player_id] < cost.to_i
    c[:balances][player_id] -= cost.to_i
    _tx(:burn, collab_id, title_id, player_id, reward_id, cost)
  end

  def balance_of(collab_id:, title_id:, player_id:)
    c = @collabs[collab_id] or return 0
    return 0 if c[:swept]
    now = (Time.respond_to?(:current) ? Time.current : Time.now).to_i
    return 0 if now < c[:start_at] || now >= c[:end_at]
    c[:balances][player_id]
  end

  def sweep_collab(collab_id:)
    c = _require(collab_id)
    now = (Time.respond_to?(:current) ? Time.current : Time.now).to_i
    raise "still active" if now < c[:end_at]
    raise "already swept" if c[:swept]
    c[:swept] = true
    c[:balances].clear
    _tx(:sweep, collab_id)
  end

  private

  def _require(id);  @collabs[id] or raise "no collab"; end
  def _active(id)
    c = _require(id)
    now = (Time.respond_to?(:current) ? Time.current : Time.now).to_i
    raise "not started" if now < c[:start_at]
    raise "expired"     if now >= c[:end_at]
    c
  end

  def _tx(kind, *args)
    @tx_seq += 1
    @calls << [kind, *args]
    { "transactionHash" => "0xtx#{@tx_seq}", "blockNumber" => @tx_seq }
  end
end

