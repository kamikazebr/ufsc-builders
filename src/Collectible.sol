// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice One ERC-721 where every token carries its own pinned JSON — the
///         other half of docs/pinata.md, and the opposite of UFSCBuilders,
///         which builds its metadata on-chain from one shared image.
///
/// @dev Deliberately NOT called Badge. The badge is the token UFSCBuilders
///      mints when you register, and having two things called badge cost a
///      class fifteen minutes of confusion. This one is the demo.
///
/// @dev `tokenURI` returns a *string* — the chain has no idea what is at the
///      other end of it, and does not care.
contract Collectible is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    constructor(address owner_) ERC721("UFSC Collectible", "COLLECT") Ownable(owner_) {}

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
