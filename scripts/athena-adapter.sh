#!/usr/bin/env bash
# Source after the author's stage definitions. Override fetching, not platform fixes.
# shellcheck disable=SC2034,SC2154
lock_file="${ATHENA_ROOT:?}/build.lock.tsv"
evidence="${ATHENA_ROOT:?}/artifacts"
mkdir -p "$evidence"

lock_revision() {
    awk -F '\t' -v repo="$1" '$2==repo && $1!="raw" && $1!="data-digest" && $1!~/^binary:/ {print $4}' "$lock_file"
}

git_retry() {
    if [[ "${1:-}" != clone ]]; then
        network_retry git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 "$@"
        return
    fi
    local args=("$@") url target repo revision sparse=false arg
    target=${args[${#args[@]}-1]}
    url=${args[${#args[@]}-2]}
    repo=${url#https://github.com/}; repo=${repo%.git}
    revision=$(lock_revision "$repo")
    [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || { echo "Unpinned repository: $repo" >&2; return 1; }
    target=$(realpath -m "$target")
    [[ "$target" == "$BUILD_DIR" || "$target" == "$BUILD_DIR/"* || "$target" == /tmp/tmp.* ]] || {
        echo 'Clone path outside disposable source/temp directories.' >&2; return 1;
    }
    [[ ! -d "$target" || -z "$(ls -A "$target")" ]] || { echo 'Clone target is not empty.' >&2; return 1; }
    for arg in "${args[@]}"; do
        [[ "$arg" != --sparse && "$arg" != --no-checkout ]] || sparse=true
    done
    git init -q "$target"
    git -C "$target" remote add origin "$url"
    git -C "$target" config remote.origin.promisor true
    git -C "$target" config remote.origin.partialclonefilter blob:none
    network_retry git -C "$target" fetch --depth=1 --filter=blob:none origin "$revision"
    [[ "$sparse" != true ]] || git -C "$target" sparse-checkout init --cone
    git -C "$target" checkout --detach --quiet FETCH_HEAD
    [[ "$(git -C "$target" rev-parse HEAD)" == "$revision" ]]
    printf '%s\t%s\n' "$repo" "$revision" >> "$evidence/clones.actual.tsv"
}

clone_repo() {
    git_retry clone "$REPO_URL" "$BUILD_DIR"
}

reset_feeds_conf() {
    [[ "$(git -C "$BUILD_DIR" rev-parse HEAD)" == "$COMMIT_HASH" ]]
    # Prepopulate the two author-added feeds; append_feed_if_missing then leaves them pinned.
    while IFS=$'\t' read -r kind repo ref revision; do
        case "$kind" in
            feed:*|native-feed:*) printf 'src-git %s https://github.com/%s.git^%s\n' "${kind#*:}" "$repo" "$revision" ;;
        esac
    done < "$lock_file" > "$BUILD_DIR/feeds.conf.default"
    cp "$BUILD_DIR/feeds.conf.default" "$evidence/feeds.locked.conf"
}

curl_retry() {
    local args=("$@") key='' url hash tmp dest='' index
    for ((index=0; index<${#args[@]}; index++)); do
        case "${args[index]}" in
            https://raw.githubusercontent.com/VIKINGYFY/immortalwrt/*/package/firmware/ath11k-firmware/Makefile) key=ath11k-Makefile ;;
            https://raw.githubusercontent.com/Openwrt-Passwall/openwrt-passwall-packages/*/tcping/Makefile) key=tcping-Makefile ;;
            https://gist.githubusercontent.com/puteulanus/1c180fae6bccd25e57eb6d30b7aa28aa/raw/*) key=quickstart-compat ;;
        esac
        [[ "${args[index]}" != -o ]] || dest=${args[index+1]}
    done
    [[ -n "$key" ]] || { echo 'Unpinned native raw download rejected.' >&2; return 1; }
    url=$(awk -F '\t' -v key="$key" '$1=="raw" && $2==key {print $3}' "$lock_file")
    hash=$(awk -F '\t' -v key="$key" '$1=="raw" && $2==key {print $4}' "$lock_file")
    [[ "$hash" =~ ^[0-9a-f]{64}$ ]]
    tmp=$(mktemp)
    network_retry curl --fail --silent --show-error --location --connect-timeout 20 --max-time 180 "$url" -o "$tmp"
    printf '%s  %s\n' "$hash" "$tmp" | sha256sum -c - >&2
    if [[ -n "$dest" ]]; then cp "$tmp" "$dest"; else cat "$tmp"; fi
    rm -- "$tmp"
    printf '%s\t%s\t%s\n' "$key" "$url" "$hash" >> "$evidence/raw.actual.tsv"
}

wget_retry() {
    local url=${*: -1} hash
    hash=$(awk -F '\t' -v url="$url" '$1=="data-digest" && $3==url {print $4}' "$lock_file")
    [[ "$hash" =~ ^[0-9a-f]{64}$ ]] || { echo 'Unpinned native data checksum rejected.' >&2; return 1; }
    # The author's geoip transformation consumes these fixed asset digests.
    printf '%s  %s\n' "$hash" "${url##*/}"
}
