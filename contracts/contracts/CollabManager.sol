// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CollabCurrency.sol";

/**
 * @title CollabManager
 * @notice 複数のコラボイベント・複数タイトルを一元管理。
 *         - 管理者(admin / 運営)がコラボを作成し CollabCurrency をデプロイ
 *         - タイトル別の権限を付与
 *         - クエスト達成: タイトルが mintForQuest を呼ぶ -> 通貨付与
 *         - 報酬交換  : タイトルが redeemReward を呼ぶ -> 通貨消費
 */
contract CollabManager {
    address public admin;

    struct Collab {
        bytes32         collabId;
        CollabCurrency  currency;
        uint64          startAt;
        uint64          endAt;
        bool            exists;
    }

    // collabId => Collab
    mapping(bytes32 => Collab) public collabs;
    // collabId => titleId => 権限フラグ
    mapping(bytes32 => mapping(bytes32 => bool)) public titleEnabled;

    event CollabCreated(bytes32 indexed collabId, address currency, uint64 startAt, uint64 endAt);
    event TitleEnabled(bytes32 indexed collabId, bytes32 indexed titleId, bool enabled);
    event QuestCleared(
        bytes32 indexed collabId,
        bytes32 indexed titleId,
        bytes32 indexed player,
        bytes32 questId,
        uint256 amount
    );
    event RewardRedeemed(
        bytes32 indexed collabId,
        bytes32 indexed titleId,
        bytes32 indexed player,
        bytes32 rewardId,
        uint256 cost
    );
    event CollabSwept(bytes32 indexed collabId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "zero");
        admin = newAdmin;
    }

    function createCollab(
        bytes32 collabId,
        string calldata name,
        string calldata symbol,
        uint64 startAt,
        uint64 endAt
    ) external onlyAdmin returns (address currency) {
        require(!collabs[collabId].exists, "exists");
        CollabCurrency c = new CollabCurrency(name, symbol, startAt, endAt, address(this));
        collabs[collabId] = Collab({
            collabId: collabId,
            currency: c,
            startAt:  startAt,
            endAt:    endAt,
            exists:   true
        });
        emit CollabCreated(collabId, address(c), startAt, endAt);
        return address(c);
    }

    function setTitleEnabled(bytes32 collabId, bytes32 titleId, bool enabled)
        external onlyAdmin
    {
        require(collabs[collabId].exists, "no collab");
        titleEnabled[collabId][titleId] = enabled;
        emit TitleEnabled(collabId, titleId, enabled);
    }

    /// @dev 本来はタイトル毎のアドレスを onlyTitle で確認すべきだが、
    ///      ローカルエミュレーション簡素化のため admin (運営バックエンド) が代理発行する。
    function mintForQuest(
        bytes32 collabId,
        bytes32 titleId,
        bytes32 player,
        bytes32 questId,
        uint256 amount
    ) external onlyAdmin {
        Collab memory col = collabs[collabId];
        require(col.exists, "no collab");
        require(titleEnabled[collabId][titleId], "title disabled");
        col.currency.mint(player, amount, questId);
        emit QuestCleared(collabId, titleId, player, questId, amount);
    }

    function redeemReward(
        bytes32 collabId,
        bytes32 titleId,
        bytes32 player,
        bytes32 rewardId,
        uint256 cost
    ) external onlyAdmin {
        Collab memory col = collabs[collabId];
        require(col.exists, "no collab");
        require(titleEnabled[collabId][titleId], "title disabled");
        col.currency.burn(player, cost, rewardId);
        emit RewardRedeemed(collabId, titleId, player, rewardId, cost);
    }

    /// @notice コラボ期間終了後に呼ぶと残通貨は消滅扱い
    function sweepCollab(bytes32 collabId) external onlyAdmin {
        Collab memory col = collabs[collabId];
        require(col.exists, "no collab");
        col.currency.sweep();
        emit CollabSwept(collabId);
    }

    function balanceOf(bytes32 collabId, bytes32 player) external view returns (uint256) {
        Collab memory col = collabs[collabId];
        if (!col.exists) return 0;
        return col.currency.effectiveBalanceOf(player);
    }
}

