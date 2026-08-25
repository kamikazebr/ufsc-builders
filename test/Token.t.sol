// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    uint256 constant CAP = 1_000_000 ether;

    function setUp() public {
        token = new Token("UFSC Token", "UFSC", CAP, alice);
    }

    function test_OwnerHoldsHalfTheCap() public view {
        assertEq(token.balanceOf(alice), CAP / 2);
    }

    function test_CannotSendWhatYouDoNotHave() public {
        vm.prank(bob);
        vm.expectRevert();
        token.transfer(alice, 1 ether);
    }

    function test_OnlyOwnerMints() public {
        vm.prank(bob);
        vm.expectRevert();
        token.mint(bob, 1 ether);
    }

    function test_CapIsEnforced() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Token.CapExceeded.selector, CAP, CAP / 2)
        );
        token.mint(alice, CAP);
    }

    /// A property, not an example. Foundry runs this with hundreds of generated
    /// inputs and tries to break it. A transfer MOVES value; it never creates it.
    function testFuzz_TransferPreservesSupply(uint256 amount) public {
        amount = bound(amount, 0, token.balanceOf(alice));
        uint256 supplyBefore = token.totalSupply();

        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.totalSupply(), supplyBefore);
        assertEq(token.balanceOf(alice) + token.balanceOf(bob), supplyBefore);
    }
}
