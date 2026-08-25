# Summarised from 1Hive/gardens-v2. The point of a Makefile here is that the
# commands you run at 2am are the same ones CI runs, and neither of you has to
# remember a flag.
-include .env
export

NETWORK ?= sepolia
DISPERSE ?= 0x0000000000000000000000000000000000000000
RPC     ?= $(SEPOLIA_RPC_URL)

.PHONY: help install build test fmt cov chisel deploy drop fund addresses slither abi subgraph clean

help:            ## show this
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install:         ## fetch dependencies (safe to re-run)
	@# Dependencies are git submodules, same as 1Hive/gardens-v2. That makes
	@# this idempotent for free — and it is why `git clone --recursive` is the
	@# right way to clone. Cloned without it? This fixes it.
	@if [ -f .gitmodules ]; then \
	  git submodule update --init --recursive; \
	else \
	  forge install foundry-rs/forge-std; \
	  forge install OpenZeppelin/openzeppelin-contracts; \
	fi
	@echo "dependencies ready"

build:           ## compile, and show contract sizes
	forge build --sizes

test:            ## run the suite, verbose
	forge test -vvv

fmt:             ## format every .sol
	forge fmt

cov:             ## coverage report
	forge coverage --report summary

chisel:          ## open the Solidity REPL
	chisel

abi:             ## regenerate the subgraph ABI from the build — never hand-edit it
	forge inspect src/UFSCBuilders.sol:UFSCBuilders abi --json > subgraph/abis/UFSCBuilders.json
	@echo "wrote subgraph/abis/UFSCBuilders.json"

deploy:          ## deploy Token + Badge   (NETWORK=sepolia make deploy)
	NETWORK=$(NETWORK) forge script script/Deploy.s.sol \
		--rpc-url $(RPC) --private-key $(PRIVATE_KEY) --broadcast --verify

addresses:       ## pull every 0x address out of script/raw.txt, dedupe, write addresses.txt
	@grep -oE '0[xX][a-fA-F0-9]{40}' script/raw.txt \
		| tr 'A-FX' 'a-fx' | sort -u > script/addresses.txt
	@echo "$$(wc -l < script/addresses.txt) unique addresses"

drop:            ## fund the whole room in ONE transaction (deploys Disperse if needed)
	DISPERSE=$(DISPERSE) forge script script/Drop.s.sol \
		--rpc-url $(RPC) --private-key $(PRIVATE_KEY) --broadcast

fund:            ## same, but as N separate transactions — no contract needed
	forge script script/Fund.s.sol \
		--rpc-url $(RPC) --private-key $(PRIVATE_KEY) --broadcast

slither:         ## static analysis in a container — findings triaged in SLITHER.md
	@# --fail-on high: informational findings print but do not break the build.
	@# Every exclusion is justified in SLITHER.md — never silence one silently.
	@# --user: without it the container runs as root and leaves root-owned
	@# out/ and cache/ behind, and the next `forge build` dies with EACCES.
	docker run --rm --user $$(id -u):$$(id -g) -v "$$PWD":/src \
		trailofbits/eth-security-toolbox \
		slither /src --exclude-dependencies --fail-on high

subgraph:        ## codegen + build the subgraph
	cd subgraph && pnpm install && pnpm codegen && pnpm build

clean:
	forge clean && rm -rf subgraph/generated subgraph/build
