// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/UFSCBuilders.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract UFSCBuildersTest is Test {
    UFSCBuilders board;
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");
    address tokenA = makeAddr("tokenA");
    address tokenB = makeAddr("tokenB");

    string constant URI = "ipfs://bafyBadgeImage/badge.png";

    function setUp() public {
        board = new UFSCBuilders(URI);
    }

    function test_RegisteringMintsYouABadge() public {
        vm.prank(alice);
        board.register("time chupacabra", tokenA);

        assertEq(board.count(), 1);
        assertEq(board.indexOf(alice), 1, "1-based");
        assertEq(board.ownerOf(1), alice, "the badge is yours");
        assertEq(board.balanceOf(alice), 1);
    }

    /// The whole design in one assertion: your row number IS your token id.
    function test_TokenIdIsYourRowNumber() public {
        vm.prank(alice); board.register("a", tokenA);
        vm.prank(bob);   board.register("b", tokenB);

        assertEq(board.ownerOf(board.indexOf(alice)), alice);
        assertEq(board.ownerOf(board.indexOf(bob)), bob);
        assertEq(board.entryAt(board.indexOf(bob) - 1).who, bob);
    }

    function test_SecondRegistrationUpdatesAndDoesNotMintAgain() public {
        vm.startPrank(alice);
        board.register("first", tokenA);
        board.register("second", tokenB);
        vm.stopPrank();

        assertEq(board.count(), 1, "update, not append");
        assertEq(board.balanceOf(alice), 1, "still exactly one badge");
        assertEq(board.entryAt(0).token, tokenB);
    }

    /// The JSON is built on demand and carries your own number; the image is
    /// the same pinned file for everyone.
    function test_MetadataCarriesYourNumber() public {
        vm.prank(alice); board.register("a", tokenA);
        vm.prank(bob);   board.register("b", tokenB);

        string memory one = _decode(board.tokenURI(1));
        string memory two = _decode(board.tokenURI(2));

        assertTrue(_has(one, "UFSC Builder #1"), one);
        assertTrue(_has(two, "UFSC Builder #2"), two);
        assertTrue(_has(one, URI), "image must point at the pinned file");
        assertTrue(_has(two, URI), "image must point at the pinned file");
    }

    function test_MetadataIsValidJson() public {
        vm.prank(alice); board.register("a", tokenA);
        string memory j = _decode(board.tokenURI(1));
        assertEq(vm.parseJsonString(j, ".name"), "UFSC Builder #1");
        assertEq(vm.parseJsonString(j, ".image"), URI);
        assertEq(vm.parseJsonUint(j, ".attributes[1].value"), 1);
    }

    function _decode(string memory uri) internal pure returns (string memory) {
        bytes memory b = bytes(uri);
        bytes memory prefix = bytes("data:application/json;base64,");
        bytes memory tail = new bytes(b.length - prefix.length);
        for (uint256 i = 0; i < tail.length; i++) tail[i] = b[i + prefix.length];
        return string(Base64.decode(string(tail)));
    }

    function _has(string memory hay, string memory needle) internal pure returns (bool) {
        return vm.indexOf(hay, needle) != type(uint256).max;
    }

    function test_UnmintedTokenURIReverts() public {
        vm.expectRevert();
        board.tokenURI(99);
    }

    function test_EmptyNameReverts() public {
        vm.prank(alice);
        vm.expectRevert(UFSCBuilders.NameEmpty.selector);
        board.register("", tokenA);
    }

    function test_EmitsRegisteredWithTokenId() public {
        vm.expectEmit(true, true, false, true);
        emit UFSCBuilders.Registered(alice, 1, "time chupacabra", tokenA);

        vm.prank(alice);
        board.register("time chupacabra", tokenA);
    }

    /// However many people register, everyone owns exactly the badge whose id
    /// is their row, and nobody owns anybody else's.
    function testFuzz_EveryoneOwnsExactlyTheirOwnRow(uint8 n) public {
        n = uint8(bound(n, 1, 40));
        for (uint256 i = 0; i < n; i++) {
            address who = makeAddr(vm.toString(i));
            vm.prank(who);
            board.register(vm.toString(i), tokenA);
        }
        assertEq(board.count(), n);
        for (uint256 i = 0; i < n; i++) {
            address who = makeAddr(vm.toString(i));
            assertEq(board.ownerOf(i + 1), who);
            assertEq(board.balanceOf(who), 1);
        }
    }
}
