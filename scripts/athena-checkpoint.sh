#!/usr/bin/env bash
set -euo pipefail
root="${GITHUB_WORKSPACE:?}"
out="$root/artifacts"
mode=${1:?save or restore}
stage=${2:?checkpoint stage}
case "$stage" in prepare|toolchain|packages|images) ;; *) exit 1 ;; esac
[[ "$(pwd -P)" == /mnt/build_wrt ]]
input_hash() {
    (cd "$root"; sha256sum build.lock.tsv config/athena-apps.config scripts/athena-{preview,adapter,source,defconfig,core}.sh \
        files/etc/uci-defaults/zz-athena-services; git ls-tree -r HEAD wrt_core build.sh) | sha256sum | cut -d' ' -f1
}
case "$mode" in
    save)
        complete=true
        if [[ "$stage" != prepare && "${ATHENA_PREVIEW:?}" != true ]]; then
            status=$(cat "$out/compile-exit.txt")
            case "$status" in 0) ;; 124) complete=false ;; *) echo 'Compiler failure cannot be checkpointed.' >&2; exit 1 ;; esac
        fi
        dest="$root/checkpoint-upload"
        mkdir -p "$dest" .athena-evidence
        cp -a "$out/." .athena-evidence/
        input_hash > "$dest/inputs.sha256"
        sha256sum .config | cut -d' ' -f1 > "$dest/config.sha256"
        git rev-parse HEAD > "$dest/source.txt"
        printf '%s\n' "$stage" > "$dest/stage.txt"
        printf '%s\n' "$complete" > "$dest/complete.txt"
        printf '%s\n' "${ATHENA_PREVIEW:?}" > "$dest/preview.txt"
        printf '%s\n' "${GITHUB_RUN_ID:?}" > "$dest/run.txt"
        printf '%s\n' "$(uname -m)" > "$dest/arch.txt"
        du -sk . | awk '{print $1}' > "$dest/unpacked-KiB.txt"
        while IFS= read -r -d '' cfg; do
            if grep -Eiq '(extraheader|credential|https?://[^/[:space:]]+@)' "$cfg"; then
                echo 'Authentication configuration in source checkout; checkpoint rejected.' >&2; exit 1
            fi
        done < <(find . -path '*/.git/config' -type f -print0)
        available=$(df -Pk . | awk 'END {print $4}')
        ((available > 3 * 1024 * 1024))
        (ulimit -f "$((available - 3 * 1024 * 1024))"; tar --exclude='./key-build*' \
            --use-compress-program='zstd -T2 -3' -cf "$dest/tree.tar.zst" .)
        (cd "$dest"; sha256sum tree.tar.zst > SHA256SUMS)
        du -sh "$dest/tree.tar.zst" | tee "$out/checkpoint-size.txt"
        ;;
    restore)
        src="$root/checkpoint-download"
        [[ -z "$(ls -A .)" ]]
        [[ "$(cat "$src/stage.txt")" == "$stage" ]]
        [[ "$(cat "$src/complete.txt")" == true || "$stage" == "${ATHENA_STAGE:?}" ]]
        [[ "$(cat "$src/preview.txt")" == "${ATHENA_PREVIEW:?}" ]]
        [[ "$(cat "$src/run.txt")" == "${GITHUB_RUN_ID:?}" ]]
        [[ "$(cat "$src/arch.txt")" == "$(uname -m)" ]]
        [[ "$(cat "$src/inputs.sha256")" == "$(input_hash)" ]]
        source_sha=$(awk -F '\t' '$1=="source" {print $4}' "$root/build.lock.tsv")
        [[ "$(cat "$src/source.txt")" == "$source_sha" ]]
        (cd "$src"; sha256sum -c SHA256SUMS)
        available=$(df -Pk . | awk 'END {print $4}')
        unpacked=$(cat "$src/unpacked-KiB.txt")
        [[ "$unpacked" =~ ^[0-9]+$ ]]
        ((available > unpacked + 3 * 1024 * 1024))
        tar --use-compress-program=zstd -xf "$src/tree.tar.zst"
        [[ "$(git rev-parse HEAD)" == "$source_sha" ]]
        [[ "$(sha256sum .config | cut -d' ' -f1)" == "$(cat "$src/config.sha256")" ]]
        cmp .config .athena-evidence/final.config
        [[ ! -s .athena-evidence/protected.diff ]]
        grep -qx 'PASS: native platform and protected config unchanged; required applications selected; exclusions satisfied.' \
            .athena-evidence/preflight.txt
        [[ -x files/etc/uci-defaults/zz-athena-services && -x files/etc/openclash/core/clash_meta ]]
        [[ -L package/feeds/luci/luci-app-firewall && -f package/feeds/luci/luci-app-firewall/Makefile ]]
        mv "$out/runner-space.txt" "$out/runner-space-${ATHENA_STAGE}.txt"
        cp -a .athena-evidence/. "$out/"
        rm -- "$src/tree.tar.zst"
        printf 'PASS: %s checkpoint source/config/input hash/modes/symlinks restored.\n' "$stage" | tee "$out/restore-${ATHENA_STAGE}.txt"
        ;;
    *) exit 1 ;;
esac
