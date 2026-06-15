#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Running Noir tests"
nargo test

echo "==> Compiling circuits"
nargo compile --package common
nargo compile --package deposit
nargo compile --package transfer
nargo compile --package withdraw

echo "==> Generating Prover.toml files"
node scripts/compute-public-inputs.mjs

echo "==> All circuits ready"
