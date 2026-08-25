// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Your token. Change NAME and SYMBOL, deploy it, register it.
/// @dev    ERC20 gives you six functions and two events. Open the OpenZeppelin
///         source and read `_update` — that one function is the whole standard.
contract Token is ERC20, Ownable {
    uint256 public immutable cap;

    error CapExceeded(uint256 requested, uint256 remaining);

    constructor(string memory name_, string memory symbol_, uint256 cap_, address owner_)
        ERC20(name_, symbol_)
        Ownable(owner_)
    {
        cap = cap_;
        _mint(owner_, cap_ / 2); // half now, half mintable later
    }

    function mint(address to, uint256 amount) external onlyOwner {
        uint256 remaining = cap - totalSupply();
        if (amount > remaining) revert CapExceeded(amount, remaining);
        _mint(to, amount);
    }
}
