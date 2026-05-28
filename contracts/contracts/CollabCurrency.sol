// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title CollabCurrency
 * @notice 単一のコラボイベント専用のスコープ付き通貨。
 *         有効期間はコラボ期間と同一。期間外の mint/transfer はリバート。
 *         期間後は `sweep` で残高を 0 にして「消滅」させる。
 *         プレイヤー識別子は bytes32 (例: keccak256("title-a:userId"))。
 *         ミント/バーンは CollabManager (owner) のみが実行可能。
 */
contract CollabCurrency {
    string  public name;
    string  public symbol;
    uint8   public constant decimals = 0;       // ゲーム用ポイント想定なので整数
    uint256 public totalSupply;

    address public immutable owner;             // CollabManager
    uint64  public immutable startAt;           // unix sec
    uint64  public immutable endAt;             // unix sec (この時刻以降は無効)

    bool    public swept;                       // 期間後に sweep 済みか

    mapping(bytes32 => uint256) public balanceOf;

    event Minted(bytes32 indexed player, uint256 amount, bytes32 indexed reason);
    event Burned(bytes32 indexed player, uint256 amount, bytes32 indexed reason);
    event Swept(uint256 totalBurned);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier whileActive() {
        require(block.timestamp >= startAt, "not started");
        require(block.timestamp <  endAt,   "expired");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint64 _startAt,
        uint64 _endAt,
        address _owner
    ) {
        require(_endAt > _startAt, "bad period");
        name = _name;
        symbol = _symbol;
        startAt = _startAt;
        endAt = _endAt;
        owner = _owner;
    }

    function mint(bytes32 player, uint256 amount, bytes32 reason)
        external onlyOwner whileActive
    {
        balanceOf[player] += amount;
        totalSupply += amount;
        emit Minted(player, amount, reason);
    }

    function burn(bytes32 player, uint256 amount, bytes32 reason)
        external onlyOwner whileActive
    {
        uint256 b = balanceOf[player];
        require(b >= amount, "insufficient");
        unchecked {
            balanceOf[player] = b - amount;
            totalSupply -= amount;
        }
        emit Burned(player, amount, reason);
    }

    /**
     * @notice コラボ期間終了後に呼び出して残量を消滅させる。
     *         実残高の個別消去はガス的に非現実的なため totalSupply のみ 0 に。
     *         以降の参照系コード側で `swept` を見て残高を 0 扱いにする。
     */
    function sweep() external onlyOwner {
        require(block.timestamp >= endAt, "still active");
        require(!swept, "already swept");
        swept = true;
        uint256 burned = totalSupply;
        totalSupply = 0;
        emit Swept(burned);
    }

    /// @notice 期間外 / sweep 後はゼロ扱い
    function effectiveBalanceOf(bytes32 player) external view returns (uint256) {
        if (swept || block.timestamp >= endAt) return 0;
        if (block.timestamp <  startAt)        return 0;
        return balanceOf[player];
    }
}

