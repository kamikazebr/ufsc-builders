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

        // Set these in .env instead of editing Solidity. Editing a script to
        // change a string is how a hardcoded testnet value reaches mainnet.
        string memory name   = vm.envOr("TOKEN_NAME", string("Change This"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("CHANGE"));
        uint256 supply       = vm.envOr("TOKEN_SUPPLY", uint256(1_000_000 ether));

        Token token = new Token(name, symbol, supply, msg.sender);
        console.log("name  ", name);
        console.log("symbol", symbol);
        Badge badge = new Badge(msg.sender);

        vm.stopBroadcast();

        console.log("token", address(token));
        console.log("badge", address(badge));
        console.log("");
        console.log("now register it:");
        console.log("  cast send $UFSC_BUILDERS \\");
        console.log("    \"register(string,address)\" \"<your team>\" %s \\", address(token));
        console.log("    --rpc-url $SEPOLIA_RPC_URL --account $ACCOUNT");
    }
}
