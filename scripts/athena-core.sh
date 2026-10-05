#!/usr/bin/env bash
# Download and verify the A-route ARM64 OpenClash core for later image assembly.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out="$root/audit/openclash-core"
mkdir -p "$out"
rm -f "$out/core-pass.txt"
url=$(awk -F '\t' '$1=="binary:mihomo" {print $3}' "$root/config/source-candidates.tsv")
hash=$(awk -F '\t' '$1=="binary:mihomo" {print $4}' "$root/config/source-candidates.tsv")
[[ "$url" == https://github.com/MetaCubeX/mihomo/releases/download/*/mihomo-linux-arm64-*.gz ]]
[[ "$hash" =~ ^[0-9a-f]{64}$ ]]
archive="$out/mihomo.gz"
if [[ ! -f "$archive" ]] || [[ "$(sha256sum "$archive" | cut -d' ' -f1)" != "$hash" ]]; then
    curl --fail --silent --show-error --location --connect-timeout 20 --max-time 300 --retry 3 "$url" -o "$archive"
fi
printf '%s  %s\n' "$hash" "$archive" | sha256sum -c -
gzip -dc "$archive" > "$out/clash_meta"
# ELF magic, ELF64, little endian, and AArch64 e_machine (183).
[[ "$(od -An -tx1 -N6 "$out/clash_meta" | tr -d ' \n')" == 7f454c460201 ]]
[[ "$(od -An -tx1 -j18 -N2 "$out/clash_meta" | tr -d ' \n')" == b700 ]]
chmod 0755 "$out/clash_meta"
(cd "$out" && sha256sum mihomo.gz clash_meta) > "$out/SHA256SUMS"
printf '%s\n' 'PASS: Mihomo archive SHA256 and AArch64 ELF header verified.' \
    'NOT RUN: firmware installation or router execution.' | tee "$out/core-pass.txt"
