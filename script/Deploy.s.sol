// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/Badge.sol";

/// forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL \
///   --private-key $PRIVATE_KEY --broadcast --verify
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        Token token = new Token(
            "Change This",   // <- your name
            "CHANGE",        // <- your symbol
            1_000_000 ether,
            msg.sender
        );
        Badge badge = new Badge(msg.sender);

        vm.stopBroadcast();

        console.log("token", address(token));
        console.log("badge", address(badge));
        console.log("now register the token address on UFSCBuilders");
    }
}
