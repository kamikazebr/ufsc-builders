// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Disperse — pay many addresses in ONE transaction
/// @notice Deploy it once, keep the address. Nobody else's website involved,
///         and nothing to trust: the whole contract fits on this screen.
///
/// @dev The classic version of this (disperse.app) has existed since 2018 and is
///      deployed on most chains. Deploying your own takes thirty seconds and
///      means you never connect a funded wallet to a site you did not read.
contract Disperse {
    error LengthMismatch(uint256 recipients, uint256 amounts);
    error SendFailed(address to, uint256 amount);

    /// @notice Same amount to everyone — what you want for a classroom.
    function dropEqual(address[] calldata to, uint256 amount) external payable {
        for (uint256 i = 0; i < to.length; i++) {
            (bool ok, ) = to[i].call{value: amount}("");
            if (!ok) revert SendFailed(to[i], amount);
        }
        _refund();
    }

    /// @notice A different amount per address.
    function drop(address[] calldata to, uint256[] calldata amounts) external payable {
        if (to.length != amounts.length) revert LengthMismatch(to.length, amounts.length);
        for (uint256 i = 0; i < to.length; i++) {
            (bool ok, ) = to[i].call{value: amounts[i]}("");
            if (!ok) revert SendFailed(to[i], amounts[i]);
        }
        _refund();
    }

    /// @dev Overpay on purpose, get the remainder back. Sending exact change
    ///      means one wrong multiplication strands ETH in here forever — and
    ///      this contract has no owner and no way to sweep it.
    function _refund() private {
        uint256 left = address(this).balance;
        if (left > 0) {
            (bool ok, ) = msg.sender.call{value: left}("");
            if (!ok) revert SendFailed(msg.sender, left);
        }
    }
}
