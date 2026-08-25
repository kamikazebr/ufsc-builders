// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Disperse.sol";

/// A recipient that is a contract gets `receive()` called mid-loop — while the
/// money for everybody after it is still sitting in Disperse. The first version
/// of `_refund` read `address(this).balance`, so re-entering with an empty list
/// fell straight through the loop into a refund of *everything*, payable to
/// whoever was calling: the attacker.
contract Thief {
    Disperse immutable d;
    bool struck;

    constructor(Disperse d_) { d = d_; }

    receive() external payable {
        if (struck) return;
        struck = true;
        // Empty list: the loop does nothing. All that runs is the refund.
        d.dropEqual{value: 0}(new address[](0), 0);
    }
}

contract DisperseReentrancyTest is Test {
    Disperse d;

    function setUp() public {
        d = new Disperse();
    }

    /// The whole point of the fix: the refund is bounded by *this* call's
    /// arithmetic, not by whatever happens to be in the contract right now.
    function test_RecipientCannotDrainTheRest() public {
        Thief thief = new Thief(d);
        address alice = makeAddr("alice");
        address bob   = makeAddr("bob");

        address[] memory to = new address[](3);
        to[0] = address(thief);   // paid first, re-enters while the rest is still here
        to[1] = alice;
        to[2] = bob;

        address payer = makeAddr("payer");
        vm.deal(payer, 10 ether);

        vm.prank(payer);
        d.dropEqual{value: 1 ether}(to, 0.01 ether);

        // Everyone on the list got exactly what they were promised.
        assertEq(address(thief).balance, 0.01 ether, "thief took more than its share");
        assertEq(alice.balance,          0.01 ether, "alice was shorted");
        assertEq(bob.balance,            0.01 ether, "bob was shorted");

        // And the overpay went back to the payer, not to the thief.
        assertEq(payer.balance, 10 ether - 0.03 ether, "payer did not get the change");
        assertEq(address(d).balance, 0, "money stranded in Disperse");
    }

    /// Last in the list is the dangerous position: the loop is finished, so
    /// nothing after the re-entry can fail, and the theft goes through silently
    /// on a transaction that reports success.
    function test_LastRecipientCannotPocketTheChange() public {
        Thief thief = new Thief(d);
        address alice = makeAddr("alice");

        address[] memory to = new address[](2);
        to[0] = alice;
        to[1] = address(thief);   // paid last — the loop cannot revert after this

        address payer = makeAddr("payer");
        vm.deal(payer, 10 ether);

        vm.prank(payer);
        d.dropEqual{value: 1 ether}(to, 0.01 ether);

        assertEq(address(thief).balance, 0.01 ether, "thief kept the change");
        assertEq(payer.balance, 10 ether - 0.02 ether, "payer did not get the change");
    }

    /// You cannot spend the contract's balance by calling with no value.
    function test_CannotSpendWhatYouDidNotSend() public {
        address[] memory to = new address[](1);
        to[0] = makeAddr("someone");

        vm.expectRevert(
            abi.encodeWithSelector(Disperse.Underfunded.selector, 0, 1 ether)
        );
        d.dropEqual{value: 0}(to, 1 ether);
    }
}
