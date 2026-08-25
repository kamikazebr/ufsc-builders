# Pinata — putting the image somewhere

`tokenURI` returns a string. You now need something real at the other end of it.

Running an IPFS node yourself means keeping a machine online forever, which is
not what you want on a Saturday. A pinning service does it for you.

## The free plan is enough

$0/month · **1 GB storage** · **1 dedicated gateway** · no card.

A badge image is a few hundred KB. You are nowhere near the limit.

<https://pinata.cloud> → sign up → **Files**.

## Two uploads, in this order

This is where people go wrong, so read the order carefully.

### 1. Upload the image

Drag it into Files. Pinata gives you a CID:

```
bafybeigd...q4  ← the IMAGE cid
```

### 2. Write the metadata JSON, with that CID inside it

```json
{
  "name": "UFSC Badge #0",
  "description": "Ethereum Builders Tour, Florianópolis",
  "image": "ipfs://bafybeigd...q4",
  "attributes": [
    { "trait_type": "Cohort", "value": "2026" }
  ]
}
```

Save it as `metadata.json` and upload **that** too. You get a second CID.

### 3. Mint with the JSON's CID — not the image's

```solidity
mint("ipfs://<THE JSON CID>")
```

> **The single most common mistake:** minting the image CID. The NFT then has a
> PNG where its metadata should be, every marketplace fails to parse it, and it
> shows up as broken with no error message anywhere.

## Your gateway

`ipfs://` is not a URL a browser understands. Something has to resolve it.

Pinata gives you one dedicated gateway on the free plan:

```
https://<your-subdomain>.mypinata.cloud/ipfs/<CID>
```

Use that, not `ipfs.io`. The public gateway is shared by the whole internet and
gets slow exactly when thirty people hit it at once.

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
