# chisel — a Solidity REPL

`chisel` ships with Foundry. It is a Solidity prompt: type an expression, get
the answer. No file, no compile step, no deploy.

It is the fastest way to answer "wait, what does this actually return?" — and in
a hackathon you ask that forty times a day.

```bash
chisel
```

## The five things worth knowing

```solidity
// 1. Decimal math, before you send the wrong amount by a factor of 10^12
1 ether
// 1000000000000000000
uint256 amount = 25 * 10**6;   // USDC has 6 decimals, not 18
amount

// 2. What a function selector actually is
bytes4(keccak256("transfer(address,uint256)"))
// 0xa9059cbb

// 3. What your calldata looks like
abi.encodeWithSignature("register(string,address)", "my team", address(1))

// 4. Overflow behaviour, live
uint8 x = 255;
x + 1        // reverts — since 0.8 this check is free

// 5. Hashes and packing, the source of a whole class of bugs
keccak256(abi.encodePacked("a", "bc"))
keccak256(abi.encodePacked("ab", "c"))   // same hash. that is the bug.
```

## Session commands

```
!help    !h     every command
!source  !so    show the contract chisel is building behind your prompt
!clear   !c     wipe the session
!save    !s     save the session, !load to bring it back
!export  !ex    dump the session out as a Foundry script
!fork    !f <RPC>        run against real chain state
!fetch   !fe <ADDR> <NAME>   pull a verified contract's interface from Etherscan
!traces  !t     show call traces
```

`!fork` plus `!fetch` is the combination worth remembering: fork Sepolia, fetch a
deployed contract's interface, and call it from a prompt. No frontend, no
scripts, no deploy.

---

## Watch it being used

**[Aprenda a Usar Chisel do Foundry](https://www.youtube.com/watch?v=_sPuy0pGUmA)** — 20 min
Felipe Novaes Rocha · July 2024 · **in Portuguese**

Worked examples with rational and integer literals in Solidity — the exact place
where chisel earns its keep, because literal arithmetic is where you quietly send
the wrong amount.
