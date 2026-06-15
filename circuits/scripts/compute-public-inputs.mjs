#!/usr/bin/env node
/**
 * Compute public inputs and write valid Prover.toml files for all circuits.
 * Uses @aztec/bb.js Poseidon2 (matches noir-lang/poseidon v0.3.0).
 */
import { writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";
import { BarretenbergSync, Fr } from "@aztec/bb.js";
import { Noir } from "@noir-lang/noir_js";
import { readFileSync } from "fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

const ZERO_PATH = Array(8).fill("0");
const FALSE_INDICES = Array(8).fill(false);

function toToml(data) {
  return (
    Object.entries(data)
      .map(([key, val]) => {
        if (Array.isArray(val)) {
          return `${key} = [${val.map((v) => (typeof v === "boolean" ? v : `"${v}"`)).join(", ")}]`;
        }
        return `${key} = "${val}"`;
      })
      .join("\n") + "\n"
  );
}

function frToDecimal(hexOrFr) {
  const s = hexOrFr.toString();
  if (s.startsWith("0x")) return BigInt(s).toString();
  return s;
}

async function main() {
  const api = await BarretenbergSync.initSingleton();
  const hash1 = (a) => api.poseidon2Hash([new Fr(BigInt(a))]);
  const hash2 = (a, b) =>
    api.poseidon2Hash([new Fr(BigInt(a)), new Fr(BigInt(b))]);
  const hash3 = (a, b, c) =>
    api.poseidon2Hash([
      new Fr(BigInt(a)),
      new Fr(BigInt(b)),
      new Fr(BigInt(c)),
    ]);

  const secret = 42n;
  const value = 1000n;
  const blinding = 7n;
  const recipient = 99n;
  const outBlinding = 13n;
  const recipientHash = 2748n;

  const pubkey = hash1(secret);
  const inputCommitment = hash3(pubkey, value, blinding);
  const nullifier = hash2(secret, inputCommitment);
  const outputCommitment = hash3(recipient, value, outBlinding);

  let merkleCurrent = inputCommitment;
  for (let i = 0; i < 8; i++) {
    merkleCurrent = hash2(merkleCurrent, 0n);
  }
  const merkleRoot = merkleCurrent;

  const depositToml = {
    secret_key: "42",
    amount: "1000",
    blinding: "7",
    commitment: frToDecimal(inputCommitment),
  };

  const transferToml = {
    secret_key: "42",
    input_value: "1000",
    input_blinding: "7",
    merkle_path: ZERO_PATH,
    merkle_indices: FALSE_INDICES,
    output_value: "1000",
    output_blinding: "13",
    recipient_pubkey: "99",
    merkle_root: frToDecimal(merkleRoot),
    nullifier: frToDecimal(nullifier),
    output_commitment: frToDecimal(outputCommitment),
  };

  const withdrawToml = {
    secret_key: "42",
    input_value: "1000",
    input_blinding: "7",
    merkle_path: ZERO_PATH,
    merkle_indices: FALSE_INDICES,
    merkle_root: frToDecimal(merkleRoot),
    nullifier: frToDecimal(nullifier),
    withdraw_amount: "1000",
    recipient_hash: "2748",
  };

  writeFileSync(join(ROOT, "deposit", "Prover.toml"), toToml(depositToml));
  writeFileSync(join(ROOT, "transfer", "Prover.toml"), toToml(transferToml));
  writeFileSync(join(ROOT, "withdraw", "Prover.toml"), toToml(withdrawToml));

  console.log("Wrote Prover.toml for deposit, transfer, withdraw");

  for (const pkg of ["deposit", "transfer", "withdraw"]) {
    execSync(`nargo compile --package ${pkg}`, { cwd: ROOT, stdio: "pipe" });
    const circuit = JSON.parse(
      readFileSync(join(ROOT, "target", `${pkg}.json`), "utf8")
    );
    const noir = new Noir(circuit);
    const inputs =
      pkg === "deposit"
        ? depositToml
        : pkg === "transfer"
          ? transferToml
          : withdrawToml;
    await noir.execute(inputs);
    execSync(`nargo execute --package ${pkg}`, { cwd: ROOT, stdio: "pipe" });
    console.log(`✓ ${pkg}: nargo execute succeeded`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
