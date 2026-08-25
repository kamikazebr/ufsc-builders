# UFSCBuilders

Starter repo for **Module 2 — Solidity & Token Standards**
Ethereum Builders Tour · Florianópolis · 25 Aug 2026

Three contracts, ten tests, a subgraph, and five pages that answer the questions
you will actually hit at the hackathon on the 29th.

---

## Two ways in. Pick one.

### Browser — nothing to install

Open [remix.ethereum.org](https://remix.ethereum.org), paste a file from `src/`,
compile with **0.8.24**, deploy to **Sepolia**. The npm imports resolve on their
own. See [docs/remix.md](docs/remix.md).

This is the path for the session. It works on any laptop.

### Codespaces — the real toolchain, still nothing installed

On GitHub: `Code` → `Codespaces` → *Create codespace*. Foundry, node, pnpm,
graph-cli and slither, in a browser tab. See [docs/remix.md](docs/remix.md).

### Foundry — when it starts to matter

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup

forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts

forge build
forge test -vvv        # 10 tests, two of them fuzzed over 512 inputs
```

Deploy:

```bash
cp .env.example .env   # fill in a THROWAWAY key
source .env

forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

Read and write without a frontend — the hackathon superpower:

```bash
cast call $TOKEN "balanceOf(address)(uint256)" $YOU --rpc-url $SEPOLIA_RPC_URL
cast send $TOKEN "transfer(address,uint256)" $FRIEND 1ether \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

---

## What is in here

| | |
| --- | --- |
| `src/UFSCBuilders.sol` | The class registry. Forty lines, and every idea from the session is in it. You **call** this one — the instructor deployed it. |
| `src/Token.sol` | Your ERC-20. OpenZeppelin, capped, owner-minted. |
| `src/Badge.sol` | Your ERC-721. `tokenURI` returns a string and the chain does not care what is behind it. |
| `src/Disperse.sol` | Fund a whole room in one transaction. Fifteen lines, and one of them was a real bug — see [SLITHER.md](SLITHER.md). |
| `test/` | 10 tests. `testFuzz_*` are properties, not examples — Foundry generates the inputs and tries to break you. |
| `subgraph/` | Ready to deploy. The ABI is generated from your own build, so it cannot drift. |
| `.github/workflows/` | `forge test` and Slither on every push. |

## Everything else

- **[LINKS.md](LINKS.md)** — every link from the session, in one page
- **[slides/](slides/)** — the deck and the live board. Open `index.html`, no build step.
- **[SLITHER.md](SLITHER.md)** — what the static analyser said, which finding was real, and the worse one it missed
- **[CLAUDE.md](CLAUDE.md)** — read this first if you are pointing a coding agent at the repo

## Bringing an agent to the hackathon

Claude Code reads `CLAUDE.md` on its own, so it will already know this is Foundry
and not Hardhat, that dependencies are submodules, and that `.env` never gets
committed. Three skills ship in `.claude/skills/` — ask for one by name:

| | |
| --- | --- |
| `hackathon-scope` | you have no idea yet, or an idea far too big for 48 hours |
| `solidity-review` | you wrote a contract and want it torn apart before you ship it |
| `ship-to-testnet` | deploy, verify, and end up with a link you can demo |

## The pages

- **[docs/remix.md](docs/remix.md)** — Remix, and honestly when to leave it for Foundry
- **[docs/chisel.md](docs/chisel.md)** — the Solidity REPL. Five things worth knowing, including the `abi.encodePacked` collision
- **[docs/security.md](docs/security.md)** — Slither, the Pashov audit skill, and two deliberate bugs in this repo for you to argue about
- **[docs/wallet.md](docs/wallet.md)** — the key that signs: exporting from Rabby, and the encrypted keystore for when you keep using this
- **[docs/pinata.md](docs/pinata.md)** — where the NFT image actually lives, and the CID mistake everyone makes once
- **[docs/verify.md](docs/verify.md)** — get an Etherscan key, and why an unverified contract is one nobody can attach to
- **[docs/indexing.md](docs/indexing.md)** — subgraph vs Ponder, and the one line that decides it
- **[docs/deeper.md](docs/deeper.md)** — for the quarter of the room that already does this professionally: overflow at the bit level, EIP-1167, Yul
- **[docs/ideas.md](docs/ideas.md)** — where to find something worth building on the 29th

## `forge build` prints two warnings. That is the point.

```
warning[erc20-unchecked-transfer]: ERC20 'transfer' and 'transferFrom'
calls should check the return value
```

They are real, they are in the tests, and they are the reason `SafeERC20` exists.
The toolchain told you before anyone reviewed your code. That is the habit worth
leaving with — see [docs/security.md](docs/security.md).

## Video, if you would rather watch

All in Portuguese, all by the instructor:

| | |
| --- | --- |
| [Overflow and underflow](https://youtu.be/GnhLM8mHq8E) | 16 min · bits, bytes, and what `uint256` really is |
| [chisel, with worked examples](https://www.youtube.com/watch?v=_sPuy0pGUmA) | 20 min · literal arithmetic, where you quietly send the wrong amount |
| [Three lines that clone a contract](https://youtu.be/B0V3zoK9sxo) | 9 min · EIP-1167 and Yul |
| [Subgraph, start to finish](https://www.youtube.com/watch?v=YYe5gYzmXU4) | 1h04 · schema through deploy |

## Funding a room (instructor)

Sign with a keystore, not a key in a file:

```
cast wallet import ufsc --interactive     # once — asks for the key, then a password
cast wallet address --account ufsc        # the address it holds
ACCOUNT=ufsc SENDER=0x… make drop
```

`make wallet` lists what Foundry already has. Without `ACCOUNT`, every target
falls back to `PRIVATE_KEY` from `.env` — fine for a testnet key that never held
money, not fine for anything else.

An empty wallet cannot call a faucet contract — calling costs gas, which is the
thing it does not have. So the instructor pushes instead of them pulling.

1. A Google Form with one field, `your wallet address`. QR on screen.
2. Responses land in a Sheet. Watch the count; you know when to stop waiting.
3. Copy the column into `script/raw.txt` — header, timestamps, whatever, it does
   not need cleaning.

```bash
make addresses            # pulls every 0x… out of raw.txt, lowercases, dedupes
DISPERSE=0x… make drop    # 0.05 ETH each, in ONE transaction
```

`make drop` deploys `src/Disperse.sol` the first time and prints its address —
keep it and pass it back as `DISPERSE=` so the next run reuses it. Both it and
`make fund` (which sends N separate transactions instead, no contract needed)
skip anyone who already has a balance, so re-running is safe.

Fifteen lines, and you can read all of them. That is the reason to deploy your
own rather than connecting a funded wallet to a website you did not read.

Collect the night before if you can. Then nobody waits in the room.

## Safety

Every key in this repo is a throwaway that only ever touches Sepolia. Never put a
key holding real money into a file, a terminal, or a website.

Sepolia is alive until **30 September 2026**. After that the network you use here
changes; nothing else does.
