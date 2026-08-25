---
name: solidity-review
description: Reviews Solidity contracts for security bugs in passes, cheapest first — build, test, Slither, then a manual checklist, then a Foundry test that proves each finding. Use when the user asks to review, audit, or check a contract, asks "is this safe to deploy", or has just written or changed something in src/.
---

# Solidity review

A review that finds nothing is worthless, and a review that invents findings is
worse than worthless. Work in passes, cheapest first. Do not start reading code
by hand until the machine has had its turn.

Reference for what real findings look like: <https://github.com/pashov/audits>
— public reports, hundreds of them, real bugs in shipped code. Read a few. The
bugs are more boring than you expect.

---

## Pass 1 — run what already exists

```bash
make build      # forge build --sizes  — read the warnings, do not scroll past them
make test       # forge test -vvv
make slither    # static analysis in the trailofbits container, --fail-on high
```

If `make build` fails, stop. There is nothing to review yet.

### Reading Slither output

Every line looks like a bug. Most are not. The format is:

```
Badge.mint(string) (src/Badge.sol#22-26) uses a dangerous ...
    Reentrancy in Badge.mint(string):
        External calls:
        - _safeMint(msg.sender,tokenId) (src/Badge.sol#25)
        State variables written after the call(s):
        - nextTokenId (src/Badge.sol#23)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#...
```

Three things to extract: **which function**, **which line**, **what shape it
matched**. Then decide, and write the decision down.

`SLITHER.md` in this repo is the worked example. Seven findings on four
contracts. **One was a real bug** (`Badge.mint` did `_safeMint` before
`_setTokenURI`, handing control to a contract recipient while the token had no
metadata — fixed by swapping two lines). Six were justified and excluded in
`slither.config.json`, each with a written reason.

Rules for triage:

- **Never exclude a detector without writing down why**, next to the exclusion.
  A `detectors_to_exclude` list with no `SLITHER.md` beside it is
  indistinguishable from someone who did not understand the finding.
- "Slither rated it benign" is not a reason to leave code backwards. The
  `Badge.mint` fix cost nothing.
- Slither only tracks **storage variables**. It does not track ETH balance, so
  it will not find the bug in Pass 2's worked example. Static analysis is a
  filter for the boring 80%, not a proof of anything.

If `make slither` exits 0, that means no *high* finding. It does not mean clean.

---

## Pass 2 — read the code

Ten things. In hackathon code, these are the ones that actually show up.

### 1. Checks → Effects → Interactions

Write state **before** you call out. An external call hands control to code you
did not write, and it can call back into you.

```solidity
// wrong — the recipient runs while state is still stale
_safeMint(msg.sender, tokenId);
_setTokenURI(tokenId, uri);

// right — src/Badge.sol
_setTokenURI(tokenId, uri);      // effect
_safeMint(msg.sender, tokenId);  // interaction, last
```

Which calls hand over control:

| call | gives control away? |
|---|---|
| `_mint` | no — pure bookkeeping |
| `_safeMint` | **yes** — calls `onERC721Received` on a contract recipient |
| `.call{value: x}("")` | **yes** — runs the recipient's `receive`/`fallback` |
| `.transfer` / `.send` | yes, but capped at 2300 gas |
| any call to a token/contract you did not write | **yes** |

`src/UFSCBuilders.sol:71` uses `_mint`, not `_safeMint`, deliberately — it is
called by humans, and `_safeMint` would hand control to a contract recipient
mid-registration for no benefit.

**Worked example — a real bug the tools missed, in this repo.** It is fixed now;
what follows is the version that shipped first, because how it was found matters
more than the patch. Full write-up in `SLITHER.md`.

`src/Disperse.sol` holds ETH for the duration of the transaction (you overpay on
purpose, `_refund()` returns the remainder). It has no storage variables, so
Slither's reentrancy detectors find nothing. But:

