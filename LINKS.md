# Every link from the session

Nothing here needs an account except where it says so.

## What you set up tonight

| | |
| --- | --- |
| [rabby.io](https://rabby.io) | The wallet. Testnets are **off by default** — Settings → Enable testnets, then add Sepolia. |
| [remix.ethereum.org](https://remix.ethereum.org) | Solidity in the browser. Nothing to install. Resolves the npm imports on its own. |
| [etherscan.io/apidashboard](https://etherscan.io/apidashboard) | API key for `--verify`. One key covers 60+ chains since V2. |
| [thegraph.com/studio](https://thegraph.com/studio) | Subgraphs. Your wallet is the account. Free plan: 100k queries/month, 3 subgraphs. |
| [pinata.cloud](https://pinata.cloud) | Pins your NFT image and metadata. Free: 1 GB, 1 gateway. |

## Out of testnet ETH

[sepolia-faucet.pk910.de](https://sepolia-faucet.pk910.de/) — proof of work in the
browser. No signup, and it does not demand a mainnet balance the way most faucets
now do. Roughly **0.28 SepETH per hour**; the minimum claim is 0.05, so about
**eleven minutes** for a first claim.

Slow for a room of thirty. Fine for one person on a Saturday.

## Where to find something worth building

| | |
| --- | --- |
| [eips.ethereum.org/all#last-call](https://eips.ethereum.org/all#last-call) | The 14-day window before a proposal is Final. Short list, high signal. |
| [ethereum-magicians.org](https://ethereum-magicians.org) | Where standards get argued *before* they exist. An open thread is an unsolved problem. |
| [speedrunethereum.com/builds](https://speedrunethereum.com/builds) | What people already built, filterable by category. |
| [speedrunethereum.com](https://speedrunethereum.com) | BuidlGuidl's challenges. Challenge 0 is this ground, done properly with a frontend. |

## Agent tooling

| | |
| --- | --- |
| [thegraph.com/docs/en/ai-overview](https://thegraph.com/docs/en/ai-overview/) | The Graph's MCP server + Agent Skills. Query a subgraph in plain language; needs a Gateway API key from Studio. See [docs/indexing.md](docs/indexing.md). |
| [github.com/pashov/skills](https://github.com/pashov/skills) | `solidity-auditor`. MIT. Spawns several agents, so it costs tokens — check before running it on a free plan. |
| [BMAD brainstorming](https://github.com/bmad-code-org/BMAD-METHOD) | One workflow, for when the idea is the bottleneck. Ignore the rest of the framework over a weekend. |

## Reference

| | |
| --- | --- |
| [book.getfoundry.sh](https://book.getfoundry.sh) | forge, cast, anvil, chisel |
| [docs.openzeppelin.com/contracts](https://docs.openzeppelin.com/contracts) | The contracts you imported |
| [github.com/pashov/skills](https://github.com/pashov/skills) | `solidity-auditor` — an AI audit pass. MIT. Costs tokens; check before running it on a free plan. |
| [revoke.cash](https://revoke.cash) | Every approval you have ever signed. Worth looking at once. |

## Video — all in Portuguese, all by the instructor

| | |
| --- | --- |
| [Overflow and underflow](https://youtu.be/GnhLM8mHq8E) | 16 min · bits, bytes, what `uint256` really is |
| [chisel, worked examples](https://www.youtube.com/watch?v=_sPuy0pGUmA) | 20 min · literal arithmetic |
| [Three lines that clone a contract](https://youtu.be/B0V3zoK9sxo) | 9 min · EIP-1167 and Yul |
| [Subgraph, start to finish](https://www.youtube.com/watch?v=YYe5gYzmXU4) | 1h04 · schema through deploy |

### Understanding the key itself

| | |
|---|---|
### The class subgraph

| | |
|---|---|
| [playground](https://api.studio.thegraph.com/query/1758157/ufscbuilder/v0.0.1/graphql) | public GraphiQL, no login — query the registry live |
| `https://api.studio.thegraph.com/query/1758157/ufscbuilder/v0.0.1` | the endpoint itself, if you are calling it from code |

| [iancoleman.io/bip39](https://iancoleman.io/bip39/) | seed phrase → private key → address, every step visible. Run it offline with a throwaway seed — a site that turns a seed into keys is exactly the site you never paste a real seed into. |


## The slides

In [`slides/`](slides/). Open `index.html` in a browser — no build, no server.
`board.html` is the live board; it reads the registry over plain `eth_call`, so
it needs an RPC and the contract address, nothing else.

Re-run `slides/make-qr.py` after changing any URL, so the QR codes match:

```bash
uv run --with qrcode --with pillow python3 slides/make-qr.py
```
