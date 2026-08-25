// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title UFSCBuilders — the class registry, which is also the badge
/// @notice Deployed once, by the instructor, before class. You call `register`
///         with your team name and the token you just deployed. Two things
///         happen: your name goes up on the board at the front, and you are
///         minted an NFT.
///
/// @dev Forty lines, and every idea in the session is in here:
///
///        - a struct, an array and a mapping (how state is shaped)
///        - `msg.sender` — no `req.user`; the signature IS the identity
///        - `calldata` vs `storage` — what the tx carries vs what the chain keeps
///        - an event — the cheap write, unreadable from inside the contract
///        - custom errors — cheaper than require strings since 0.8.4
///        - insert-or-update — there is no UPSERT, you write the branch
///        - and ERC-721, where **your token id is your row number**
contract UFSCBuilders is ERC721 {
    struct Entry {
        address who;    // taken from msg.sender, never passed in
        string  name;   // your team name
        address token;  // the ERC-20 you deployed
        uint256 at;     // block.timestamp of the last write
    }

    Entry[] private _entries;

    /// @notice 1-based index into `_entries`, and also your NFT's token id.
    /// @dev Zero means "never registered". The 1-based trick exists because a
    ///      mapping returns 0 for a missing key and 0 is a valid array index.
    mapping(address => uint256) public indexOf;

    /// @notice The badge artwork, pinned to IPFS. One image, every badge.
    /// @dev Images are big, so they live off-chain. The JSON around them is
    ///      small, so we build it here — which is why your badge can say your
    ///      own number without anybody pinning thirty files.
    string public imageURI;

    event Registered(address indexed who, uint256 indexed tokenId, string name, address token);

    error NameEmpty();
    error NameTooLong(uint256 given, uint256 max);

    uint256 public constant MAX_NAME = 32;

    constructor(string memory imageURI_) ERC721("UFSC Builders", "UFSC26") {
        imageURI = imageURI_;
    }

    /// @notice Register, or overwrite your previous entry. First call mints you
    ///         a badge; later calls just update the row.
    function register(string calldata name, address token) external {
        uint256 len = bytes(name).length;
        if (len == 0) revert NameEmpty();
        if (len > MAX_NAME) revert NameTooLong(len, MAX_NAME);

        uint256 idx = indexOf[msg.sender];

        if (idx == 0) {
            _entries.push(Entry(msg.sender, name, token, block.timestamp));
            idx = _entries.length;              // 1-based: also the token id
            indexOf[msg.sender] = idx;

            // Effects are done. `_mint` and not `_safeMint` on purpose: this is
            // called by people, and _safeMint would hand control to a contract
            // recipient mid-registration for no benefit here.
            _mint(msg.sender, idx);
        } else {
            Entry storage e = _entries[idx - 1];  // `storage` = a pointer, not a copy
            e.name  = name;
            e.token = token;
            e.at    = block.timestamp;
        }

        emit Registered(msg.sender, idx, name, token);
    }

    /// @notice The metadata, assembled on demand.
    /// @dev Two lessons in one function. The JSON never existed anywhere until
    ///      you called this — no file, no server, no pinning. The image did have
    ///      to be pinned, because 67 KB of PNG on-chain would cost a fortune.
    ///      That split — small and dynamic on-chain, big and static off-chain —
    ///      is how most real collections work.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory json = string.concat(
            '{"name":"UFSC Builder #', Strings.toString(tokenId),
            '","description":"Deployed a contract at the Ethereum Builders Tour, ',
            'Florianopolis, 25 Aug 2026. Token id is the row number on the board.",',
            '"image":"', imageURI, '",',
            '"attributes":[',
              '{"trait_type":"Cohort","value":"2026"},',
              '{"trait_type":"Row","display_type":"number","value":', Strings.toString(tokenId), '}',
            ']}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function count() external view returns (uint256) {
        return _entries.length;
    }

    function entryAt(uint256 i) external view returns (Entry memory) {
        return _entries[i];
    }

    /// @notice Everything in one call. Fine for a classroom, a bad idea at scale:
    ///         an unbounded return grows until the RPC refuses to serve it.
    ///         That is why indexers exist — see docs/indexing.md.
    function all() external view returns (Entry[] memory) {
        return _entries;
    }
}
