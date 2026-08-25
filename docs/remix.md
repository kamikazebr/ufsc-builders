# Remix — no install, and it is not a toy

Everything in `src/` runs in [remix.ethereum.org](https://remix.ethereum.org)
with nothing installed. Paste the file, compile with **0.8.24**, deploy.

Remix resolves `@openzeppelin/...` straight from npm. There is no setup step.

## Deploying

1. **Solidity Compiler** → version `0.8.24` → Compile
2. **Deploy & Run** → Environment: `Injected Provider – Rabby`
3. Network in Rabby: **Sepolia**
4. Fill the constructor arguments → **Deploy**

## The move that matters: `At Address`

Below the Deploy button there is a field marked **At Address**. That attaches
Remix to a contract *someone else already deployed* and gives you a working UI
for it.

Deploying your own contract is the easy half. Attaching to somebody else's and
calling it is what integration actually is — and it is most of what a hackathon
rewards.

Try it: paste `UFSCBuilders.sol`, compile, then **At Address** with the class
registry, and call `register`.

## Remix or Foundry?

|                          | Remix | Foundry |
| ------------------------ | ----- | ------- |
| Install                  | none  | one command, then a toolchain |
| Write a contract         | fine  | fine |
| Deploy once              | fine  | fine |
| **Tests**                | painful | the reason it exists |
| **Fuzzing / invariants** | no    | built in |
| Scripted, repeatable deploys | no | yes |
| Works on a locked-down laptop | yes | sometimes |

Use Remix to *learn* and to poke at a deployed contract. Use Foundry the moment
the thing holds value, because that is when you need tests you can re-run.

They are not rivals. Most people who use Foundry every day still open Remix to
inspect somebody else's contract.
