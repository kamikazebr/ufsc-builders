// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Disperse.sol";
import "./Base.s.sol";

/// Pay the whole room in ONE transaction.
///
///   make addresses          # pull the 0x… out of script/raw.txt
///   DISPERSE=0x… make drop  # one tx, everybody funded
///
/// No DISPERSE set? It deploys one first, prints the address, and you keep it.
contract Drop is Base {
    /// Measured on Sepolia, not guessed. One student doing everything:
    ///   deploy Token                     708,453
    ///   register (mints their NFT)       206,121
    ///   ~25 mints/transfers/approves   ~1,000,000
    ///                                  ----------
    ///                                  ~1,915,000 gas
    /// 0.05 ETH covers that up to ~26 gwei, far above anything Sepolia sees.
    /// It is also one minimum claim from the pk910 faucet, so a student who
    /// burns through it can top themselves up without asking.
    ///
    /// Collectible.sol is NOT in that number: it costs 1,248,707 gas on its own and
    /// the class never calls it, so `make deploy` skips it unless you ask.
    uint256 constant AMOUNT = 0.05 ether;

    function run() external {
        // Which chain did you mean? config/networks.json says, NETWORK picks it,
        // and this refuses to run anywhere else. Without it a stale RPC in .env
        // sends the room's funding to whatever chain that URL points at.
        _load();
        require(block.chainid == chainId, "wrong chain - check NETWORK and your RPC");

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
        console.log("total to send (wei)", n * AMOUNT);
        if (n == 0) return;

        vm.startBroadcast();

        Disperse d = Disperse(vm.envOr("DISPERSE", address(0)));
        if (address(d) != address(0)) {
            // A DISPERSE exported from a chat message, or left over from another
            // chain, is a contract that keeps the whole batch. Compare the code
            // actually deployed there against what this repo compiles.
            require(
                address(d).codehash == keccak256(type(Disperse).runtimeCode),
                "DISPERSE is not this repo's Disperse - unset it and let the script deploy one"
            );
        }
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
