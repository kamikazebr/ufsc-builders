---
name: hackathon-scope
description: Takes someone from "no idea yet" to a scope that ships in 48 hours — use when a hackathon team has no idea, has an idea that is too big, cannot justify why it needs a blockchain, or needs a build plan for the 29 Aug 2026 hackathon.
---

# Hackathon scope

The hackathon is **29 Aug 2026**. This skill produces one thing: a scope small
enough to demo, with a deploy plan.

Links are not repeated here. Idea sources are in [docs/ideas.md](../../../docs/ideas.md);
everything else from the session is in [LINKS.md](../../../LINKS.md).

Run the five sections in order. Do not skip 2 — most ideas die there, and it is
cheaper to kill one on Monday than on Saturday.

---

## 1. Find the problem before the solution

Do not start from "what can I build with an NFT". Start from something that
already annoys the person in front of you. Ask these, and write the answers
down verbatim:

- What did you pay for in the last month where you could not see where the money
  went?
- What do you keep in a spreadsheet that other people also need to trust?
- Where do you currently have to ask someone for permission, and what happens if
  they say no or just do not answer?
- In your course, your job, your club, your building — who holds a list that
  everyone else has to believe?
- What do you already do with friends that involves splitting, owing, or
  tracking money by hand?
- What costs how much today, and to whom? (A number here is worth more than any
  adjective.)
- What have you complained about twice in the last week?

If every answer is abstract, the idea is not there yet. Push for one sentence
with a person, a number and a time in it: *"my building's 40 residents each pay
R$X/month and nobody sees the account statement."*

When personal life produces nothing, go outward — three doors, each answering a
different question. Full descriptions in [docs/ideas.md](../../../docs/ideas.md):

