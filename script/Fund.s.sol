// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

/// Fund the whole room in ONE transaction.
///
/// A faucet *contract* cannot solve this: calling it costs gas, and gas is
/// exactly what an empty wallet does not have. So the instructor pushes.
///
/// 1. Students paste their address in the Telegram group
/// 2. Paste them into script/addresses.txt, one per line
/// 3. forge script script/Fund.s.sol --rpc-url $SEPOLIA_RPC_URL \
///      --private-key $PRIVATE_KEY --broadcast
contract Fund is Script {
    uint256 constant AMOUNT = 0.05 ether; // plenty for two deploys + calls

    function run() external {
        string memory raw = vm.readFile("script/addresses.txt");
        string[] memory lines = vm.split(raw, "\n");

        vm.startBroadcast();
        uint256 sent;
        for (uint256 i = 0; i < lines.length; i++) {
            string memory line = _trim(lines[i]);
            bytes memory b = bytes(line);
            // skip blanks, comments, and anything that is not an address
            if (b.length != 42 || b[0] != "0" || b[1] != "x") continue;
            address to = vm.parseAddress(line);
            if (to.balance >= AMOUNT) continue;       // already funded, skip
            (bool ok, ) = to.call{value: AMOUNT}("");
            require(ok, "send failed");
            sent++;
        }
        vm.stopBroadcast();

        console.log("funded", sent, "wallets");
        console.log("each received (wei)", AMOUNT);
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
