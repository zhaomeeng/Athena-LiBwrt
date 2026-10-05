#!/usr/bin/env bash
set -euo pipefail
root="${GITHUB_WORKSPACE:?}"
out="$root/artifacts"
stage=${ATHENA_STAGE:?}
[[ "$(pwd -P)" == /mnt/build_wrt ]]
case "$stage" in toolchain|rust|packages|images) ;; *) exit 1 ;; esac
rm -f "$out/compile-exit.txt"
export CCACHE_MAXSIZE=1G
before=$(sha256sum .config | cut -d' ' -f1)
available=$(df -Pk . | awk 'END {print $4}')
((available > 20 * 1024 * 1024)) || { echo 'Compilation needs 20 GiB free.' >&2; exit 1; }
# Four-hour compiler budget leaves two hours for startup and preserving the tree.
# Native include/package.mk supports AUTOREMOVE while retaining .pkgdir and stamps;
# unfinished packages retain their build trees. Pass the policy to make, not .config.
# The child expands the stage after timeout creates its process group.
# shellcheck disable=SC2016
setsid timeout --signal=TERM --kill-after=60s 240m bash -c '
    build_target() { make -j"$(nproc)" CONFIG_AUTOREMOVE=y "$@" || make -j1 V=s CONFIG_AUTOREMOVE=y "$@"; }
    case "$ATHENA_STAGE" in
        toolchain) build_target tools/install && build_target toolchain/install && build_target target/compile ;;
        rust) build_target package/feeds/packages/rust/host/compile ;;
        packages) build_target package/compile ;;
        images) build_target ;;
    esac
' &
compiler_pid=$!
monitor_pid=''
# shellcheck disable=SC2329
cleanup() {
    [[ -z "$monitor_pid" ]] || kill "$monitor_pid" 2>/dev/null || true
    [[ -z "$compiler_pid" ]] || kill -TERM -- "-$compiler_pid" 2>/dev/null || true
}
trap cleanup EXIT
(
    while kill -0 "$compiler_pid" 2>/dev/null; do
        build_free=$(df -Pk . | awk 'END {print $4}')
        root_free=$(df -Pk / | awk 'END {print $4}')
        printf '%s\tbuild_KiB=%s\troot_KiB=%s\n' "$(date -Is)" "$build_free" "$root_free" >> "$out/compile-space.tsv"
        if ((build_free < 3 * 1024 * 1024 || root_free < 3 * 1024 * 1024)); then
            echo 'Stopping to preserve diagnostics: less than 3 GiB free.' | tee "$out/disk-stop.txt" >&2
            kill -TERM -- "-$compiler_pid" 2>/dev/null || true
            exit 0
        fi
        sleep 60
    done
) &
monitor_pid=$!
status=0
wait "$compiler_pid" || status=$?
compiler_pid=''
kill "$monitor_pid" 2>/dev/null || true
wait "$monitor_pid" 2>/dev/null || true
monitor_pid=''
[[ "$before" == "$(sha256sum .config | cut -d' ' -f1)" ]]
printf '%s\n' "$status" > "$out/compile-exit.txt"
df -h / . > "$out/compile-space-after.txt"
exit "$status"
