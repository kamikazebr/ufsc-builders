# The key that signs

Nothing reaches a chain without a signature. Two ways to give Foundry one, and
they are not equally good.

## First, the rule

**Make a wallet that exists only for this.** Not the one with your money in it,
not the one you use on mainnet, not one you have ever typed a seed phrase into
on a site you did not read. A separate wallet, created today, holding testnet
ETH and nothing else.

Everything below is safe for that wallet and unsafe for any other.

## Students: exporting from Rabby

Foundry cannot talk to a browser extension. To deploy from the terminal you need
the key itself.

In Rabby: **⚙︎ → Address Management → the ⋯ next to your address → Export Private
Key**. It asks for your password and shows a 64-character hex string.

Put it in `.env`:

```
PRIVATE_KEY=0x<the 64 characters>
```

`.env` is gitignored in this repo and must stay that way. Check it any time:

```
git check-ignore -v .env      # prints the rule that ignores it
```

Three things that will bite someone in the room:

- **`0x` in front.** Rabby exports it without. Foundry wants it with.
- **A space or newline at the end** from copying. Trim it.
- **Committing it.** If it happens, the key is burned — assume anyone can see it.
  For a testnet wallet that costs you nothing, so just make a new one. The habit
  is what matters: getting it wrong here is free, getting it wrong later is not.

Once it is in `.env`, everything works:

```
make deploy
```

## Instructor, or anyone who keeps using this: a keystore

A raw key in a file is one `cat` away from a screen share. Foundry can hold it
encrypted instead, and ask for a password when it needs to sign.

```
make wallet-import name=ufsc     # asks for the key, then a password
make wallet-use name=ufsc        # writes ACCOUNT and SENDER into .env
```

`wallet-import` wraps `cast wallet import ufsc --interactive`, which writes an
encrypted JSON file to `~/.foundry/keystores/ufsc`. The key is never on disk in
the clear and never in `.env`.

`wallet-use` runs `cast wallet address --account ufsc` once, and stores the
result. That call costs a password prompt, which is exactly why it is done once
and written down rather than recomputed on every `make`.

### It will ask for the password every time

`--account` prompts on every signing command. During a class that is five
prompts with a projector behind you. Point Foundry at a file and it stops:

```
echo -n 'the password' > ~/.ufsc-pw && chmod 600 ~/.ufsc-pw
PASSWORD_FILE=~/.ufsc-pw make drop
```

The Makefile turns that into `--password-file`. Every deploy line then prints
`(password from file)` so you always know which of the two is happening.

A password in a file is weaker than one in your head — anything that can read
your disk can now sign. For a testnet keystore that has never held real money,
that is the better trade against typing it repeatedly in front of a room. For
anything else it is not: type it.

From then on nothing needs arguments:

```
make wallet       # what foundry holds, and which one is in use
make deploy       # signs with the keystore, prompts for the password
make drop
```

Under the hood the Makefile builds one variable:

```make
SIGNER := $(if $(ACCOUNT),--account $(ACCOUNT) --sender $(SENDER),--private-key $(PRIVATE_KEY))
```

`ACCOUNT` set, it signs from the keystore. `ACCOUNT` empty, it falls back to
`PRIVATE_KEY`. Both paths work; the fallback exists so nobody in the room is
blocked by a password prompt during a 15-minute build.

## Checking what you have

```
cast wallet list                                   # every keystore
cast wallet address --account ufsc                 # the address it holds
cast balance <ADDRESS> --rpc-url $SEPOLIA_RPC_URL --ether
```

A zero balance is the most common reason a deploy does nothing at all. Check it
before you blame the code.

## If you need testnet ETH

<https://sepolia-faucet.pk910.de/> — it mines in the browser tab. Leave it
running while you read the rest of the repo.

## Never

- A key holding real money in `.env`, in a terminal, in a chat, or pasted into a
  site that offers to "validate" it.
- A seed phrase anywhere near any of this. A private key exposes one address; a
  seed phrase exposes every address it ever derived, on every chain.
- `PRIVATE_KEY` on the command line in a shared shell — it lands in your history
  and in the process list, where anyone on the machine can read it.
