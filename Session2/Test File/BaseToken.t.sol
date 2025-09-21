// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BaseToken.sol";

contract BaseTokenTest is Test {
    BaseToken token;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token = new BaseToken(1_000_000 * 10 ** 18);
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 1_000_000 * 10 ** 18);
        assertEq(token.balanceOf(admin), 1_000_000 * 10 ** 18);
    }

    function testMintByMinter() public {
        token.grantRole(token.MINTER_ROLE(), admin);

        token.mint(user1, 1000);
        assertEq(token.balanceOf(user1), 1000);
    }

    function testMintNotMinterFails() public {
        vm.prank(user1);
        vm.expectRevert("AccessControl: account");
        token.mint(user1, 1000);
    }

    function testPauseAndUnpause() public {
        token.grantRole(token.PAUSER_ROLE(), admin);

        token.pause();
        vm.expectRevert("Pausable: paused");
        token.transfer(user1, 100);

        token.unpause();
        token.transfer(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }

    function testBlacklist() public {
        token.setBlacklist(user1, true);

        // Uji coba klaim reward oleh pengguna yang masuk daftar hitam
        vm.prank(user1);
        vm.expectRevert("Blacklisted");
        token.claimReward();

        // Uji coba transfer oleh pengguna yang masuk daftar hitam
        // Menguji transfer dari user1 ke user2
        vm.prank(user1);
        vm.expectRevert("Blacklisted");
        token.transfer(user2, 100);
    }

    function testClaimReward() public {
        uint256 initialBalance = token.balanceOf(user1);

        vm.prank(user1);
        token.claimReward();

        uint256 afterClaim = token.balanceOf(user1);
        assertEq(afterClaim, initialBalance + 10 * 10 ** 18);

        // Klaim lagi sebelum 24 jam gagal
        vm.prank(user1);
        vm.expectRevert("Wait 24h");
        token.claimReward();
    }
}