| Source | What it is good for |
| --- | --- |
| [eips.ethereum.org/all#last-call](https://eips.ethereum.org/all#last-call) | Standards 14 days from Final. Nearly nothing implements them yet, so a first implementation is a real contribution — and the spec writes half your scope for you. |
| [ethereum-magicians.org](https://ethereum-magicians.org) | Arguments about standards that do not exist yet. An open thread with no agreement is an unsolved problem someone competent already cares about. |
| [speedrunethereum.com/build-prompts](https://speedrunethereum.com/build-prompts) | ~13 ready-made specs written for an agent. Good for shaping scope even if you build it yourself: read one to see how tight a 48-hour spec has to be. |
| [speedrunethereum.com/builds](https://speedrunethereum.com/builds) | What has already been built, by category. Use it twice: to avoid rebuilding something that exists, and to calibrate size — weekend projects are smaller than you think. |

If the idea itself is the blocker, run the BMAD brainstorming workflow
(`/bmad:core:workflows:brainstorming`) — it forces you to name the user before
the feature. One workflow, nothing else from that framework this week.

---

## 2. The "why blockchain" test

Ask it flatly: **would a Postgres database with a login screen solve this?**

If yes, it is not a web3 hackathon project. It is CRUD with extra steps, and a
judge will say so in the first thirty seconds.

Answers that pass are few and concrete:

- **Money has to move without an intermediary.** Someone pays someone and no
  company sits between them holding the balance.
- **A record has to be verifiable by a third party** who does not trust you and
  should not have to — an outsider can check it without asking you for anything.
- **A rule has to hold without trusting the operator.** The person running the
  thing cannot break it even if they want to, because the code is the enforcement.
- **An asset has to exist outside the platform.** It keeps working if your app
  disappears; someone else can build on it without your permission.

Answers that fail, no matter how they are phrased: "it's transparent" (a public
read-only endpoint is transparent), "it's immutable" (append-only Postgres is
immutable), "it's decentralized" (say what specifically stops working if you
disappear), "it's a token for engagement" (that is points, and points are a
database column).

Reject your own idea honestly. Say out loud which of the four it is. If you
cannot pick one without hedging, the answer is none of them — go back to
section 1 and take a different problem from the list. You still have days; this
is exactly what they are for.

One legitimate escape hatch: keep the problem, move the on-chain part. The
tutoring app is CRUD, but the escrow that releases payment when both sides
confirm is not. Build the escrow, mock the app.

---

## 3. Cut it until it fits in 48 hours

One question does the cutting:

> **What is the single transaction that, if it works in the demo, proves the thesis?**

Name it in the form `someone calls f(x) and y becomes true on-chain`. Everything
that does not serve that transaction is out of scope. Not "later" — out.

Hard rules, no exceptions over a weekend:

- **No mobile app.** A browser page, or `cast` in a terminal.
- **No login system of your own.** The wallet is the account. `msg.sender` is
  the identity — that is already true and you get it for free.
- **No tokenomics.** No emission curve, no vesting, no staking rewards, no
  governance token. If your project needs a whitepaper to explain the token,
  cut the token.
- **No upgradeable contracts.** Proxies cost you a day and buy you nothing in
  48 hours. Redeploy instead.
- **Two contracts maximum.** One is better. Three means you will spend the
  weekend on the wiring between them.
- **No admin dashboard, no roles beyond one owner, no pause, no multisig.**

Ugly frontend is fine — a raw HTML page with three buttons is fine, no frontend
at all is fine if you drive it with `cast`. A demo that does not run is not fine.
That is the whole ranking.

Sanity check the cut: can you explain the single transaction to a stranger in
one sentence, and would they understand why it is on a chain? If not, cut again.

---

## 4. Map it to what you already have

Nobody starts from zero. Find the row closest to your idea:

| If your project is... | Start from | What it already does |
| --- | --- | --- |
| Anything with a fungible balance, points with real transfer, a stablecoin-ish unit | `src/Token.sol` | ERC-20, OpenZeppelin, capped supply, owner-minted. Change name, symbol, cap. |
| A certificate, ticket, membership, proof of attendance, receipt | `src/UFSCBuilders.sol` | ERC-721 whose `tokenURI` builds JSON on-chain with `Base64` + `Strings` — no server, no pinning per token, and the metadata can carry per-token data. |
| An NFT whose art or metadata is a file you already have | `src/Collectible.sol` + [docs/pinata.md](../../../docs/pinata.md) | `ERC721URIStorage` — `tokenURI` is just a string you set at mint. Pin the file, mint the CID. |
| A registry, list, or board that others must read: who did what, who is a member, who claimed what | `src/UFSCBuilders.sol` | Struct + array + `mapping(address => uint256)`, 1-based index, insert-or-update, indexed event, custom errors. This is the shape of most registries. |
| Paying many people at once: payroll, splits, airdrop, refunds, prize distribution | `src/Disperse.sol` | N transfers in one transaction, equal or per-address amounts, with refund of the overpay. Fifteen lines you can read. |
| Anything that needs a list, a leaderboard, a feed, or history in a frontend | `subgraph/` | Schema, mapping and a generated ABI, ready to deploy. Use it instead of an unbounded `all()` view. [docs/indexing.md](../../../docs/indexing.md) |
| Anything you might deploy to a second chain | `script/Base.s.sol` + `config/networks.json` | Network name → chainId, RPC, explorer, addresses. Add a block to the JSON, never edit Solidity to change a chain. |
| Anything at all | `test/`, `Makefile`, `.github/workflows/` | 10 tests including two fuzzed, `make build/test/deploy/slither`, and CI that runs `forge test` + Slither on every push. |

A read-only page that just shows on-chain state needs no backend: `slides/board.html`
reads the registry over plain `eth_call` with an RPC and an address. Copy it.

If nothing matches, your project is probably one of these plus one function.
Find which one and add the function.

---

## 5. The 48 hours

The only milestone that matters:

> **A contract deployed and verified on Sepolia within the first 12 hours** —
> even if it barely does anything.

Deploy is where projects die. Leaving it for the end is the classic way to have
working code and no demo. Deploy something trivial early, then keep redeploying.

| Block | Hours | Do |
| --- | --- | --- |
| 0 | 0–2 | Write the single transaction from section 3 on paper. Agree on it out loud. Fill `.env` with a throwaway key. Get Sepolia ETH before you need it — the faucet in [LINKS.md](../../../LINKS.md) takes about eleven minutes for a first claim. |
| 1 | 2–8 | Write the minimum contract: the one function, the state it touches, one event. `forge test` on the happy path plus one failing case. |
| 2 | 8–12 | **Deploy and verify.** `make deploy` (`--verify`). Paste the Etherscan link somewhere the whole team can see. Send the transaction once with `cast send` and confirm it on the explorer. Milestone met. |
| 3 | 12–20 | Sleep. Someone has to be awake for the demo. |
| 4 | 20–30 | Finish the contract: the second function if you truly need one, the reverts, the events the frontend will read. Redeploy and verify again — it costs nothing on a testnet. |
| 5 | 30–38 | Frontend or subgraph, not both unless the frontend needs a list. Three buttons. Ugly. |
| 6 | 38–44 | Run the demo end to end from a clean wallet. Whatever breaks, that is your remaining work. Do not add features here. |
| 7 | 44–48 | Freeze the code. Write the one sentence. Rehearse the demo twice with the exact wallet and the exact tab layout you will use on stage. |

Rules for the weekend:

- Every redeploy goes through `--verify`. Unverified means nobody can read your
  code or call it from the explorer — see [docs/verify.md](../../../docs/verify.md).
- `cast call` and `cast send` are the frontend until the frontend exists. Do not
  block contract work on UI work.
- If the deploy is not done by hour 12, cut a function, not the deploy.
- Keep the Etherscan link in the pinned message. You will need it twice.

---

## 6. What the demo has to contain

Three things, and they are not negotiable:

1. **A real transaction on the testnet, sent live** — or, if the room's wifi is
   bad, sent minutes before and shown with the wallet in the same tab. Not a
   recording, not a mock.
2. **The Etherscan link**, verified, source visible, the transaction findable in
   it. Anyone in the room can open it on their own phone and check. That is the
   whole point of the argument you made in section 2.
3. **One sentence** naming who has the problem, what the transaction does, and
   which of the four "why blockchain" answers it is.

What does not belong in the demo: a roadmap slide, a token distribution pie
chart, a market-size number, a team-photo slide, a "future work" list, or the
word "ecosystem".

If the demo runs, the link opens and the sentence lands, you are finished.
