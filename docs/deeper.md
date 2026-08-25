# One level down

A quarter of the room already deploys contracts for a living. This page is for
them — and for anyone who finishes the builds early and wants the part the
tutorials stop before.

There are a hundred free Solidity courses. Almost none go one level down. Knowing
what the import protects you from is the difference between writing contracts and
being trusted with them.

## Where the numbers actually live

**[Solidity Explicado: Overflow e Underflow](https://youtu.be/GnhLM8mHq8E)** — 16 min
Felipe Novaes Rocha · July 2024 · **in Portuguese**

Bits and bytes, and what a `uint256` really is. Subtract one from a balance of
zero before 0.8 and you land on `2²⁵⁶−1` — which was free money, and drained real
contracts. Since 0.8 the compiler inserts the check for you, and `unchecked`
gives it back when you know what you are doing.

This is item 4 on the OpenZeppelin list, told properly.

## Three lines that clone a contract

**[Como Apenas 3 Linhas de Solidity Clonam Seu Contrato](https://youtu.be/B0V3zoK9sxo)** — 9 min
Felipe Novaes Rocha · September 2024 · **in Portuguese**

EIP-1167, the minimal proxy. A contract whose entire body is a handful of
assembly that forwards every call somewhere else, so deploying the thousandth
copy costs almost nothing.

Two reasons it is worth nine minutes:

1. **It is a whole EIP you can read in one sitting.** Most are not like this.
   Go read it after: <https://eips.ethereum.org/EIPS/eip-1167>
2. **It is Yul.** Solidity compiles to Yul, Yul assembles to opcodes, and opcodes
   are where gas is actually metered. This is the shortest path from "I write
   Solidity" to "I know what the machine does".

## Keeping going

- **[eips.ethereum.org/all#last-call](https://eips.ethereum.org/all#last-call)** — the 14-day window before a proposal is Final. Short list, high signal, RSS available.
- `forge inspect <Contract> storageLayout --pretty` — the compiler tells you exactly which slot every variable landed in. Then read one with `cast storage`. That is how you find out that `private` was never about secrecy.
- `chisel` with `!fork` and `!fetch` — fork a live chain, pull a verified contract's interface, and call it from a prompt. See [chisel.md](chisel.md).
