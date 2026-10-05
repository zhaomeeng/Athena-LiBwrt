#!/usr/bin/env bash
set -euo pipefail
root="${GITHUB_WORKSPACE:?}"
out="$root/artifacts"
[[ "$(pwd -P)" == /mnt/build_wrt ]]
cp "$root/audit/config-preview/baseline.input.config" .config
make defconfig
cp .config "$out/baseline.config"
cp "$root/audit/config-preview/custom.input.config" .config
make defconfig
cp .config "$out/final.config"

# Preserve platform/core configuration. New ordinary app dependencies are resolved
# by native Kconfig; no explicit driver/target/firmware overrides are accepted.
protected='^CONFIG_(TARGET|LINUX|KERNEL|NSS|ATH11K|IPQ|QCA|MAC80211|PACKAGE_(MAC80211_MESH|kmod-(qca|ath|usb|mmc|sdhci|phy|mdio)|ath11k-firmware|ipq-wifi|nss-|firewall|fullconenat|block-mount|fstools|mmc-utils|cpufreq))'
normalize_protected() {
    sed -E 's/^# (CONFIG_[^ ]+) is not set$/\1=n/' "$1" | grep -E "$protected" | LC_ALL=C sort
}
normalize_protected "$out/baseline.config" > "$out/baseline.protected.config"
normalize_protected "$out/final.config" > "$out/final.protected.config"
diff -u "$out/baseline.protected.config" "$out/final.protected.config" > "$out/protected.diff" || {
    cat "$out/protected.diff"; echo 'Protected platform config changed; stop.' >&2; exit 1;
}
diff -u "$out/baseline.config" "$out/final.config" > "$out/application.diff" || {
    status=$?; [[ "$status" == 1 ]] || exit "$status";
}
required=(luci luci-app-firewall luci-app-package-manager luci-app-openclash
    luci-theme-aurora luci-app-aurora-config docker dockerd containerd runc
    luci-app-dockerman luci-app-autoreboot luci-app-emmc-health luci-app-lucky
    luci-app-ttyd luci-app-upnp luci-app-wol luci-app-diskman luci-app-samba4
    block-mount fstools kmod-usb-storage kmod-qca-nss-drv kmod-qca-nss-ecm
    dnsmasq-full)
for name in "${required[@]}"; do
    grep -qx "CONFIG_PACKAGE_$name=y" .config || { echo "Required package absent: $name" >&2; exit 1; }
done
excluded=(luci-app-passwall luci-app-passwall2 xray-core sing-box rust
    shadowsocks-rust-sslocal shadowsocks-rust-ssserver shadowsocks-rust-ssmanager
    shadowsocks-rust-ssservice shadowsocks-rust-ssurl shadowsocksr-libev-ssr-local simple-obfs-client v2ray-plugin
    luci-app-adguardhome adguardhome luci-app-mosdns mosdns
    luci-app-smartdns smartdns luci-app-easytier easytier luci-app-oaf oaf open-app-filter appfilter kmod-oaf
    luci-app-pbr pbr luci-app-sqm sqm-scripts sqm-scripts-nss luci-app-vlmcsd vlmcsd
    luci-app-quickstart quickstart luci-app-store luci-app-istorex luci-app-quickfile
    luci-app-homeproxy luci-app-ssr-plus luci-app-nikki nikki mihomo-meta luci-app-attendedsysupgrade)
for name in "${excluded[@]}"; do
    if grep -Eq "^CONFIG_PACKAGE_$name=[ym]$" .config; then
        echo "Excluded package selected: $name" >&2; exit 1
    fi
done
awk '
    FNR==NR {
        if ($0 ~ /^CONFIG_PACKAGE_.*=[ym]$/) {
            name=$0; sub(/^CONFIG_PACKAGE_/, "", name); sub(/=[ym]$/, "", name); selected[name]=1
        }
        next
    }
    function flush( i) {
        if (uses_rust) for (i=1; i<=count; i++)
            if (selected[names[i]]) print source "\t" names[i]
    }
    /^Source-Makefile:/ {flush(); source=$2; count=0; uses_rust=0}
    /^Package:/ {names[++count]=$2}
    /rust\/host/ {uses_rust=1}
    END {flush()}
' .config tmp/.packageinfo > "$out/selected-rust-consumers.txt"
[[ ! -s "$out/selected-rust-consumers.txt" ]] || {
    cat "$out/selected-rust-consumers.txt"; echo 'Selected package still depends on Rust host.' >&2; exit 1;
}
gzip -c tmp/.packageinfo > "$out/packageinfo.gz"
grep -qx 'CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=y' .config
for name in kmod-ath11k kmod-ath11k-pci ath11k-firmware-qcn9074-ddwrt luci-app-athena-led; do
    grep -Eq "^CONFIG_PACKAGE_$name=[ym]$" .config
done
grep '^CONFIG_TARGET_DEVICE_PACKAGES_.*DEVICE_jdcloud_re-cs-02=' .config |
    grep -q 'ath11k-firmware-qcn9074-ddwrt kmod-ath11k-pci luci-app-athena-led'
[[ -x files/etc/openclash/core/clash_meta && -x files/etc/uci-defaults/zz-athena-services ]]
printf '%s\n' 'PASS: native platform and protected config unchanged; required applications selected; exclusions satisfied.' \
    | tee "$out/preflight.txt"
sha256sum .config > "$out/final-config.sha256"
