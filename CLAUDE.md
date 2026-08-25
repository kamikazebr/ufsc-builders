# UFSC Builders — notes for coding agents

Read this before changing anything. It is short on purpose.

## What this repo is

A Foundry template from Module 2 of the Ethereum Builders Tour at UFSC,
Florianópolis. It is meant to be forked and taken to a hackathon. The contracts
are small and heavily commented because they are teaching material — when you
edit them, the comments are part of the code, not decoration around it.

## Toolchain

**Foundry, not Hardhat.** No `npx hardhat`, no `ethers` in tests. Tests are
Solidity, in `test/`, and they run with `forge test`.

**Dependencies are git submodules**, the same as
[1Hive/gardens-v2](https://github.com/1Hive/gardens-v2). Do not run
`npm install @openzeppelin/contracts` — the import path
`@openzeppelin/contracts/...` is a *remapping* (`remappings.txt`) that points at
`lib/openzeppelin-contracts/contracts/`. If `lib/` is empty, the fix is:

```
make install          # git submodule update --init --recursive
```

Clone with `git clone --recursive`, or run the above afterwards.

**Use the Makefile.** Every command worth running has a target — `make help`
lists them. If you find yourself typing a long `forge script ... --rpc-url ...`
by hand, there is already a target for it, or there should be.

## Rules that are not negotiable

1. **Never commit `.env`.** It holds a private key. `.env.example` is the
   tracked one; `.env` is gitignored and stays that way.
2. **Never commit `script/raw.txt` or `script/addresses.txt`.** Those hold other
   people's wallet addresses, collected by form. Both are gitignored; the
   `.example` files are what is tracked.
3. **Tests must pass before you commit.** `make test`. If you are committing
   something you could not verify, put `WIP` in the message and say what is
   unverified.
4. **Do not hand-edit `subgraph/abis/UFSCBuilders.json`.** It is generated:
   `make abi`. Hand-editing it makes the indexer disagree with the chain, and
   that failure is silent.
5. **Do not silence a Slither finding without writing down why.** `SLITHER.md`
   triages the current findings one by one. Add to it; do not add exclusions to
   `slither.config.json` that nothing explains.

## Layout

```
src/         contracts — Token (ERC-20), UFSCBuilders (registry + ERC-721),
             Badge (ERC-721 with per-token URI), Disperse (batch send)
test/        Solidity tests, one file per contract
script/      deploy + operational scripts; Base.s.sol reads config/networks.json
subgraph/    The Graph indexer for UFSCBuilders
docs/        one file per topic — read these before asking
slides/      the class deck, self-contained HTML
.claude/     skills — see below
```

## Skills in this repo

- `solidity-review` — review a contract before you ship it
- `hackathon-scope` — turn a vague idea into something that fits 48 hours
- `ship-to-testnet` — deploy, verify, and prove it works

Invoke one by name when the task matches.

## Conventions

- Solidity `0.8.24`, OpenZeppelin `v5.7.0`. Both are pinned; changing either is
  a decision, not a cleanup.
- Custom errors, not `require` strings — cheaper since 0.8.4, and the repo is
  consistent about it.
- Emit an event on every state change. The subgraph reads events; a state
  change with no event is invisible to every indexer and every frontend.
- Checks, effects, interactions — in that order. `src/Badge.sol` has the
  comment explaining why `_safeMint` goes last.
- English in code, comments, and docs. The class was in Portuguese; the repo is
  not.

## Testnet keys

Everything here targets Sepolia. The key in `.env` is a throwaway that must
never have held real money. Say so plainly if you see one being reused — but do
not treat a testnet key as a security incident, and do not add warnings about it
to every file.
