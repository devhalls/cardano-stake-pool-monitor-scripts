# Security policy

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security problems.

Use GitHub’s [private vulnerability reporting](https://github.com/devhalls/cardano-stake-pool-monitor-scripts/security/advisories/new) for this repository, or contact the maintainers via the Upstream channels in the README.

We aim to acknowledge reports within **7 days**.

## Scope

**In scope**

- Flaws in these scripts that could weaken SSH usage or install tampered binaries (e.g. `yq`)
- Accidental handling that would encourage committing `hosts.yaml` or private keys

**Out of scope**

- Compromised monitor hosts or passwordless SSH keys with overly broad access (operator responsibility)
- Issues solely in tmux, OpenSSH, or upstream `yq` releases after checksum verification succeeds

## Trust boundaries for operators

- `hosts.yaml` is **inventory-sensitive** (IPs, usernames, key paths). It is gitignored; never commit a real copy. Prefer `chmod 600 hosts.yaml`.
- Use a **dedicated monitor SSH key** with least privilege (separate user or forced commands where possible). Avoid one passwordless key that can also administer block producers.
- Prefer verifying host keys (`known_hosts`) rather than disabling host-key checks.

## Maintainer checklist (GitHub settings)

After `gh auth login`, enable for this repo:

1. Dependabot alerts + Dependabot security updates
2. Secret scanning + push protection
3. Private vulnerability reporting
4. Branch protection on `master` (require PR; disallow force-push; optionally require the `CI` status check)
