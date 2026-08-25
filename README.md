# UFSCBuilders

Starter repo for **Module 2 — Solidity & Token Standards**
Ethereum Builders Tour · Florianópolis · 25 Aug 2026

Four contracts, twenty-one tests, a subgraph, and nine pages that answer the
questions you will actually hit at the hackathon on the 29th.

---

## Live, right now

Everything below is deployed and verified on **Sepolia**. You do not deploy the
registry — you call it.

| | |
|---|---|
| **Registry** | [`0xaD08C29Aa13a01Ef33533398cf8bAA9eFEeAc360`](https://sepolia.etherscan.io/address/0xaD08C29Aa13a01Ef33533398cf8bAA9eFEeAc360#code) — verified source, Read/Write tabs live |
| **Subgraph** | [playground](https://api.studio.thegraph.com/query/1758157/ufscbuilder/v0.0.1/graphql) — public GraphiQL, no login |
| **Badge image** | `ipfs://bafkreigpgwxwpaaocq5ut3g2sfaeadhqpei2r5nmlnbijcpr4uehppdl54` |
| **Board** | `slides/board.html` — open it, it already points at the registry |

Your one call, once your token is deployed:

```solidity
register("your team", <your token address>)
```

That single transaction writes your row **and** mints your badge. The token id
is your row number.

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
make setup             # installs Foundry if missing, then the dependencies
make build
make test              # 21 tests, three of them fuzzed over 512 inputs
```

`make setup` checks node, pnpm and docker too, and tells you which are missing
and what each is for — node and pnpm only matter for the subgraph, docker only
for `make slither`. Everything else works without them.

Dependencies are git submodules, so `forge install` is not how you fetch them:
`make install` (which `setup` calls) runs `git submodule update --init
--recursive`. Cloning with `--recursive` does it up front.

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
| `src/Badge.sol` | ERC-721 with one pinned JSON per token — the other half of [docs/pinata.md](docs/pinata.md). **Not deployed by default**: registering already mints you a badge, and this costs 1.25M gas. `DEPLOY_BADGE=1 make deploy` when you want it. |
| `src/Disperse.sol` | Fund a whole room in one transaction. Fifteen lines, and one of them was a real bug — see [SLITHER.md](SLITHER.md). |
| `test/` | 21 tests. `testFuzz_*` are properties, not examples — Foundry generates the inputs and tries to break you. `DisperseReentrancy.t.sol` is a real theft bug, reproduced then fixed. |
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

## Deploying your own token

Name and symbol come from the environment, not from editing Solidity:

```
TOKEN_NAME="Robo Devs" TOKEN_SYMBOL="ROBO" make deploy
```

It prints the token address and the exact `register` command to paste next.

`src/Badge.sol` is skipped by default — it costs 1,248,707 gas, nearly twice the
Token, and nothing in the class calls it. `DEPLOY_BADGE=1 make deploy` when you
want the per-token-metadata example.

## Funding a room (instructor)

Sign with a keystore, not a key in a file:

```
make wallet-import name=ufsc     # once — asks for the key, then a password
make wallet-use name=ufsc        # writes ACCOUNT and SENDER into .env
make drop                        # from here on, no arguments needed
```

`--account` asks for the password on every command. `PASSWORD_FILE=~/.ufsc-pw
make drop` stops that — see [docs/wallet.md](docs/wallet.md) for the trade-off.

`make wallet` lists what Foundry already has and which one is in use. Without
`ACCOUNT`, every target falls back to `PRIVATE_KEY` from `.env` — fine for a
testnet key that never held money, not fine for anything else. Full detail in
[docs/wallet.md](docs/wallet.md).

Two more instructor targets:

```
make pin       # pins assets/badge.png, prints BADGE_CID for .env
make registry  # deploys UFSCBuilders with that image. Once, before class.
make verify    # Etherscan verification, if --verify fell back to Sourcify
```

`make verify` exists because `--verify` silently uses Sourcify when
`ETHERSCAN_API_KEY` is empty — and Sourcify-verified is not Etherscan-verified:
no source tab, no Read/Write Contract.

An empty wallet cannot call a faucet contract — calling costs gas, which is the
thing it does not have. So the instructor pushes instead of them pulling.

1. A shared spreadsheet, one row each: name and wallet address. QR on screen,
   editable without a Google login.
2. Watch the rows fill; you know when to stop waiting.
3. Copy the column into `script/raw.txt` — header, timestamps, whatever, it does
   not need cleaning. Both `raw.txt` and `addresses.txt` are gitignored: they
   hold other people's wallets.

```bash
make addresses            # pulls every 0x… out of raw.txt, lowercases, dedupes
DISPERSE=0x… make drop    # 0.05 ETH each, in ONE transaction
```

`make drop` deploys `src/Disperse.sol` the first time and prints its address —
keep it and pass it back as `DISPERSE=` so the next run reuses it, and the whole
room is funded in **one** transaction. It refuses a `DISPERSE` whose deployed
code is not this repo's, and refuses to run at all when the chain does not match
`NETWORK`.

`make fund` does the same job as N separate transactions, no contract needed —
simpler to read, thirty nonces to wait through. Both skip anyone who already has
a balance, so re-running is safe.

Fifteen lines, and you can read all of them. That is the reason to deploy your
own rather than connecting a funded wallet to a website you did not read.

Collect the night before if you can. Then nobody waits in the room.

## Safety

Every key in this repo is a throwaway that only ever touches Sepolia. Never put a
key holding real money into a file, a terminal, or a website.

Sepolia is alive until **30 September 2026**. After that the network you use here
changes; nothing else does.
