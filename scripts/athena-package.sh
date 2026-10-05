#!/usr/bin/env bash
set -euo pipefail
root="${GITHUB_WORKSPACE:?}"
out="$root/artifacts"
target=bin/targets/qualcommax/ipq60xx
[[ "$(pwd -P)" == /mnt/build_wrt ]]
mkdir -p upload
for format in factory sysupgrade; do
    mapfile -t images < <(find "$target" -maxdepth 1 -type f -name "*jdcloud_re-cs-02*${format}*")
    [[ ${#images[@]} == 1 ]] || { echo "Expected one Athena $format image." >&2; exit 1; }
    cp "${images[0]}" upload/
    [[ "$format" != factory ]] || factory_image=${images[0]}
done
unsquashfs_bin="$PWD/staging_dir/host/bin/unsquashfs4"
[[ -x "$unsquashfs_bin" ]]
# This route's original RE-CS-02 image uses KERNEL_SIZE=6144k.
"$unsquashfs_bin" -o 6291456 -ll "$factory_image" > "$out/athena-rootfs.txt"
for path in lib/firmware/ath11k/QCN9074/hw1.0/amss.bin lib/firmware/IPQ6018/amss.bin \
    etc/openclash/core/clash_meta etc/init.d/passwall2 etc/init.d/openclash \
    etc/uci-defaults/zz-athena-services usr/bin/docker usr/bin/dockerd usr/sbin/athena-led; do
    grep -Fq "$path" "$out/athena-rootfs.txt" || { echo "Athena rootfs missing: $path" >&2; exit 1; }
done
"$unsquashfs_bin" -o 6291456 -cat "$factory_image" etc/uci-defaults/zz-athena-services > "$out/services.rootfs.sh"
cmp "$root/files/etc/uci-defaults/zz-athena-services" "$out/services.rootfs.sh"
"$unsquashfs_bin" -o 6291456 -cat "$factory_image" etc/openclash/core/clash_meta > "$out/core.rootfs"
cmp files/etc/openclash/core/clash_meta "$out/core.rootfs"
rm -- "$out/core.rootfs"
"$unsquashfs_bin" -o 6291456 -cat "$factory_image" usr/lib/opkg/status > "$out/athena-packages.db"
for name in luci-app-openclash luci-app-passwall2 luci-theme-aurora luci-app-aurora-config docker dockerd \
    luci-app-athena-led ath11k-firmware-qcn9074-ddwrt block-mount; do
    grep -qx "Package: $name" "$out/athena-packages.db" || { echo "Athena image missing package: $name" >&2; exit 1; }
done
for name in luci-app-passwall luci-app-homeproxy luci-app-adguardhome luci-app-mosdns luci-app-smartdns \
    luci-app-easytier luci-app-oaf luci-app-pbr luci-app-sqm luci-app-vlmcsd luci-app-store \
    luci-app-istorex luci-app-quickstart luci-app-quickfile luci-app-attendedsysupgrade; do
    if grep -qx "Package: $name" "$out/athena-packages.db"; then echo "Excluded image package: $name" >&2; exit 1; fi
done
cp "$out"/* upload/
cp .config upload/final.config
find "$target" -maxdepth 1 -type f \( -name '*.manifest' -o -name '*buildinfo' -o -name profiles.json \) -exec cp {} upload/ \;
tar -czf upload/packages.tar.gz bin/packages "$target/packages"
cat > upload/RELEASE.md <<EOF
# 雅典娜 A 版 / LiBwrt

框架：$GITHUB_SHA
源码：LiBwrt/openwrt-6.x / $(git rev-parse HEAD)
构建：$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID

作者原生处理后的平台/保护配置比较通过。首次启动两个代理及 Docker 关闭。
下载后使用 SHA256SUMS 校验；实机启动、NSS、有线与 Wi-Fi 80/160MHz 稳定性尚待验证。
EOF
(cd upload; find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%P\0' | LC_ALL=C sort -z | xargs -0 sha256sum > "$out/release.SHA256SUMS")
mv "$out/release.SHA256SUMS" upload/SHA256SUMS
