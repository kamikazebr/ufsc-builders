// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title UFSCBuilders — the class registry
/// @notice Deployed once, by the instructor, before class. Every student calls
///         `register` with their team name and the token they just deployed.
///         The board at the front of the room reads this contract live.
///
/// @dev This is the whole contract. Forty lines. Read it top to bottom — every
///      idea in the session is in here somewhere:
///
///        - a struct, an array and a mapping (how state is shaped)
///        - `msg.sender` (there is no `req.user`; the signature IS the identity)
///        - `calldata` vs `storage` (what the tx carries vs what the chain keeps)
///        - an event (the cheap write — nothing on-chain can read it back)
///        - custom errors (cheaper than require strings since 0.8.4)
///        - insert-or-update (there is no UPSERT; you write the branch yourself)
contract UFSCBuilders {
    struct Entry {
        address who;    // who registered — taken from msg.sender, never passed in
        string  name;   // team name, chosen by the student
        address token;  // the ERC-20 they deployed  (BUILD 1)
        address badge;  // the ERC-721 they deployed (BUILD 2), zero until set
        uint256 at;     // block.timestamp of the last write
    }

    /// @dev `private` here is about *contract* visibility, not secrecy.
    ///      Anyone can read these slots straight off the chain.
    Entry[] private _entries;

    /// @notice 1-based index into `_entries`. Zero means "never registered".
    /// @dev The 1-based trick exists because a mapping returns 0 for missing
    ///      keys, and 0 is a valid array index. Off-by-one on purpose.
    mapping(address => uint256) public indexOf;

    event Registered(address indexed who, string name, address token);
    event BadgeSet(address indexed who, address badge);

    error NameEmpty();
    error NameTooLong(uint256 given, uint256 max);
    error NotRegistered();

    uint256 public constant MAX_NAME = 32;

    /// @notice Register, or overwrite your previous entry.
    /// @param name  Team name. `calldata` because we only read it.
    /// @param token The ERC-20 you deployed. Not validated on purpose — see the
    ///              exercise in docs/security.md.
    function register(string calldata name, address token) external {
        uint256 len = bytes(name).length;
        if (len == 0) revert NameEmpty();
        if (len > MAX_NAME) revert NameTooLong(len, MAX_NAME);

        uint256 idx = indexOf[msg.sender];

        if (idx == 0) {
            _entries.push(Entry(msg.sender, name, token, address(0), block.timestamp));
            indexOf[msg.sender] = _entries.length; // 1-based
        } else {
            Entry storage e = _entries[idx - 1];   // `storage` = a pointer, not a copy
            e.name  = name;
            e.token = token;
            e.at    = block.timestamp;
        }

        emit Registered(msg.sender, name, token);
    }

    /// @notice Add the NFT from BUILD 2 without retyping your name.
    /// @dev Updating one field of an existing row — the other half of the
    ///      insert-or-update branch above. Note it reverts if you never
    ///      registered: there is no row to update.
    function setBadge(address badge) external {
        uint256 idx = indexOf[msg.sender];
        if (idx == 0) revert NotRegistered();

        _entries[idx - 1].badge = badge;
        _entries[idx - 1].at    = block.timestamp;

        emit BadgeSet(msg.sender, badge);
    }

    function count() external view returns (uint256) {
        return _entries.length;
    }

    function entryAt(uint256 i) external view returns (Entry memory) {
        return _entries[i];
    }

    /// @notice Everything, in one call. Fine for a classroom, a bad idea at scale:
    ///         an unbounded return grows until the RPC refuses to serve it.
    ///         This is why indexers exist — see docs/indexing.md.
    function all() external view returns (Entry[] memory) {
        return _entries;
    }
}
