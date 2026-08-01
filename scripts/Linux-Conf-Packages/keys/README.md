# Public keys embedded in the configuration packages

Both files are **public** key material, committed on purpose: pinning them in
git means that changing what every user's machine will trust requires a
reviewed commit, not a CI variable edit.

| File | Key | Private half lives in |
|---|---|---|
| `kathara-package-key.asc`  | RPM **package** signing key (signs every `.rpm` in the `rpm-sign` job) | GitHub Actions secret `RPM_GPG_PRIVATE_KEY` |
| `kathara-metadata-key.asc` | repository **metadata** key (signs `InRelease` and `repomd.xml` on GitLab) | GitLab CI variable `GPG_PRIVATE_KEY` |

To (re)generate them, on the machines that hold the respective private keys:

    gpg --armor --export <PACKAGE_KEY_ID>  > kathara-package-key.asc
    gpg --armor --export <METADATA_KEY_ID> > kathara-metadata-key.asc

During a key rotation a file may temporarily contain BOTH the old and the new
public key (concatenated armored blocks): rpm/dnf and apt import every block
they find, which is what gives existing users a window to absorb the new key
while the archive is still signed with the old one.

The GitLab side pins the same package public key in `conf/pubkeys/` of the
repository project; keep the two copies in sync.
