#!/usr/bin/make -f
# ============================================================================
# Configuration packages for the Kathara Linux package repository.
#
#   kathara-archive-keyring  (.deb, Architecture: all, one per suite)
#       /usr/share/keyrings/$(KEYRING_NAME).gpg      metadata public key
#       /etc/apt/sources.list.d/kathara.sources      repo definition (conffile)
#
#   kathara-release          (.rpm, noarch, one per Fedora release)
#       /etc/pki/rpm-gpg/$(KEY_FILE_NAME)            package + metadata pubkeys
#       /etc/yum.repos.d/$(REPO_ID).repo             repo definition
#
# These packages make the signing keys and the repository definition upgradeable through the package manager itself: a key rotation or a URL change ships as a regular `apt upgrade` / `dnf upgrade`, instead of asking every user to re-run a curl command.
#
# The version below is INDEPENDENT of the Kathara version: bump it (and only it) when the keys or the repository definition change.
#
# CI usage:
#   make deb_noble  deb_jammy  deb_resolute  deb_trixie
#   make rpm_43     rpm_44
#
# Inputs (overridable from the environment):
#   REPO_URL       public base URL of the repository site
#   DEB_SUBDIR / RPM_SUBDIR / REPO_COMPONENT   site layout
#   KEYRING_NAME / KEY_FILE_NAME / REPO_ID     key and repo file names
#
# The public keys are committed in keys/ (see keys/README.md): they are public material, and pinning them in git means changing what users will trust requires a reviewed commit.
# ============================================================================

CONF_VERSION=1.0
PACKAGE_VERSION=1

REPO_URL?=https://repo.kathara.org
DEB_SUBDIR?=deb
RPM_SUBDIR?=rpm
REPO_COMPONENT?=main
KEYRING_NAME?=kathara-archive-keyring
KEY_FILE_NAME?=RPM-GPG-KEY-kathara
REPO_ID?=kathara

export CONF_VERSION PACKAGE_VERSION REPO_URL DEB_SUBDIR RPM_SUBDIR \
       REPO_COMPONENT KEYRING_NAME KEY_FILE_NAME REPO_ID

.PHONY: all clean

# A plain `make` builds one package of each kind, for a quick local check.
all: deb_noble rpm_43

# Pattern target: `make deb_noble`, `make deb_trixie`, ...
# The suite becomes the version suffix (1.0-1noble), which is what the GitLab pipeline uses to file the package under the right suite — the same mechanism used by the kathara package itself.
deb_%:
	./build-deb.sh $*

# Pattern target: `make rpm_43`, `make rpm_44`, ...
# The Fedora release becomes the %{?dist} tag (1.fc43), which is what the GitLab pipeline uses to file the package under fedora/<releasever>/.
rpm_%:
	./build-rpm.sh $*

clean:
	rm -rf Output
