# Summarised from 1Hive/gardens-v2. The point of a Makefile here is that the
# commands you run at 2am are the same ones CI runs, and neither of you has to
# remember a flag.
-include .env
export

NETWORK ?= sepolia

# How to sign. Two ways, and the first one is better.
#
#   make wallet-import name=ufsc    # once. asks for the key, then a password.
#                                   # encrypted, in ~/.foundry/keystores/ufsc
#   make wallet-use name=ufsc       # writes ACCOUNT/SENDER into .env
#   make deploy                     # from here on it just works
#
# ACCOUNT and SENDER come from .env, so no target needs them on the command line.
# Deriving SENDER costs a password prompt, which is why it is stored once by
# `wallet-use` instead of being computed on every make invocation.
#
# With no ACCOUNT set, everything falls back to PRIVATE_KEY from .env — a raw
# key sitting in a file. Fine for a testnet key that never held money. Not fine
# for anything else. See docs/wallet.md.
ACCOUNT ?=
SENDER  ?=
SIGNER  := $(if $(ACCOUNT),--account $(ACCOUNT) --sender $(SENDER),--private-key $(PRIVATE_KEY))
DISPERSE ?= 0x0000000000000000000000000000000000000000
RPC     ?= $(SEPOLIA_RPC_URL)

.PHONY: wallet wallet-import wallet-use help install build test fmt cov chisel deploy registry pin drop fund addresses slither abi subgraph clean

wallet:          ## list the keystores foundry knows about
	@cast wallet list
	@echo ""
	@echo "in use: ACCOUNT=$(if $(ACCOUNT),$(ACCOUNT),<none - falling back to PRIVATE_KEY>) SENDER=$(SENDER)"

wallet-import:   ## store a private key encrypted   (make wallet-import name=ufsc)
	@test -n "$(name)" || (echo "usage: make wallet-import name=ufsc"; exit 1)
	cast wallet import $(name) --interactive
	@echo ""
	@echo "now: make wallet-use name=$(name)"

wallet-use:      ## point .env at that keystore   (make wallet-use name=ufsc)
	@test -n "$(name)" || (echo "usage: make wallet-use name=ufsc"; exit 1)
	@test -f .env || cp .env.example .env
	@addr=$$(cast wallet address --account $(name)) && \
	  sed -i -e "s|^ACCOUNT=.*|ACCOUNT=$(name)|" -e "s|^SENDER=.*|SENDER=$$addr|" .env && \
	  grep -q '^ACCOUNT=' .env || echo "ACCOUNT=$(name)" >> .env; \
	  grep -q '^SENDER=' .env || echo "SENDER=$$addr" >> .env; \
	  echo "ACCOUNT=$(name)"; echo "SENDER=$$addr"
	@echo "written to .env - make deploy / make drop now sign with it"

help:            ## show this
	@# firstword, not MAKEFILE_LIST: `-include .env` adds .env to that list, and
	@# grep across two files prefixes every line with the filename.
	@grep -E '^[a-z-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

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
		--rpc-url $(RPC) $(SIGNER) --broadcast --verify

pin:             ## pin assets/badge.png to IPFS via Pinata, print the CID
	@# Needs PINATA_JWT in .env. Free tier is 1 GB — see docs/pinata.md.
	@test -n "$(PINATA_JWT)" || (echo "set PINATA_JWT in .env - see docs/pinata.md"; exit 1)
	@curl -s -X POST https://uploads.pinata.cloud/v3/files \
		-H "Authorization: Bearer $(PINATA_JWT)" \
		-F "file=@assets/badge.png" -F "network=public" \
		-F "name=ufsc-builders-badge.png" \
		| grep -oE '"cid":"[^"]+"' | cut -d'"' -f4 \
		| sed 's/^/BADGE_CID=/'
	@echo "put that line in .env, then: make registry"

registry:        ## deploy the class registry ONCE (instructor only, needs BADGE_CID)
	NETWORK=$(NETWORK) forge script script/DeployRegistry.s.sol \
		--rpc-url $(RPC) $(SIGNER) --broadcast --verify

addresses:       ## pull every 0x address out of script/raw.txt, dedupe, write addresses.txt
	@# raw.txt and addresses.txt are gitignored — they hold other people's wallets.
	@[ -f script/raw.txt ] || cp script/raw.txt.example script/raw.txt
	@grep -oE '0[xX][a-fA-F0-9]{40}' script/raw.txt \
		| tr 'A-FX' 'a-fx' | sort -u > script/addresses.txt
	@echo "$$(wc -l < script/addresses.txt) unique addresses"

drop:            ## fund the whole room in ONE transaction (deploys Disperse if needed)
	DISPERSE=$(DISPERSE) forge script script/Drop.s.sol \
		--rpc-url $(RPC) $(SIGNER) --broadcast

fund:            ## same, but as N separate transactions — no contract needed
	forge script script/Fund.s.sol \
		--rpc-url $(RPC) $(SIGNER) --broadcast

slither:         ## static analysis in a container — findings triaged in SLITHER.md
	@# --fail-high: informational findings print but do not break the build.
	@# Every exclusion is justified in SLITHER.md — never silence one silently.
	@# The image keeps slither under /root (mode 700), so it has to run as root.
	@# FOUNDRY_OUT/FOUNDRY_CACHE_PATH send the build artefacts to the container's
	@# /tmp instead — without them root-owned out/ and cache/ land in your repo
	@# and the next `forge build` dies with EACCES.
	docker run --rm -v "$$PWD":/src -w /src \
		-e FOUNDRY_OUT=/tmp/fout -e FOUNDRY_CACHE_PATH=/tmp/fcache \
		trailofbits/eth-security-toolbox \
		slither . --exclude-dependencies --fail-high

subgraph:        ## codegen + build the subgraph
	cd subgraph && pnpm install && pnpm codegen && pnpm build

clean:
	forge clean && rm -rf subgraph/generated subgraph/build
