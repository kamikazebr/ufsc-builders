// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Disperse.sol";

contract DisperseTest is Test {
    Disperse d;
    address payable sender = payable(makeAddr("sender"));

    function setUp() public {
        d = new Disperse();
        vm.deal(sender, 10 ether);
    }

    function _people(uint256 n) internal returns (address[] memory a) {
        a = new address[](n);
        for (uint256 i = 0; i < n; i++) a[i] = makeAddr(vm.toString(i));
    }

    function test_EveryoneGetsPaidInOneCall() public {
        address[] memory to = _people(30);
        vm.prank(sender);
        d.dropEqual{value: 0.3 ether}(to, 0.01 ether);

        for (uint256 i = 0; i < to.length; i++) {
            assertEq(to[i].balance, 0.01 ether);
        }
    }

    function test_OverpayComesBack() public {
        address[] memory to = _people(3);
        uint256 before = sender.balance;

        vm.prank(sender);
        d.dropEqual{value: 1 ether}(to, 0.01 ether);   // way more than needed

        assertEq(sender.balance, before - 0.03 ether, "only the drop should leave");
        assertEq(address(d).balance, 0, "nothing may be stranded");
    }

    function test_MismatchedLengthsRevert() public {
        address[] memory to = _people(3);
        uint256[] memory amts = new uint256[](2);
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(Disperse.LengthMismatch.selector, 3, 2));
        d.drop{value: 1 ether}(to, amts);
    }

    function testFuzz_NothingIsEverStranded(uint8 n, uint96 amount) public {
        n = uint8(bound(n, 1, 60));
        amount = uint96(bound(amount, 1, 0.05 ether));
        address[] memory to = _people(n);

        vm.deal(sender, 100 ether);
        vm.prank(sender);
        d.dropEqual{value: 100 ether}(to, amount);

        assertEq(address(d).balance, 0);
    }
}
