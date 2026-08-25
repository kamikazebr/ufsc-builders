#!/usr/bin/env bash
# Runs once, when the container is created.
set -euo pipefail

echo "▸ foundry"
curl -sL https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
foundryup

echo "▸ contracts"
git submodule update --init --recursive 2>/dev/null || {
  forge install foundry-rs/forge-std
  forge install OpenZeppelin/openzeppelin-contracts
}
forge build

echo "▸ subgraph toolchain"
corepack enable
(cd subgraph && pnpm install --ignore-scripts)

echo "▸ slither"
pipx install slither-analyzer || pip install --user slither-analyzer

cp -n .env.example .env 2>/dev/null || true

cat <<'DONE'

  ready.

    make help     every target, with a description
    make test     18 tests, three of them fuzzed
    make chisel   a Solidity prompt

  Put a THROWAWAY private key in .env before deploying anything.

DONE
