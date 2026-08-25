# What Slither said, and what we did about it

Seven findings. **One was a real bug.** Knowing which is the skill — a static
analyser cannot tell you what your code is *supposed* to do, so it flags shapes,
and most shapes are innocent.

## Fixed — `reentrancy-benign` and `reentrancy-events` in `Badge.mint`

The original order was:

```solidity
_safeMint(msg.sender, tokenId);   // hands control to the recipient
_setTokenURI(tokenId, uri);       // ...and only then writes state
```

`_safeMint` calls `onERC721Received` on the recipient. If that recipient is a
contract, **it gets control while the token exists but has no metadata**, and it
can re-enter from there.

Slither rated it *benign* because nothing extractable happens in that window.
That is not a reason to write it backwards. Checks, Effects, Interactions —
state first, external call last:

```solidity
_setTokenURI(tokenId, uri);        // effect
_safeMint(msg.sender, tokenId);    // interaction
```

Costs nothing. `_setTokenURI` never required the token to exist.

## Excluded, with a reason — see `slither.config.json`

**`incorrect-equality`: `idx == 0`.** The detector looks for `==` against
balances and timestamps, where an exact match is a bad assumption. Here `idx`
comes from a mapping, and 0 means "no row" — that *is* the 1-based index design,
and it is exact by construction.

**`timestamp`: same two lines.** Slither associates them with `block.timestamp`
because the struct stores one. The comparison has nothing to do with time.

**`pragma`: six Solidity versions.** All six come from OpenZeppelin's own files.
Not ours to fix, and not a risk.

## The habit

Never silence a detector without writing down why. A `slither.config.json` with
no explanation next to it is indistinguishable from someone who did not
understand the finding.
