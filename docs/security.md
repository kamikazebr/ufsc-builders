# Security — the parts that fit in one page

## Run the linter and read what it says

`forge build` on this repo prints two warnings, on purpose:

```
warning[erc20-unchecked-transfer]: ERC20 'transfer' and 'transferFrom'
calls should check the return value
```

They are in the test file, and they are correct. Some real tokens — USDT is the
famous one — do not return a `bool` from `transfer`, so a *correct* caller
reverts on them. That is the entire reason `SafeERC20` exists.

The toolchain told you. Most money lost on-chain was preceded by a warning
somebody scrolled past.

## Slither

Static analysis. Catches a large class of things before anyone reviews your code.

```bash
pipx install slither-analyzer      # or: pip install slither-analyzer
slither . --exclude-dependencies
```

No Python on your machine? Use the container:

```bash
docker run -v "$PWD":/src trailofbits/eth-security-toolbox \
  slither /src --exclude-dependencies
```

CI runs it on every push — see `.github/workflows/security.yml`.

## An AI second pass

The [Pashov Audit Group skills](https://github.com/pashov/skills) (MIT) include
`solidity-auditor`, a Claude Code skill that runs a parallel scan over a repo and
merges the findings into one report.

```bash
# see the repo for install instructions
/solidity-auditor
```

Two honest caveats. It spawns several agents, so **it costs tokens** — check
before you run it on a free plan. And no automated pass, AI or static, proves the
absence of a bug. Treat both as a filter that catches the boring 80%, not as a
review.

## Going deeper on any of this

[docs/deeper.md](deeper.md) — overflow at the bit level, EIP-1167, and the path
from Solidity down through Yul to opcodes.

## Two exercises in this repo

Both are deliberate. Neither is a trick.

1. **`Collectible.mint` is open to anyone.** Should it be? What is the argument for
   leaving it open, and what breaks if you do?
2. **`UFSCBuilders.register` never checks that `token` is a contract**, let alone
   an ERC-20. Write the check. Then ask whether it was worth the gas, and what a
   determined liar could still put in that field.

The second one is the more interesting question, and it is the one that comes up
in every real integration.

## The list, before anything holds value

```
□ compiler >= 0.8            overflow reverts, for free
□ checks -> effects -> interactions, every time
□ who can call this?         access control on every state-changing function
□ zero-address checks on transfer and mint
□ an event on every state change, or your frontend is blind
□ don't write your own token — use OpenZeppelin
□ SafeERC20 when calling a token you did not write
□ `private` hides nothing. assume every value is public
□ at least one fuzz test
□ it is immutable. assume you get one shot
```
