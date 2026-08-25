// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/UFSCBuilders.sol";

/// @notice Deploys the class registry. Run ONCE, by the instructor, before the
///         session. Students never run this — they run `make deploy`, which
///         deploys their own Token, and then register against this address.
///
///   make pin        # pins assets/badge.png, prints BADGE_CID
///   make registry   # this script
///
/// @dev The image is passed in rather than hardcoded for the reason every
///      hardcoded address exists: the constant that was right on the testnet is
///      the one that ships to mainnet. Pin a new badge, redeploy, no edit here.
contract DeployRegistry is Script {
    function run() external {
        string memory cid = vm.envString("BADGE_CID");
        require(bytes(cid).length > 0, "set BADGE_CID in .env - see docs/pinata.md");

        // ipfs:// is the canonical form. A gateway URL would work today and rot
        // the day that gateway does; the CID is the content, the gateway is a
        // convenience. Wallets resolve ipfs:// through a gateway of their own.
        string memory imageURI = string.concat("ipfs://", cid);

        vm.startBroadcast();
        UFSCBuilders registry = new UFSCBuilders(imageURI);
        vm.stopBroadcast();

        console.log("UFSCBuilders", address(registry));
        console.log("imageURI    ", imageURI);
        console.log("");
        console.log("Now do three things:");
        console.log("  1. put the address in .env as UFSC_BUILDERS");
        console.log("  2. put it in config/networks.json under the network you used");
        console.log("  3. put it in subgraph/subgraph.yaml, with the deploy block");
    }
}
