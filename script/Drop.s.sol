// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Disperse.sol";

/// Pay the whole room in ONE transaction.
///
///   make addresses          # pull the 0x… out of script/raw.txt
///   DISPERSE=0x… make drop  # one tx, everybody funded
///
/// No DISPERSE set? It deploys one first, prints the address, and you keep it.
contract Drop is Script {
    uint256 constant AMOUNT = 0.01 ether;

    function run() external {
        string[] memory lines = vm.split(vm.readFile("script/addresses.txt"), "\n");

        address[] memory to = new address[](lines.length);
        uint256 n;
        for (uint256 i = 0; i < lines.length; i++) {
            string memory line = _trim(lines[i]);
            bytes memory b = bytes(line);
            if (b.length != 42 || b[0] != "0" || b[1] != "x") continue;
            address a = vm.parseAddress(line);
            if (a.balance >= AMOUNT) continue;          // already funded, skip
            to[n++] = a;
        }
        assembly { mstore(to, n) }                       // shrink to what we filled

        console.log("funding", n, "wallets");
        if (n == 0) return;

        vm.startBroadcast();

        Disperse d = Disperse(vm.envOr("DISPERSE", address(0)));
        if (address(d) == address(0)) {
            d = new Disperse();
            console.log("deployed Disperse at", address(d));
            console.log("keep it: export DISPERSE=%s", address(d));
        }

        // Overpay deliberately; _refund sends the remainder straight back.
        d.dropEqual{value: (n * AMOUNT) + 0.001 ether}(to, AMOUNT);

        vm.stopBroadcast();
    }

    function _trim(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        uint256 start; uint256 end = b.length;
        while (start < end && (b[start] == 0x20 || b[start] == 0x0d)) start++;
        while (end > start && (b[end - 1] == 0x20 || b[end - 1] == 0x0d)) end--;
        bytes memory out = new bytes(end - start);
        for (uint256 i = 0; i < out.length; i++) out[i] = b[start + i];
        return string(out);
    }
}
