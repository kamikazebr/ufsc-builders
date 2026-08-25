# What Slither said, and what we did about it

Run it yourself: `make slither`.

Two bugs were found in this repo. **Slither found one of them.** Knowing which is
the skill — a static analyser cannot tell you what your code is *supposed* to do,
so it flags shapes, and most shapes are innocent. It also misses anything that
does not look like a shape it knows.

## The one Slither found — `reentrancy-benign` in `Badge.mint`

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

## The one Slither missed — theft in `Disperse._refund`

This is the more important half of the page.

`_refund` used to read the contract's own balance:

```solidity
function _refund() private {
    uint256 left = address(this).balance;      // <- everything in here
    if (left > 0) msg.sender.call{value: left}("");
}
```

Paying a recipient hands it control — `.call` runs its `receive()`. At that
moment the balance still holds the money for **everybody further down the list**.
So a recipient that is a contract can re-enter with an empty list, fall straight
through the loop into the refund, and be paid the lot:

```solidity
receive() external payable {
    d.dropEqual{value: 0}(new address[](0), 0);   // loop does nothing, refund pays me
}
```

Two outcomes, depending on where the attacker sits in the list:

| position | what happens |
|---|---|
| anywhere but last | the next transfer runs out of balance, the whole drop reverts — nobody gets funded |
| **last** | the loop is already finished, nothing can fail, and **the transaction succeeds** with the money gone |

For this repo that is the wallet funding thirty students. One contract address
pasted into the form and either everyone goes unfunded, or the change walks.

The fix is not a mutex:

```solidity
uint256 total = amount * to.length;
if (msg.value < total) revert Underfunded(msg.value, total);
...
_refund(msg.value - total);
```

**Settle against what this call was given, never against a shared balance you do
not own.** `address(this).balance` belongs to every call that is in flight, not
to yours. Proof in `test/DisperseReentrancy.t.sol` — three tests that fail
against the old version.

Why Slither stayed quiet: its reentrancy detectors follow *storage writes*, and
`Disperse` has no storage at all. The whole bug lives in ETH accounting. This is
the honest limit of the tool, and the reason the manual pass in
`.claude/skills/solidity-review` exists.

## Excluded, with a reason — see `slither.config.json`

**`arbitrary-send-eth`: `to[i].call{value: ...}`.** Rated High, and it is the
entire purpose of the contract — you pass a list of addresses and it pays them.
It is also your own money: `msg.value` now has to cover the total, so the
contract can never spend more than the caller sent in that call. Without this
exclusion `--fail-high` blocks every build.

**`incorrect-equality`: `idx == 0`.** The detector looks for `==` against
balances and timestamps, where an exact match is a bad assumption. Here `idx`
comes from a mapping, and 0 means "no row" — that *is* the 1-based index design,
and it is exact by construction.

**`timestamp`: same two lines.** Slither associates them with `block.timestamp`
because the struct stores one. The comparison has nothing to do with time.

**`pragma`: six Solidity versions.** All six come from OpenZeppelin's own files.
Not ours to fix, and not a risk.

## Left in, deliberately

`calls-loop` and `low-level-calls` still print — five findings, all in
`Disperse`. Both are true statements about the code and neither is a bug here:
the loop is the feature, and `.call` is the correct way to send ETH to an
address that might be a contract. They are informational, `--fail-high` ignores
them, and leaving them visible is the point — a clean report you never read is
worse than a noisy one you do.

## The habit

Never silence a detector without writing down why. A `slither.config.json` with
no explanation next to it is indistinguishable from someone who did not
understand the finding.

And never mistake a green Slither run for a reviewed contract. The second bug on
this page had a green run.
