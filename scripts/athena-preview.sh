#!/usr/bin/env bash
# Local input preview only. This does not run feeds, make defconfig or compilation.
set -euo pipefail
export LC_ALL=C
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
device=jdcloud_ipq60xx_libwrt
out="$root/audit/config-preview"
mkdir -p "$out"
rm -f "$out/preview-pass.txt"

# Fail rather than silently preview a different native configuration/stage order.
framework=$(awk -F '\t' '$1=="framework" {print $4}' config/source-candidates.tsv)
[[ "$framework" =~ ^[0-9a-f]{40}$ ]]
git diff --exit-code "$framework" -- build.sh wrt_core > "$out/native-source.diff"
[[ -z "${ADD_CONFIG_FRAGMENTS:-}" && -z "${REMOVE_CONFIG_FRAGMENTS:-}" ]] || {
    echo 'Fragment overrides are unsupported in the A-route preview.' >&2
    exit 1
}
ini="$root/wrt_core/compilecfg/$device.ini"
fragments=$(awk -F= '$1=="CONFIG_FRAGMENTS" {gsub(/\r/, "", $2); print $2}' "$ini")
[[ "$fragments" == nss,docker_deps,proxy ]]
bash build.sh "$device" config_preview > "$out/native-preview.txt"

inputs=("wrt_core/deconfig/$device.config" wrt_core/deconfig/compile_base.config)
IFS=',' read -r -a fragment_names <<< "$fragments"
for name in "${fragment_names[@]}"; do
    inputs+=("wrt_core/deconfig/fragments/$name.config")
done
# Hash committed blobs, so Windows CRLF checkout conversion cannot change evidence.
for path in "${inputs[@]}" build.sh wrt_core/update.sh; do
    hash=$(git show "$framework:$path" | sha256sum | cut -d' ' -f1)
    printf '%s  %s\n' "$hash" "$path"
done > "$out/native-inputs.sha256"

# OpenWrt inputs may repeat keys across fragments. Keep the final assignment.
normalize() {
    awk '
        {sub(/\r$/, "")}
        /^CONFIG_[^=]+=/ {key=$0; sub(/=.*/, "", key); values[key]=$0}
        /^# CONFIG_[^ ]+ is not set$/ {
            key=$2; values[key]=key "=n"
        }
        END {for (key in values) print values[key]}
    ' "$@" | sort
}
normalize "${inputs[@]}" > "$out/baseline.input.config"

# The overlay is limited to package selections; driver/kernel/target keys fail.
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" =~ ^CONFIG_PACKAGE_[a-zA-Z0-9_-]+=[ynm]$ ]] || {
        echo "Invalid application overlay line: $line" >&2; exit 1;
    }
    key=${line%%=*}
    name=${key#CONFIG_PACKAGE_}
    case "$name" in
        luci|luci-app-*|luci-theme-*|luci-lib-taskd|docker|dockerd|containerd|runc|\
        adguardhome|mosdns|smartdns|easytier|oaf|open-app-filter|pbr|sqm-scripts|\
        sqm-scripts-nss|vlmcsd|quickstart|taskd|nikki|mihomo-meta) ;;
        *) echo "Package outside the authorized application overlay: $name" >&2; exit 1 ;;
    esac
done < config/athena-apps.config
normalize "$out/baseline.input.config" config/athena-apps.config > "$out/custom.input.config"

protected='^CONFIG_(TARGET|LINUX|KERNEL|NSS|ATH11K|IPQ|QCA|MAC80211|PACKAGE_(kmod-|ath11k-firmware|ipq-wifi|nss-|firewall|fullconenat|nftables|iptables|ip6tables|mmc-utils|cpufreq))'
grep -E "$protected" "$out/baseline.input.config" > "$out/baseline.protected.config"
grep -E "$protected" "$out/custom.input.config" > "$out/custom.protected.config"
diff -u "$out/baseline.protected.config" "$out/custom.protected.config" > "$out/protected.diff"
diff -u "$out/baseline.input.config" "$out/custom.input.config" > "$out/application.diff" || {
    result=$?; [[ "$result" == 1 ]] || exit "$result";
}

required=(luci luci-app-firewall luci-app-package-manager luci-app-openclash
    luci-app-passwall2 luci-theme-aurora luci-app-aurora-config
    docker dockerd containerd runc luci-app-dockerman luci-app-autoreboot
    luci-app-emmc-health luci-app-lucky luci-app-ttyd luci-app-upnp
    luci-app-wol luci-app-diskman luci-app-samba4 kmod-usb-storage)
for name in "${required[@]}"; do
    grep -qx "CONFIG_PACKAGE_$name=y" "$out/custom.input.config"
done
excluded=(passwall adguardhome mosdns smartdns easytier oaf pbr sqm vlmcsd
    quickstart store istorex quickfile homeproxy ssr-plus nikki momo attendedsysupgrade)
for name in "${excluded[@]}"; do
    grep -qx "CONFIG_PACKAGE_luci-app-$name=n" "$out/custom.input.config"
done
grep -qx 'CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=y' "$out/custom.input.config"
grep -qx 'CONFIG_PACKAGE_ath11k-firmware-qcn9074-ddwrt=m' "$out/custom.input.config"
grep -qx 'CONFIG_PACKAGE_luci-app-athena-led=m' "$out/custom.input.config"
grep '^CONFIG_TARGET_DEVICE_PACKAGES_.*DEVICE_jdcloud_re-cs-02=' "$out/custom.input.config" |
    grep -q 'ath11k-firmware-qcn9074-ddwrt kmod-ath11k-pci luci-app-athena-led'
sha256sum "$out/baseline.input.config" "$out/custom.input.config" > "$out/config-inputs.sha256"
printf '%s\n' 'PASS: native inputs unchanged; application selections assembled; protected input diff empty.' \
    'NOT RUN: source/feed preparation, make defconfig, compilation, boot/runtime tests.' |
    tee "$out/preview-pass.txt"
