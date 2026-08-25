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
        // Badge is the "one pinned JSON per token" example — the other half of
        // docs/pinata.md. The class never calls it: registering on UFSCBuilders
        // already mints you an ERC-721, and this costs 1.25M gas, nearly twice
        // the Token. Deploy it when you actually want it:
        //   DEPLOY_BADGE=1 make deploy
        address badge = address(0);
        if (vm.envOr("DEPLOY_BADGE", false)) {
            badge = address(new Badge(msg.sender));
        }

        vm.stopBroadcast();

        console.log("token", address(token));
        if (badge != address(0)) console.log("badge", badge);
        else console.log("badge  skipped - DEPLOY_BADGE=1 to include it");
        console.log("");
        console.log("now register it:");
        console.log("  cast send $UFSC_BUILDERS \\");
        console.log("    \"register(string,address)\" \"<your team>\" %s \\", address(token));
        console.log("    --rpc-url $SEPOLIA_RPC_URL --account $ACCOUNT");
    }
}
