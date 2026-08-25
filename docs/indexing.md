# Reading history — subgraph or Ponder

`UFSCBuilders.all()` returns every entry in one call. Fine for a classroom. It is
also the reason indexers exist: an unbounded return grows until the RPC refuses
to serve it, and there is no "give me everyone who registered on Tuesday".

A chain is very good at *state*. It is terrible at *queries*. An indexer reads
your events and puts them somewhere you can ask questions.

## The decision, in one line

> **Ponder if the demo runs on your laptop. Subgraph if a deployed frontend has
> to reach it.**

Hosting is the tiebreaker in a 48-hour hackathon, not indexing speed.

|                    | Subgraph (The Graph) | Ponder |
| ------------------ | -------------------- | ------ |
| Who hosts it       | **they do** — Studio, free for dev | you do |
| Infra you provision | none | Postgres + a Node service |
| Language           | AssemblyScript | TypeScript |
| Local dev loop     | slower | hot reload, very good |
| Speed              | fine | 10–15× faster in some benchmarks |
| Steward            | The Graph | team acquired by Monad in 2026 |

## Subgraph — the default here

Already written, in `subgraph/`. It compiles — `graph codegen` and `graph build`
both pass on this repo as committed.

### 1. Regenerate the ABI from your own build

```bash
forge inspect src/UFSCBuilders.sol:UFSCBuilders abi --json > subgraph/abis/UFSCBuilders.json
```

Do this every time you change the contract. The ABI is generated, never
hand-written, so it cannot drift from what you actually deployed — and a drifted
ABI produces an indexer that silently indexes nothing.

### 2. Point it at your deployment

In `subgraph.yaml`:

```yaml
source:
  address: "0xYourDeployedAddress"
  startBlock: 1234567     # the block it was deployed in, NOT 0
```

`startBlock: 0` makes the indexer replay the entire chain from genesis before it
reaches your first event. On Sepolia that is hours. Get the real number from the
contract's first transaction on Etherscan, or from `forge`'s broadcast log at
`broadcast/Deploy.s.sol/<chainId>/run-latest.json`.

### 3. The Studio panel

<https://thegraph.com/studio> → connect your wallet. No signup form; the wallet
is the account.

**Create a Subgraph** → give it a slug. The page you land on has the three things
you need, in the top right:

- the **deploy key** (`graph auth`)
- the **slug** (`graph deploy`)
- the **query URL**, which is what your frontend eventually calls

```bash
cd subgraph
pnpm install
pnpm codegen && pnpm build

./node_modules/.bin/graph auth <DEPLOY_KEY>
./node_modules/.bin/graph deploy <YOUR_SLUG>
```

It asks for a version label — `v0.0.1` is fine, and it is only a label.

### 4. What the panel shows you after deploying

- **Sync status.** It starts at your `startBlock` and walks forward. "Synced"
  means it caught up to the chain head.
- **Logs.** This is where a mapping that throws shows up. **An indexer that
  throws stops indexing entirely** — it does not skip the bad event and carry on.
  That is why `handleBadgeSet` in this repo checks for null and returns instead
  of assuming the Builder exists.
- **Playground.** A GraphQL editor against your own data, with the schema
  autocompleting. Try it before you write a single line of frontend:

```graphql
{
  builders(orderBy: updatedAt, orderDirection: desc, first: 10) {
    id name token badge writes updatedAt
  }
  board(id: "0x626f617264") { total }
}
```

### 5. Dev endpoint vs publishing

The free plan gives you **100,000 queries a month** and **3 deployed subgraphs**,
renewing monthly. That is entirely enough for a hackathon demo — you will not get
close.

*Publishing* to the decentralized network is a separate, paid step involving GRT
and curation signal. You do not need it this weekend, and nobody will ask.

### Watch the whole thing being built

**[Desenvolvimento e Configuração do Subgraph (The Graph Studio)](https://www.youtube.com/watch?v=YYe5gYzmXU4)** — 1h04
Felipe Novaes Rocha · March 2023 · **in Portuguese**

Start to finish: schema, mappings, Studio, deploy. Recorded in 2023, so parts of
the Studio interface have moved since — the shape of the work has not.

## Ponder — when you want TypeScript and no AssemblyScript

```bash
pnpm create ponder@latest
```

Requires **Postgres in a private network with under 50ms latency** — their docs
are explicit that you get performance problems above that. There is no managed
option; Railway is the platform they document.

Which is fine, and often better, if the answer to "where does this run during the
demo?" is "my laptop".

## The thing worth carrying away

The indexer can only see what you **emit**. A contract that forgets its events is
invisible — to wallets, to explorers, and to this. Events are not logging. They
are the read API.

---

## Asking a subgraph questions without writing GraphQL

The Graph ships an **official MCP server**, so an agent can find a subgraph by
contract address, read its schema, and query it in plain language. Remote, so
there is nothing to install:

```bash
claude mcp add --transport sse subgraph \
  https://subgraphs.mcp.thegraph.com/sse \
  --header "Authorization: Bearer <GATEWAY_API_KEY>"
```

The key is a **Gateway API key**, from the *API Keys* tab in
[Subgraph Studio](https://thegraph.com/studio) — the same place you deploy from,
a different key from the deploy key.

They also publish **Agent Skills** for writing, optimising and testing subgraphs.
The MCP reads; the skills build.

### The part worth saying out loud

This is the whole argument in one tool. An agent will write you a subgraph faster
than you can type one — and it will not tell you that `startBlock: 0` means
replaying the chain from genesis, or that a mapping which throws stops indexing
*everything* instead of skipping the bad event.

Both of those cost you a night. Neither shows up as an error message. Use the
tools, and know the layer underneath them.
