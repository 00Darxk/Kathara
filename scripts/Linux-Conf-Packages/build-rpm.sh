#!/usr/bin/env bash
# ============================================================================
# build-rpm.sh <fedora-release>
# Builds kathara-release-<CONF_VERSION>-<PACKAGE_VERSION>.fc<release>.noarch.rpm into Output/.
#
# The package carries the public key bundle (package key + metadata key) and the repository definition.
# The .repo file is release-independent (it uses $releasever), but one package is still built per dist tag so that it flows through the existing per-releasever machinery with no special cases.
#
# No Fedora container is needed: the package is noarch, contains no compiled code, and the dist tag is set explicitly with --define "dist .fcNN". rpmbuild is available from the standard Ubuntu repositories (package `rpm`).
#
# The resulting .rpm MUST then pass through the rpm-sign job like every other package: dnf with gpgcheck=1 would refuse it unsigned.
# ============================================================================
set -euo pipefail

REL="${1:?usage: build-rpm.sh <fedora-release>}"
[[ "$REL" =~ ^[0-9]+$ ]] || { echo "Invalid Fedora release: $REL" >&2; exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

: "${CONF_VERSION:?}" "${PACKAGE_VERSION:?}" "${REPO_URL:?}" "${RPM_SUBDIR:?}"
: "${KEY_FILE_NAME:?}" "${REPO_ID:?}"

PKG_KEY="keys/kathara-package-key.asc"
META_KEY="keys/kathara-metadata-key.asc"
for k in "$PKG_KEY" "$META_KEY"; do
    [ -s "$k" ] || { echo "ERROR: $k is missing or empty (see keys/README.md)" >&2; exit 1; }
done

command -v rpmbuild >/dev/null 2>&1 || {
    echo "ERROR: rpmbuild not found (on Ubuntu: apt-get install rpm)" >&2; exit 1; }

OUT="$PWD/Output"
TOP="$(mktemp -d)"
trap 'rm -rf "$TOP"' EXIT INT TERM
mkdir -p "$OUT" "$TOP/SOURCES" "$TOP/SPECS"

# --- Sources ----------------------------------------------------------------
# The key bundle: one file, two armored blocks. rpm/dnf import every block they find.
# Identical in content to the bundle served at the site root.
{
    cat "$PKG_KEY"
    echo
    cat "$META_KEY"
} > "$TOP/SOURCES/$KEY_FILE_NAME"

# The installed repo definition points at the LOCALLY installed key (file:///etc/pki/rpm-gpg/…): after bootstrap the key arrives and rotates via this very package, not via the network.
cat > "$TOP/SOURCES/$REPO_ID.repo" <<EOF
[$REPO_ID]
name=Kathara \$releasever - \$basearch
baseurl=$REPO_URL/$RPM_SUBDIR/fedora/\$releasever/\$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/$KEY_FILE_NAME
metadata_expire=6h
skip_if_unavailable=False
EOF

sed -e "s|__VERSION__|$CONF_VERSION|g" \
    -e "s|__PACKAGE_VERSION__|$PACKAGE_VERSION|g" \
    -e "s|__KEY_FILE_NAME__|$KEY_FILE_NAME|g" \
    -e "s|__REPO_ID__|$REPO_ID|g" \
    -e "s|__DATE__|$(date +'%a %b %d %Y')|g" \
    rpm/kathara-release.spec.in > "$TOP/SPECS/kathara-release.spec"

# --- Build ------------------------------------------------------------------
# Reproducible output, for the same reason as the .deb: the same version must
# always produce the same bytes, or a cache anywhere between the site and the
# user will serve a copy whose checksum no longer matches the signed repodata.
# rpm honours SOURCE_DATE_EPOCH for BUILDTIME and clamps file mtimes to it.
: "${SOURCE_DATE_EPOCH:=1700000000}"
export SOURCE_DATE_EPOCH

rpmbuild -bb \
    --define "_topdir $TOP" \
    --define "dist .fc$REL" \
    --define "use_source_date_epoch_as_buildtime 1" \
    --define "clamp_mtime_to_source_date_epoch 1" \
    "$TOP/SPECS/kathara-release.spec" >/dev/null

built="$(find "$TOP/RPMS" -name '*.noarch.rpm' -type f)"
[ -n "$built" ] || { echo "ERROR: rpmbuild produced no package" >&2; exit 1; }
cp "$built" "$OUT/"
echo "Built $OUT/$(basename "$built")"
rpm -qpi --nosignature "$OUT/$(basename "$built")" | sed 's/^/    /'