```solidity
function dropEqual(address[] calldata to, uint256 amount) external payable {
    for (uint256 i = 0; i < to.length; i++) {
        (bool ok, ) = to[i].call{value: amount}("");   // recipient gets control
        if (!ok) revert SendFailed(to[i], amount);
    }
    _refund();   // sends address(this).balance to msg.sender
}
```

A recipient placed **last** in the list re-enters with an empty `drop([], [])`.
That call does no work and falls straight into `_refund()`, which sends the
whole pending balance — the sender's overpayment — to the attacker. The outer
`_refund()` then sees a balance of 0 and returns nothing. The transaction
**succeeds**; the sender is simply poorer.

Verified: sender sends 1 ETH to drop 0.01 ETH to two addresses, thief walks away
with 0.99 ETH. Test in Pass 3.

Placed anywhere **but** last, the same attack drains the balance and the next
transfer then reverts the whole batch — no theft, but nobody gets paid either.

The fix is not a mutex. Track what this call owes with a local computed from
`msg.value`, and require `msg.value` to cover the total. Settle against what
this call was given, never against a shared balance you do not own.

### 2. Access control

Who is allowed to call this? Answer it for **every** state-changing function.

```solidity
function mint(address to, uint256 amount) external onlyOwner { ... }  // src/Token.sol
```

- Missing `onlyOwner` on a mint, a withdraw, a config setter, a pause — the
  single most common hackathon bug.
- `tx.origin` is **not** the caller. It is the human who signed the outermost
  transaction, so any contract they call can impersonate them. Use `msg.sender`.
  Every time.
- `private`/`internal` hide nothing on-chain. They only block *calls*, not
  *reads*. Anyone can read any storage slot.
- Absent is not the same as wrong: `Badge.mint` in `src/Badge.sol` is open to
  anyone **on purpose** (see `docs/security.md`). Ask what the function is for
  before you file it.

### 3. Ignored return values

`.call` returns `(bool, bytes)`. Dropping the bool means a failed payment looks
like a successful one.

```solidity
to[i].call{value: amount}("");                    // silent failure
(bool ok, ) = to[i].call{value: amount}("");      // right
if (!ok) revert SendFailed(to[i], amount);
```

Same for ERC-20 — see item 7.

### 4. Unbounded loops and unbounded returns

A loop over an array anyone can grow is a griefing vector: once the array is big
enough, the function costs more than the block gas limit and nobody can call it
again. Ever.

```solidity
// src/UFSCBuilders.sol — fine for a classroom, wrong at scale
function all() external view returns (Entry[] memory) { return _entries; }
```

`view` functions called off-chain are less dangerous (no gas limit on `eth_call`,
though the RPC will eventually refuse). A **state-changing** unbounded loop is a
real finding. Ask: can an attacker add entries cheaply? Then they can brick it.

Also: one failing recipient inside a loop reverts the whole batch. Is that what
you want, or should failures be recorded and skipped?

### 5. Arithmetic

Solidity ≥ 0.8 reverts on overflow, so most old bugs are gone. What is left:

- **`unchecked` is a promise you are making.** Safe when the bound is obvious
  from the line above (`for (uint i; i < len;) { unchecked { ++i; } }`). Not safe
  around anything derived from user input.
- **Division before multiplication truncates.** Integers have no fractions.

  ```solidity
  uint256 fee = (amount / 10000) * feeBps;   // amount < 10000 → fee is 0
  uint256 fee = (amount * feeBps) / 10000;   // right
  ```
- **Decimals.** 1 USDC is `1e6`, 1 DAI is `1e18`. Mixing them is a 12-order-of-
  magnitude bug that compiles cleanly.
- Casting down (`uint256` → `uint96`) truncates silently.

### 6. Randomness

`block.timestamp`, `block.number`, `blockhash`, and `block.prevrandao` are all
visible to — or influenceable by — whoever is producing the block, and readable
by any contract in the same transaction.

