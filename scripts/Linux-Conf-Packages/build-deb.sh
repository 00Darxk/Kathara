#!/usr/bin/env bash
# ============================================================================
# build-deb.sh <suite>
# Builds kathara-archive-keyring_<CONF_VERSION>-<PACKAGE_VERSION><suite>_all.deb into Output/.
#
# The package carries the METADATA public key and the repository definition.
# `Suites:` must match the machine's own suite and a package cannot know it at runtime, so one package is built per suite: the suite in the version suffix files it into the right pool with no special handling downstream.
#
# The .deb itself is not GPG-signed: APT's chain of trust starts at the signed InRelease of the repository that serves it.
# ============================================================================
set -euo pipefail

SUITE="${1:?usage: build-deb.sh <suite>}"
[[ "$SUITE" =~ ^[a-z][a-z0-9]*$ ]] || { echo "Invalid suite: $SUITE" >&2; exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

: "${CONF_VERSION:?}" "${PACKAGE_VERSION:?}" "${REPO_URL:?}" "${DEB_SUBDIR:?}"
: "${REPO_COMPONENT:?}" "${KEYRING_NAME:?}"

META_KEY="keys/kathara-metadata-key.asc"
[ -s "$META_KEY" ] || {
    echo "ERROR: $META_KEY is missing or empty (see keys/README.md)" >&2; exit 1; }

PKG=kathara-archive-keyring
VER="$CONF_VERSION-$PACKAGE_VERSION$SUITE"
OUT="Output"
STAGE="$(mktemp -d)"
chmod 755 "$STAGE"
trap 'rm -rf "$STAGE"' EXIT INT TERM

mkdir -p "$OUT" \
         "$STAGE/DEBIAN" \
         "$STAGE/usr/share/keyrings" \
         "$STAGE/etc/apt/sources.list.d" \
         "$STAGE/usr/share/doc/$PKG"

# --- Keyring ----------------------------------------------------------------
# /usr/share/keyrings, NOT /etc/apt/keyrings:
# the former is package-owned and gets replaced on upgrade (which is the whole point — key rotation rides the regular upgrade), the latter is administrator-owned and a package must not touch it.
# The dearmored binary form is what Signed-By expects.
gpg --dearmor < "$META_KEY" > "$STAGE/usr/share/keyrings/$KEYRING_NAME.gpg"
chmod 644 "$STAGE/usr/share/keyrings/$KEYRING_NAME.gpg"

# --- Repository definition (deb822) -----------------------------------------
sed -e "s|__REPO_URL__|$REPO_URL|g" \
    -e "s|__DEB_SUBDIR__|$DEB_SUBDIR|g" \
    -e "s|__SUITE__|$SUITE|g" \
    -e "s|__COMPONENT__|$REPO_COMPONENT|g" \
    -e "s|__KEYRING_NAME__|$KEYRING_NAME|g" \
    deb/kathara.sources.in > "$STAGE/etc/apt/sources.list.d/kathara.sources"
chmod 644 "$STAGE/etc/apt/sources.list.d/kathara.sources"

# --- Metadata ---------------------------------------------------------------
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VER
Architecture: all
Maintainer: Kathara Team <contact@kathara.org>
Section: misc
Priority: optional
Multi-Arch: foreign
Homepage: https://www.kathara.org/
Description: GnuPG archive key and repository definition of the Kathara repository
 Installs the public key used to verify the Kathara APT repository and the
 repository definition itself, so that future key rotations and repository
 changes arrive through regular package upgrades.
EOF

# The repository definition is a conffile: dpkg preserves local edits and prompts on conflicting upgrades, like any /etc file.
printf '/etc/apt/sources.list.d/kathara.sources\n' > "$STAGE/DEBIAN/conffiles"

# Bootstrap cleanup: the install instructions create a plain kathara.list before this package exists.
# Once the package's own kathara.sources is in place, that leftover would define the repository twice.
sed -e "s|__KEYRING_NAME__|$KEYRING_NAME|g" \
    deb/postinst.in > "$STAGE/DEBIAN/postinst"
chmod 755 "$STAGE/DEBIAN/postinst"

cat > "$STAGE/usr/share/doc/$PKG/copyright" <<'EOF'
Kathara is distributed under the GPL-3.0 license.
See https://github.com/KatharaFramework/Kathara/blob/main/LICENSE
EOF

# --- Build ------------------------------------------------------------------
dpkg-deb --build --root-owner-group "$STAGE" "$OUT/${PKG}_${VER}_all.deb" >/dev/null
echo "Built $OUT/${PKG}_${VER}_all.deb"
dpkg-deb -I "$OUT/${PKG}_${VER}_all.deb" | sed 's/^/    /'
