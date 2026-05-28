// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {CollabManager}  from "../contracts/CollabManager.sol";
import {CollabCurrency} from "../contracts/CollabCurrency.sol";

contract CollabManagerTest is Test {
    CollabManager mgr;

    bytes32 constant COLLAB = keccak256("collab-001");
    bytes32 constant TITLE_A = keccak256("title-a");
    bytes32 constant TITLE_B = keccak256("title-b");
    bytes32 constant PLAYER  = keccak256("title-a:user-1");
    bytes32 constant QUEST   = keccak256("quest-1");
    bytes32 constant REWARD  = keccak256("reward-1");

    address admin = address(this);
    address notAdmin = address(0xBEEF);

    uint64 startAt;
    uint64 endAt;

    function setUp() public {
        mgr = new CollabManager();
        startAt = uint64(block.timestamp + 10);
        endAt   = uint64(block.timestamp + 1000);
    }

    // -------------------- createCollab --------------------

    function test_CreateCollab_OnlyAdmin() public {
        vm.prank(notAdmin);
        vm.expectRevert(bytes("not admin"));
        mgr.createCollab(COLLAB, "Collab", "CLB", startAt, endAt);
    }

    function test_CreateCollab_Succeeds_AndDeploysCurrency() public {
        address cur = mgr.createCollab(COLLAB, "Collab", "CLB", startAt, endAt);
        assertTrue(cur != address(0));

        (bytes32 id, CollabCurrency c, uint64 s, uint64 e, bool exists) = mgr.collabs(COLLAB);
        assertEq(id, COLLAB);
        assertEq(address(c), cur);
        assertEq(s, startAt);
        assertEq(e, endAt);
        assertTrue(exists);
    }

    function test_CreateCollab_RejectsDuplicate() public {
        mgr.createCollab(COLLAB, "Collab", "CLB", startAt, endAt);
        vm.expectRevert(bytes("exists"));
        mgr.createCollab(COLLAB, "Collab", "CLB", startAt, endAt);
    }

    function test_CreateCollab_RejectsBadPeriod() public {
        vm.expectRevert(bytes("bad period"));
        mgr.createCollab(COLLAB, "x", "x", endAt, startAt);
    }

    // -------------------- title enable --------------------

    function test_SetTitleEnabled_RequiresCollab() public {
        vm.expectRevert(bytes("no collab"));
        mgr.setTitleEnabled(COLLAB, TITLE_A, true);
    }

    function test_SetTitleEnabled_OnlyAdmin() public {
        mgr.createCollab(COLLAB, "c", "c", startAt, endAt);
        vm.prank(notAdmin);
        vm.expectRevert(bytes("not admin"));
        mgr.setTitleEnabled(COLLAB, TITLE_A, true);
    }

    // -------------------- mintForQuest --------------------

    function _activeCollabWithTitleA() internal {
        mgr.createCollab(COLLAB, "c", "c", startAt, endAt);
        mgr.setTitleEnabled(COLLAB, TITLE_A, true);
        vm.warp(startAt + 1);
    }

    function test_MintForQuest_BeforeStart_Reverts() public {
        mgr.createCollab(COLLAB, "c", "c", startAt, endAt);
        mgr.setTitleEnabled(COLLAB, TITLE_A, true);
        // 期間前 (warp していない)
        vm.expectRevert(bytes("not started"));
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
    }

    function test_MintForQuest_TitleNotEnabled_Reverts() public {
        mgr.createCollab(COLLAB, "c", "c", startAt, endAt);
        vm.warp(startAt + 1);
        vm.expectRevert(bytes("title disabled"));
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
    }

    function test_MintForQuest_Succeeds_AndUpdatesBalance() public {
        _activeCollabWithTitleA();
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
        assertEq(mgr.balanceOf(COLLAB, PLAYER), 100);
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 50);
        assertEq(mgr.balanceOf(COLLAB, PLAYER), 150);
    }

    function test_MintForQuest_AfterEnd_Reverts() public {
        _activeCollabWithTitleA();
        vm.warp(endAt);
        vm.expectRevert(bytes("expired"));
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
    }

    // -------------------- redeemReward --------------------

    function test_RedeemReward_InsufficientBalance_Reverts() public {
        _activeCollabWithTitleA();
        vm.expectRevert(bytes("insufficient"));
        mgr.redeemReward(COLLAB, TITLE_A, PLAYER, REWARD, 1);
    }

    function test_RedeemReward_Succeeds() public {
        _activeCollabWithTitleA();
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
        mgr.redeemReward(COLLAB, TITLE_A, PLAYER, REWARD, 30);
        assertEq(mgr.balanceOf(COLLAB, PLAYER), 70);
    }

    function test_RedeemReward_TitleNotEnabled_Reverts() public {
        _activeCollabWithTitleA();
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
        vm.expectRevert(bytes("title disabled"));
        mgr.redeemReward(COLLAB, TITLE_B, PLAYER, REWARD, 10);
    }

    function test_RedeemReward_AfterEnd_Reverts() public {
        _activeCollabWithTitleA();
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
        vm.warp(endAt + 1);
        vm.expectRevert(bytes("expired"));
        mgr.redeemReward(COLLAB, TITLE_A, PLAYER, REWARD, 10);
    }

    // -------------------- sweep / expiry --------------------

    function test_BalanceOf_AfterEnd_IsZero() public {
        _activeCollabWithTitleA();
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);
        vm.warp(endAt);
        assertEq(mgr.balanceOf(COLLAB, PLAYER), 0);
    }

    function test_BalanceOf_BeforeStart_IsZero() public {
        mgr.createCollab(COLLAB, "c", "c", startAt, endAt);
        mgr.setTitleEnabled(COLLAB, TITLE_A, true);
        // warp していない (期間前)
        assertEq(mgr.balanceOf(COLLAB, PLAYER), 0);
    }

    function test_Sweep_RevertsBeforeEnd() public {
        _activeCollabWithTitleA();
        (, CollabCurrency c, , , ) = mgr.collabs(COLLAB);
        vm.expectRevert(bytes("still active"));
        mgr.sweepCollab(COLLAB);
        assertFalse(c.swept());
    }

    function test_Sweep_AfterEnd_Succeeds_AndZerosBalance() public {
        _activeCollabWithTitleA();
        mgr.mintForQuest(COLLAB, TITLE_A, PLAYER, QUEST, 100);

        (, CollabCurrency c, , , ) = mgr.collabs(COLLAB);
        assertEq(c.totalSupply(), 100);

        vm.warp(endAt + 1);
        mgr.sweepCollab(COLLAB);

        assertTrue(c.swept());
        assertEq(c.totalSupply(), 0);
        assertEq(mgr.balanceOf(COLLAB, PLAYER), 0);
        // 個別残高自体は内部的に残るが effectiveBalanceOf が 0 を返すことを保証
        assertEq(c.effectiveBalanceOf(PLAYER), 0);
    }

    function test_Sweep_Twice_Reverts() public {
        _activeCollabWithTitleA();
        vm.warp(endAt + 1);
        mgr.sweepCollab(COLLAB);
        vm.expectRevert(bytes("already swept"));
        mgr.sweepCollab(COLLAB);
    }

    // -------------------- admin transfer --------------------

    function test_TransferAdmin_OnlyAdmin() public {
        vm.prank(notAdmin);
        vm.expectRevert(bytes("not admin"));
        mgr.transferAdmin(notAdmin);
    }

    function test_TransferAdmin_Succeeds() public {
        mgr.transferAdmin(notAdmin);
        assertEq(mgr.admin(), notAdmin);
        // 旧 admin はもう createCollab できない
        vm.expectRevert(bytes("not admin"));
        mgr.createCollab(COLLAB, "x", "x", startAt, endAt);
    }
}

contract CollabCurrencyDirectTest is Test {
    CollabCurrency cur;
    bytes32 constant PLAYER = keccak256("p");
    bytes32 constant REASON = keccak256("r");

    function setUp() public {
        // owner = address(this) として直接デプロイ
        uint64 s = uint64(block.timestamp);
        uint64 e = uint64(block.timestamp + 100);
        cur = new CollabCurrency("X", "X", s, e, address(this));
    }

    function test_Mint_OnlyOwner() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(bytes("not owner"));
        cur.mint(PLAYER, 10, REASON);
    }

    function test_Burn_InsufficientReverts() public {
        vm.expectRevert(bytes("insufficient"));
        cur.burn(PLAYER, 1, REASON);
    }

    function test_MintBurn_UpdatesTotalSupply() public {
        cur.mint(PLAYER, 100, REASON);
        assertEq(cur.totalSupply(), 100);
        cur.burn(PLAYER, 40, REASON);
        assertEq(cur.totalSupply(), 60);
        assertEq(cur.balanceOf(PLAYER), 60);
    }
}