```solidity
// a lottery anyone can win: call it from a contract, check the result,
// revert if you lost. It costs gas and nothing else.
uint256 winner = uint256(keccak256(abi.encode(block.timestamp))) % players.length;
```

Timestamps for *deadlines* measured in hours are fine (that is what
`src/UFSCBuilders.sol` stores). Timestamps for *money* are not.

### 7. ERC-20 that does not return a bool

The standard says `transfer` returns `bool`. USDT does not. A correct caller
reverts on it. That is the whole reason `SafeERC20` exists.

```solidity
token.transfer(to, amt);                       // return ignored — may silently fail
require(token.transfer(to, amt));              // reverts on USDT-shaped tokens
IERC20(token).safeTransfer(to, amt);           // SafeERC20 — handles both
```

Also assume nothing about a token address you were handed: it may take a fee on
transfer (you receive less than you sent), rebase, or be outright hostile.
`src/UFSCBuilders.sol` never checks that `token` is even a contract — deliberate,
and exercise #2 in `docs/security.md`.

### 8. Initialization

- **`constructor`** runs once, at deploy, and its code is not part of the
  deployed bytecode. Constructor args set `immutable` values (`Token.cap`).
- **Behind a proxy there is no constructor.** Storage lives in the proxy, so an
  `initialize()` function does the work — and if it is not protected, anyone can
  call it and take ownership. Guard it, and disable the initializer on the
  implementation.
- Check for zero-address arguments in constructors and setters. `Ownable(0)` is
  a contract nobody owns.

### 9. Missing events

An event is the cheap write, and it is the only thing an off-chain indexer can
see. Every state change that a frontend or subgraph cares about needs one.

```solidity
event Registered(address indexed who, uint256 indexed tokenId, string name, address token);
```

`indexed` makes a field filterable — up to three per event. If you change a
state variable and emit nothing, `subgraph/src/mapping.ts` cannot know it
happened. That is not a security bug, but it is a shipping bug.

### 10. Hardcoded values

A fee, a deadline, a cap, or an address baked into the source is a value you
cannot change on a contract you cannot redeploy. Constructor argument, or an
`onlyOwner` setter with an event. `Token` takes `cap_` as an argument;
`UFSCBuilders` takes `imageURI_`.

---

## Pass 3 — prove it with a test

**A bug without a failing test was not found, it was imagined.** Write the test
first, watch it fail, then fix, then watch it pass.

The exploit from Pass 2, as a real Foundry test:

```solidity
// test/DisperseReentrancy.t.sol
contract Thief {
    Disperse d;
    constructor(Disperse d_) { d = d_; }
    receive() external payable {
        // re-enter with an empty drop: falls straight into _refund()
        if (address(d).balance > 0) d.drop(new address[](0), new uint256[](0));
    }
}

function test_ThiefStealsTheOverpayment() public {
    Disperse d = new Disperse();
    Thief t = new Thief(d);
    vm.deal(sender, 10 ether);

    address[] memory to = new address[](2);
    to[0] = makeAddr("honest");
    to[1] = address(t);              // last in the list

    vm.prank(sender);
    d.dropEqual{value: 1 ether}(to, 0.01 ether);

    assertEq(address(t).balance, 0.99 ether, "thief took the change");
}
```

Run one file, or one test:

```bash
forge test --match-path test/DisperseReentrancy.t.sol -vvv
forge test --match-test test_ThiefStealsTheOverpayment -vvvv   # -vvvv = full call trace
```

The three cheat codes you need:

```solidity
vm.prank(alice);                 // next call comes from alice
vm.startPrank(alice); ... vm.stopPrank();
vm.deal(alice, 10 ether);        // give alice ETH

vm.expectRevert();                                  // any revert
vm.expectRevert(UFSCBuilders.NameEmpty.selector);   // that specific error
vm.expectRevert(abi.encodeWithSelector(Token.CapExceeded.selector, CAP, CAP / 2));

vm.expectEmit(true, true, false, true);   // which topics to compare
emit UFSCBuilders.Registered(alice, 1, "name", tokenA);
board.register("name", tokenA);           // the call that must emit it
```

