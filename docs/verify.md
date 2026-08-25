# Verify your contract

## Why it is not optional

You spent the class calling `UFSCBuilders` with **At Address**. That worked
because the contract is *verified* — Etherscan has its source, so Remix could
hand you a working UI for a contract you did not write.

Verifying yours is how you pay that forward. An unverified contract is a wall of
bytecode: nobody can read it, nobody can attach to it, nobody can check what it
does with their money.

And at the hackathon: judges click Etherscan. Unverified reads as hiding
something, whether or not you are.

## Get a key

<https://etherscan.io/apidashboard>

Since **API V2**, one key covers 60+ EVM chains — you pass a chain id instead of
juggling a key per explorer. V1 was deprecated in August 2025 and now returns a
deprecation error, so if you find an old tutorial using a `api-sepolia.etherscan.io`
endpoint, it is out of date.

```bash
# .env
ETHERSCAN_API_KEY=...
```

## From Foundry

At deploy time:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY \
  --broadcast --verify
```

Or after the fact, which is what you will actually need when the deploy worked
and the verify did not:

```bash
forge verify-contract <ADDRESS> src/Token.sol:Token \
  --chain sepolia \
  --constructor-args $(cast abi-encode \
      "constructor(string,string,uint256,address)" \
      "My Token" "MTK" 1000000000000000000000000 <OWNER>)
```

The constructor arguments are where this fails 90% of the time. They must match
the deploy **exactly** — same types, same values, same order.

## From Remix

Plugin manager → **Contract Verification** → paste the key → pick the network and
the deployed address. Same key.

## No key, or the key is not working

Sourcify needs no account:

```bash
forge verify-contract <ADDRESS> src/Token.sol:Token \
  --chain sepolia --verifier sourcify
```

It is a different verification system, so Etherscan may still show the contract
as unverified. Good enough to prove what you deployed; not good enough to make a
judge's life easy.

## Sanity check

```bash
cast code <ADDRESS> --rpc-url $SEPOLIA_RPC_URL | head -c 20
```

Empty output means nothing is deployed at that address, and no amount of
verifying will fix it. Check that before you debug anything else.
