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
    error Underfunded(uint256 sent, uint256 needed);

    /// @notice Same amount to everyone — what you want for a classroom.
    function dropEqual(address[] calldata to, uint256 amount) external payable {
        uint256 total = amount * to.length;
        if (msg.value < total) revert Underfunded(msg.value, total);

        for (uint256 i = 0; i < to.length; i++) {
            (bool ok, ) = to[i].call{value: amount}("");
            if (!ok) revert SendFailed(to[i], amount);
        }
        _refund(msg.value - total);
    }

    /// @notice A different amount per address.
    function drop(address[] calldata to, uint256[] calldata amounts) external payable {
        if (to.length != amounts.length) revert LengthMismatch(to.length, amounts.length);

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) total += amounts[i];
        if (msg.value < total) revert Underfunded(msg.value, total);

        for (uint256 i = 0; i < to.length; i++) {
            (bool ok, ) = to[i].call{value: amounts[i]}("");
            if (!ok) revert SendFailed(to[i], amounts[i]);
        }
        _refund(msg.value - total);
    }

    /// @dev Overpay on purpose, get the remainder back. Sending exact change
    ///      means one wrong multiplication strands ETH in here forever — and
    ///      this contract has no owner and no way to sweep it.
    ///
    ///      `left` is passed in, computed from THIS call's `msg.value`. The
    ///      first version read `address(this).balance` instead, and that was a
    ///      real bug: paying a recipient hands it control (`.call` runs its
    ///      `receive`), and at that moment the balance still holds the money for
    ///      everybody further down the list. A recipient could re-enter with an
    ///      empty list, fall straight through the loop into the refund, and be
    ///      paid the lot — see test/DisperseReentrancy.t.sol.
    ///
    ///      The rule that fixes it is not "add a mutex". It is: settle against
    ///      what this call was given, never against a shared balance you do not
    ///      own. Slither does not flag it, because Disperse has no storage and
    ///      its reentrancy detectors follow storage writes.
    function _refund(uint256 left) private {
        if (left > 0) {
            (bool ok, ) = msg.sender.call{value: left}("");
            if (!ok) revert SendFailed(msg.sender, left);
        }
    }
}