**Fuzzing.** `foundry.toml` already sets `[fuzz] runs = 512`. Any test whose
name starts with `testFuzz_` and takes arguments gets 512 generated inputs.
State a *property*, not an example, and `bound` the inputs to the range that
makes sense:

```solidity
function testFuzz_TransferPreservesSupply(uint256 amount) public {
    amount = bound(amount, 0, token.balanceOf(alice));
    uint256 supplyBefore = token.totalSupply();
    vm.prank(alice);
    token.transfer(bob, amount);
    assertEq(token.totalSupply(), supplyBefore);     // transfer moves value, never creates it
}
```

Good properties to fuzz: sum of balances equals total supply; nothing is ever
stranded in the contract (`testFuzz_NothingIsEverStranded` in
`test/Disperse.t.sol`); every user owns exactly their own row
(`testFuzz_EveryoneOwnsExactlyTheirOwnRow` in `test/UFSCBuilders.t.sol`).

Check what the tests actually reach:

```bash
make cov     # forge coverage --report summary
```

---

## Pass 4 — report it

One entry per finding. All five fields, or it is not a finding.

````markdown
### [High] Reentrancy in `_refund` lets a recipient steal the overpayment

**Where:** `src/Disperse.sol:38-44` (`_refund`), reachable from
`dropEqual:17` and `drop:26`.

**Scenario:**
1. Alice calls `dropEqual{value: 1 ether}([honest, thief], 0.01 ether)`.
   Overpaying is the documented usage.
2. The loop pays `honest` 0.01, then pays `thief` 0.01. `thief.receive()` runs
   while Disperse still holds 0.98 ETH.
3. `thief` calls `d.drop([], [])`. No loop body runs; `_refund()` sends
   `address(this).balance` to `msg.sender` — the thief.
4. The outer `_refund()` sees a balance of 0 and sends nothing.

**Result:** Alice loses 0.99 ETH and the transaction succeeds. No revert, no
warning.

**Test:** `test/DisperseReentrancy.t.sol::test_LastRecipientCannotPocketTheChange`
(fails before the fix, passes after).

**Fix:** stop reading `address(this).balance`. Track this call's own funds:

```solidity
function dropEqual(address[] calldata to, uint256 amount) external payable {
    uint256 spent = amount * to.length;
    if (msg.value < spent) revert ...;
    for (uint256 i = 0; i < to.length; i++) { ... }
    uint256 left = msg.value - spent;      // this call's change, not the balance
    if (left > 0) { (bool ok, ) = msg.sender.call{value: left}(""); if (!ok) revert ...; }
}
```
````

Severity, roughly:

| | |
|---|---|
| **High** | funds stolen or permanently frozen; anyone can take ownership |
| **Medium** | funds at risk under conditions the attacker partly controls; a function can be bricked |
| **Low** | needs an unlikely precondition, or costs the attacker more than it gains |
| **Info** | style, gas, missing events, missing zero-checks with no path to loss |

**Banned:** "consider adding a reentrancy guard" with no scenario. "This might
be unsafe." "Best practice suggests…" If you cannot write step 1, step 2, step 3
and name the wrong result, you do not have a finding — you have a hunch. Say so,
or say nothing.

---

## References

- <https://github.com/pashov/audits> — real audit reports, the best source of what bugs look like
- <https://book.getfoundry.sh> — cheat codes, fuzzing, invariant testing
- <https://docs.soliditylang.org> — the language, including the security considerations chapter
- <https://github.com/crytic/slither> — detector documentation for every finding it prints
- <https://swcregistry.io> — the numbered catalogue of weakness classes
- <https://consensysdiligence.github.io/smart-contract-best-practices/> — the checklist
