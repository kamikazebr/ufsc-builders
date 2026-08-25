// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/UFSCBuilders.sol";

contract UFSCBuildersTest is Test {
    UFSCBuilders board;
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");
    address tokenA = makeAddr("tokenA");
    address tokenB = makeAddr("tokenB");

    function setUp() public {
        board = new UFSCBuilders();
    }

    function test_FirstRegistrationAppends() public {
        vm.prank(alice);
        board.register("time chupacabra", tokenA);

        assertEq(board.count(), 1);
        assertEq(board.indexOf(alice), 1); // 1-based, remember
        assertEq(board.entryAt(0).who, alice);
    }

    function test_SecondRegistrationOverwrites() public {
        vm.startPrank(alice);
        board.register("first name", tokenA);
        board.register("second name", tokenB);
        vm.stopPrank();

        assertEq(board.count(), 1, "should update, not append");
        assertEq(board.entryAt(0).token, tokenB);
    }

    function test_SetBadgeUpdatesOnlyThatField() public {
        vm.startPrank(alice);
        board.register("time chupacabra", tokenA);
        board.setBadge(address(0xBADBADBAD));
        vm.stopPrank();

        UFSCBuilders.Entry memory e = board.entryAt(0);
        assertEq(e.badge, address(0xBADBADBAD));
        assertEq(e.token, tokenA, "token must survive");
        assertEq(e.name, "time chupacabra", "name must survive");
    }

    function test_SetBadgeBeforeRegisterReverts() public {
        vm.prank(bob);
        vm.expectRevert(UFSCBuilders.NotRegistered.selector);
        board.setBadge(address(0xBADBADBAD));
    }

    function test_EmptyNameReverts() public {
        vm.prank(alice);
        vm.expectRevert(UFSCBuilders.NameEmpty.selector);
        board.register("", tokenA);
    }

    function test_EmitsRegistered() public {
        vm.expectEmit(true, false, false, true);
        emit UFSCBuilders.Registered(alice, "time chupacabra", tokenA);

        vm.prank(alice);
        board.register("time chupacabra", tokenA);
    }

    /// Two different people never collide, whatever they call themselves.
    function testFuzz_DistinctSendersGetDistinctRows(string calldata a, string calldata b) public {
        vm.assume(bytes(a).length > 0 && bytes(a).length <= 32);
        vm.assume(bytes(b).length > 0 && bytes(b).length <= 32);

        vm.prank(alice); board.register(a, tokenA);
        vm.prank(bob);   board.register(b, tokenB);

        assertEq(board.count(), 2);
        assertTrue(board.indexOf(alice) != board.indexOf(bob));
    }
}
