# Pinata — putting the image somewhere

`tokenURI` returns a string. You now need something real at the other end of it.

Running an IPFS node yourself means keeping a machine online forever, which is
not what you want on a Saturday. A pinning service does it for you.

## The free plan is enough

$0/month · **1 GB storage** · **1 dedicated gateway** · no card.

A badge image is a few hundred KB. You are nowhere near the limit.

<https://pinata.cloud> → sign up → **Files**.

## Two contracts here, two different answers

This repo does it both ways on purpose, because the trade-off is the lesson.

| | what is pinned | where the JSON comes from |
|---|---|---|
| `src/UFSCBuilders.sol` | **the image only** | built on-chain, per token, in `tokenURI` |
| `src/Collectible.sol` | image **and** a JSON per token | pinned, one file per token |

The registry can say *"UFSC Builder #7"* on badge number seven without anybody
uploading thirty JSON files, because the string is assembled at call time out of
`Strings.toString(tokenId)` and one shared `imageURI`. That is the pattern most
real collections use: small and dynamic on-chain, big and static off-chain.

`Collectible.sol` takes a full URI per token instead, which is what you want when each
token genuinely has different art.

## Pinning the image

The badge is already pinned. It is in `.env.example`:

```
BADGE_CID=bafkreigpgwxwpaaocq5ut3g2sfaeadhqpei2r5nmlnbijcpr4uehppdl54
```

To pin your own — put `PINATA_JWT` in `.env`
(<https://app.pinata.cloud/developers/api-keys>, upload scope is enough), then:

```
make pin
```

It prints a `BADGE_CID=` line. Paste it into `.env` and run `make registry`.

Re-run `make pin` on an unchanged file and **you get the identical CID back**.
That is not caching. The CID *is* a hash of the bytes, so the same bytes have
the same name everywhere, forever, on every node. Nothing is stored twice.

## The two-CID flow, for per-token metadata

If you are doing it the `Collectible.sol` way, the order matters and this is where
people go wrong.

**1. Upload the image.** Pinata gives you a CID.

**2. Write the metadata JSON with that CID inside it:**

```json
{
  "name": "UFSC Badge #0",
  "description": "Ethereum Builders Tour, Florianópolis",
  "image": "ipfs://bafkreigpgwxwpaaocq5ut3g2sfaeadhqpei2r5nmlnbijcpr4uehppdl54",
  "attributes": [
    { "trait_type": "Cohort", "value": "2026" }
  ]
}
```

Upload **that** too. You get a second CID.

**3. Mint with the JSON's CID — not the image's:**

```solidity
mint("ipfs://<THE JSON CID>")
```

> **The single most common mistake:** minting the image CID. The NFT then has a
> PNG where its metadata should be, every marketplace fails to parse it, and it
> shows up as broken with no error message anywhere.

## Gateways

`ipfs://` is not a URL a browser understands. Something has to resolve it.

Pinata gives you one dedicated gateway on the free plan:

```
https://<your-subdomain>.mypinata.cloud/ipfs/<CID>
```

Yours is faster and is not shared with the whole internet, so use it for your
own frontend. But **do not put a gateway URL in `tokenURI`** — put `ipfs://`.
Wallets and marketplaces resolve it through a gateway of their own choosing, and
a hardcoded gateway URL is a link that rots the day that company changes its
mind.

Measured on the badge above, 66 KB:

| gateway | |
|---|---|
| `amethyst-hidden-lark-905.mypinata.cloud` | 200, 1.2 s |
| `ipfs.io` | 200, 1.5 s |
| `dweb.link` | 301 to the subdomain form — normal, follow it |
| `cloudflare-ipfs.com` | dead. Cloudflare shut its gateway down; anything telling you to use it is out of date |

Worth doing yourself before class: fetch your CID from a gateway that is *not*
the one you uploaded through. If it only resolves on your own gateway, it is not
really on the network yet.

## Doing it from the terminal

Pinata ships an MCP server, so an agent can pin a file and hand back the CID
without anyone opening the dashboard: <https://docs.pinata.cloud/tools/mcp/overview>

```
claude mcp add pinata -s user \
  -e PINATA_JWT=... -e GATEWAY_URL=<sub>.mypinata.cloud \
  -- npx pinata-mcp /path/to/assets
```

Two notes. The last argument is an **allowed directory** — the server cannot
read anything outside it, so point it at `assets/`, not at your home folder.
And `npx` re-downloads the package on every run; installing it pinned
(`npm i --ignore-scripts --save-exact pinata-mcp@0.2.0`) and pointing the
command at the local binary is the safer habit.

`make pin` above does the same job with `curl` and no dependencies at all.

## What pinning does and does not buy you

- The CID is a **hash of the content**. Change one byte, you get a different CID.
  Nobody can swap the image behind your back. That is real.
- The content stays reachable **while somebody pins it**. Unpin it, close the
  account, stop paying — the CID becomes a hash of a file that no longer exists,
  and the NFT is a blank square.

So "stored on IPFS" means "someone is still paying to keep this". Worth knowing
before you tell a user their art is permanent.

## No account, or Pinata is down

The fully trustless end of the spectrum needs no host at all: build the JSON and
an SVG on-chain and return them as a `data:` URI from `tokenURI`.

```solidity
return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
```

Expensive, ugly, and it will outlive every company involved. Cost versus
permanence — the same trade-off as everything else here.
