// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BaseBadge.sol";

contract BaseBadgeTest is Test {
    BaseBadge badge;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        badge = new BaseBadge();

        badge.grantRole(badge.MINTER_ROLE(), admin);
    }

    function testCreateBadgeType() public {
        uint256 tokenId = badge.createBadgeType("Solidity Master", "achievement", 100, false, "ipfs://badge1");
        assertTrue(tokenId >= badge.ACHIEVEMENT_BASE());
    }

    function testIssueBadge() public {
        uint256 tokenId = badge.createBadgeType("Solidity Master", "achievement", 100, true, "ipfs://badge1");
        badge.issueBadge(user1, tokenId);

        uint256 balance = badge.balanceOf(user1, tokenId);
        assertEq(balance, 1);

        (bool valid, ) = badge.verifyBadge(user1, tokenId);
        assertTrue(valid);
    }

    function testBatchIssueBadges() public {
        uint256 tokenId = badge.createBadgeType("Event Participant", "event", 1000, true, "ipfs://badge2");

        // Perbaikan: Deklarasikan dan inisialisasi array 'recipients' sebelum digunakan.
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        badge.batchIssueBadges(recipients, tokenId, 2);

        assertEq(badge.balanceOf(user1, tokenId), 2);
        assertEq(badge.balanceOf(user2, tokenId), 2);
    }

    function testTransferNonTransferableFails() public {
        uint256 tokenId = badge.createBadgeType("NonTransfer Badge", "achievement", 100, false, "ipfs://badge3");
        badge.issueBadge(user1, tokenId);

        vm.prank(user1);
        vm.expectRevert("This token is non-transferable");
        badge.safeTransferFrom(user1, user2, tokenId, 1, "");
    }

    function testPauseAndUnpause() public {
        badge.grantRole(badge.PAUSER_ROLE(), admin);

        badge.pause();
        vm.expectRevert("Token transfer while paused");
        badge.issueBadge(user1, badge.createBadgeType("Paused Badge", "certificate", 10, true, "ipfs://badge4"));

        badge.unpause();
        uint256 tokenId = badge.createBadgeType("Active Badge", "certificate", 10, true, "ipfs://badge5");
        badge.issueBadge(user1, tokenId);

        assertEq(badge.balanceOf(user1, tokenId), 1);
    }
}
