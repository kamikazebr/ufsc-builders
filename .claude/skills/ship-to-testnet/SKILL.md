---
name: ship-to-testnet
description: Use when the user wants to deploy a contract to Sepolia, verify it on Etherscan, prove a deployment actually works, or debug a failed deploy or failed verification. Covers the full path from local test to a link someone else can open.
---

# Ship to testnet

A contract that only exists on your machine is a file. Get it on-chain early —
in the first hours of a hackathon, not the last — because every problem below
takes longer than you think, and none of them show up locally.

## Before you touch the network

```
make build            # it compiles
make test             # it does what you said
make slither          # nothing high-severity
```

If any of those fail, stop. Deploying broken code to a testnet wastes gas you
had to mine for.

## 1. Have the four things you need

Copy `.env.example` to `.env` and fill it in. All four matter:

| variable | where it comes from | what breaks without it |
|---|---|---|
| `SEPOLIA_RPC_URL` | a public RPC works; the default in `.env.example` is one | nothing connects |
| `PRIVATE_KEY` | a **throwaway** wallet, never one holding real money | nothing signs |
| `ETHERSCAN_API_KEY` | <https://etherscan.io/apidashboard> | `--verify` fails, source stays unreadable |
| balance | <https://sepolia-faucet.pk910.de/> (mine it) or ask | the tx reverts before it starts |

One Etherscan key covers 60+ chains since API V2. If you find instructions
saying you need a separate key per chain, they predate August 2025.

Check the balance before you start:

```
cast balance $ADDRESS --rpc-url $SEPOLIA_RPC_URL --ether
```

Zero balance is the single most common cause of "my deploy did nothing".

## 2. Deploy

```
make deploy                      # Token + Badge, verified
```

or for one script directly:

```
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

**Without `--broadcast` nothing is sent.** Forge simulates, prints a beautiful
trace, and exits. That trace is not a deployment. This trips up everyone once.

Deploying to more than one chain? `script/Base.s.sol` reads
`config/networks.json` and is selected with `NETWORK=...`. Do not hardcode an
address in a script — the constant that was right on the testnet is the one
that ships to mainnet.

## 3. Verify

`--verify` usually handles it. When it does not, verify after the fact:

```
forge verify-contract <ADDRESS> src/Token.sol:Token \
  --chain sepolia --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string,uint256,address)" \
      "My Token" "MTK" 1000000000000000000000000 $ADDRESS)
```

Verification failures are almost always one of three things, in this order:

1. **Constructor args encoded wrong.** Most common by far. `cast abi-encode`
   them; do not type the hex by hand.
2. **Compiler settings differ** from what built the bytecode — version,
   optimizer runs, `evm_version`. They live in `foundry.toml`; Etherscan must
   be told the same ones.
3. **You verified the wrong contract path.** `src/Token.sol:Token`, with the
   contract name after the colon.

Unverified means nobody can read your source on Etherscan, and nobody can use
the Write Contract tab. For a demo, that is most of the value gone.

## 4. Prove it works

Deployment is not success. A call that changes state is.

```
cast send <ADDRESS> "register(string,address)" "Your Team" <TOKEN> \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

cast call <ADDRESS> "indexOf(address)(uint256)" $YOUR_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

Then open the transaction on <https://sepolia.etherscan.io> and read the Logs
tab. Your event should be there, decoded, because you verified the source.

**That URL is your demo.** Have it open in a tab before you present.

## 5. If you added or changed an event

The subgraph indexes events, and its ABI is generated, not written:

```
make abi                        # regenerate from the build
```

Then update `subgraph/subgraph.yaml` with the contract address and the block it
was deployed at — `startBlock` matters, because without it the indexer replays
the chain from genesis and takes hours to reach you. The deploy output prints
the block; you can also read it off Etherscan.

## When it fails

| symptom | cause |
|---|---|
| script runs, nothing on-chain | missing `--broadcast` |
| `insufficient funds for gas` | empty wallet, or you are on the wrong chain |
| `nonce too low` | a pending tx from an earlier run; wait, or bump the nonce |
| `execution reverted` with no reason | run the same call without `--broadcast` to get the trace, or add `-vvvv` |
| verified but source shows as different | optimizer settings mismatch — check `foundry.toml` |
| subgraph indexes nothing | wrong address, or `startBlock` after your transaction |

For anything involving an unfamiliar cheatcode or flag, the reference is
<https://book.getfoundry.sh>.
