// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Your NFT. `tokenURI` returns a *string* — the chain has no idea
///         what is at the other end of it, and does not care.
contract Badge is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    constructor(address owner_) ERC721("UFSC Badge", "BADGE") Ownable(owner_) {}

    /// @dev Anyone can mint one to themselves. That is deliberate — it is the
    ///      exercise in docs/security.md. What would you change, and why?
    /// @dev Checks, Effects, Interactions — in that order, and the order matters.
    ///      `_safeMint` calls `onERC721Received` on the recipient, so a contract
    ///      receiving this token gets control BEFORE the next line runs. Writing
    ///      the URI first means it can never observe a token with no metadata.
    ///      Slither flags the other order as `reentrancy-benign`; benign today is
    ///      not a reason to write it backwards.
    function mint(string calldata uri) external returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _setTokenURI(tokenId, uri);   // effect
        _safeMint(msg.sender, tokenId); // interaction — hands control to the recipient
    }
}
