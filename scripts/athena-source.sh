#!/usr/bin/env bash
set -euo pipefail
root="${GITHUB_WORKSPACE:?}"
export ATHENA_ROOT="$root"
tree=/mnt/build_wrt
[[ "${GITHUB_ACTIONS:-}" == true && "${RUNNER_OS:-}" == Linux ]]
[[ -d "$tree" && -z "$(ls -A "$tree")" ]]
mkdir -p "$root/artifacts" "$root/audit"
bash "$root/scripts/athena-preview.sh"
source_sha=$(awk -F '\t' '$1=="source" {print $4}' "$root/build.lock.tsv")
framework=$(awk -F '\t' '$1=="framework" {print $4}' "$root/build.lock.tsv")
git -C "$root" diff --exit-code "$framework" -- build.sh wrt_core > "$root/artifacts/native-source.diff"
[[ "$source_sha" =~ ^[0-9a-f]{40}$ ]]

# Keep all author modules and stage bodies unchanged. Only the disposable entry copy
# uses the actual framework directory and defers main until the fetch adapter is loaded.
[[ $(grep -c '^main "\$@"$' "$root/wrt_core/update.sh") == 1 ]]
# The generated entry expands ATHENA_ROOT in the child, not while generating it.
# shellcheck disable=SC2016
sed 's|^SCRIPT_DIR=.*|SCRIPT_DIR="${ATHENA_ROOT:?}/wrt_core"|; /^main "\$@"$/d' \
    "$root/wrt_core/update.sh" > "$root/audit/update.entry.sh"
sha256sum "$root/audit/update.entry.sh" > "$root/artifacts/native-entry.sha256"
# Source functions are consumed by the author stage dispatcher in the child shell.
# shellcheck disable=SC2016
bash -c 'source "$ATHENA_ROOT/audit/update.entry.sh"; source "$ATHENA_ROOT/scripts/athena-adapter.sh"; main "$@"' \
    "$root/wrt_core/update.sh" https://github.com/LiBwrt/openwrt-6.x.git 25.12-nss "$tree" "$source_sha"

cd "$tree"
git diff --binary -- target/linux package/kernel package/firmware include/netfilter.mk \
    > "$root/artifacts/native-platform.patch"
sha256sum "$root/artifacts/native-platform.patch" > "$root/artifacts/native-platform.sha256"

# Retain original application definitions for an honest native baseline defconfig.
# Excluded apps are disabled in the final config, not removed from the baseline source catalog.
# Load only the author's package-sync helpers and our fixed-revision fetch implementation.
BUILD_DIR="$tree"
export BUILD_DIR
# shellcheck source=/dev/null
source "$root/wrt_core/modules/network.sh"
# shellcheck source=/dev/null
source "$root/wrt_core/modules/custom_feed.sh"
# shellcheck source=scripts/athena-adapter.sh
source "$root/scripts/athena-adapter.sh"
custom="$tree/custom_feed"
sync_sparse_packages_to_feed_dir https://github.com/vernesong/OpenClash.git master "$custom" OpenClash luci-app-openclash
sync_repo_root_package_to_feed_dir https://github.com/eamonxg/luci-theme-aurora.git master "$custom" Aurora luci-theme-aurora
sync_repo_root_package_to_feed_dir https://github.com/eamonxg/luci-app-aurora-config.git master "$custom" AuroraConfig luci-app-aurora-config
for path in feeds/luci/applications/luci-app-openclash feeds/luci/applications/luci-app-passwall2 \
    feeds/luci/themes/luci-theme-aurora feeds/luci/applications/luci-app-aurora-config; do
    [[ ! -d "$path" ]] || rm -rf -- "$path"
done
./scripts/feeds update -i
./scripts/feeds install -a -f

git diff --binary -- target/linux package/kernel package/firmware include/netfilter.mk \
    > "$root/artifacts/custom-platform.patch"
cmp "$root/artifacts/native-platform.patch" "$root/artifacts/custom-platform.patch"

# Verify the actual feed Git heads, including nested Go replacement independently.
while IFS=$'\t' read -r kind _repo _ref revision; do
    case "$kind" in
        feed:*|native-feed:*)
            name=${kind#*:}
            actual=$(git -C "feeds/$name" rev-parse HEAD)
            [[ "$actual" == "$revision" ]]
            printf '%s\t%s\n' "$name" "$actual" ;;
    esac
done < "$root/build.lock.tsv" > "$root/artifacts/feeds.actual.tsv"
cp "$root/build.lock.tsv" "$root/artifacts/build.lock.tsv"
git rev-parse HEAD > "$root/artifacts/source-commit.txt"
git -C "$root" rev-parse HEAD > "$root/artifacts/framework-commit.txt"
bash "$root/scripts/athena-core.sh"
install -Dm755 "$root/audit/openclash-core/clash_meta" files/etc/openclash/core/clash_meta
install -Dm755 "$root/files/etc/uci-defaults/zz-athena-services" files/etc/uci-defaults/zz-athena-services
cp "$root/audit/openclash-core/SHA256SUMS" "$root/artifacts/core.SHA256SUMS"
bash "$root/scripts/athena-defconfig.sh"
