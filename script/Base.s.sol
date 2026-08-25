// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

/// @notice One config file, many chains. Summarised from the pattern in
///         1Hive/gardens-v2 (`pkg/contracts/script/BaseMultiChain.s.sol`),
///         which does this across six production networks.
///
/// Why bother: hardcoding an address in a script works exactly once. The moment
/// you deploy to a second chain you start editing Solidity to change a constant,
/// and that is how you deploy to mainnet with the testnet address still in it.
///
/// Usage:
///   NETWORK=sepolia forge script script/Deploy.s.sol --broadcast
abstract contract Base is Script {
    using stdJson for string;

    string internal network;
    uint256 internal chainId;
    string internal rpc;
    string internal explorer;
    address internal ufscBuilders;

    function _load() internal {
        network = vm.envOr("NETWORK", string("sepolia"));
        string memory json = vm.readFile("config/networks.json");
        string memory k = string.concat(".", network);

        require(vm.keyExistsJson(json, k), "unknown network - check config/networks.json");

        chainId      = json.readUint(string.concat(k, ".chainId"));
        rpc          = json.readString(string.concat(k, ".rpc"));
        explorer     = json.readString(string.concat(k, ".explorer"));
        ufscBuilders = json.readAddress(string.concat(k, ".ufscBuilders"));

        console.log("network ", network);
        console.log("chainId ", chainId);
    }
}
