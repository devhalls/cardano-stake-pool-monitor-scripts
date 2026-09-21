# Cardano Node and Stake Pool monitoring scripts

<pre style="text-align: center">
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈                                       ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈  U P S T R E A M - S T A K E P O O L  ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈       N O D E - M O N I T O R         ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈                                       ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈ ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈   ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈     ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈       ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈         ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈           ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈             ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈             ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈               ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈             ≈ ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈           ≈≈  ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈        ≈≈≈  ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈    ≈≈≈≈   ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈       ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
|≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈|
</pre>

SSH monitoring tool for multiple remote node management. Multi-host, multi-pane configuration for easy birds eye monitoring. Set yourself up with a dashboard overview and per-node monitoring screens. Monitoring our nodes should be easy, so we can focus on the important tasks like KES rotations! View your logs, gLiveView, and any other custom script from one place.

Help support our work and delegate your ADA to Upstream: [UPSTR](https://upstream.org.uk), every little helps!

Security reports: see [SECURITY.md](SECURITY.md).


---

## Installation

Pull this repo, install dependencies and grant permissions:

```
mkdir Monitor && cd Monitor
git clone https://github.com/devhalls/spo-monitor-scripts.git .
cp hosts.example.yaml hosts.yaml
chmod 600 hosts.yaml
chmod +x ./scripts/*
./scripts/install.sh
```

Now edit the `hosts.yaml` file and configure your nodes:

```
nano hosts.yaml
```

Create a **dedicated** SSH key for monitoring (least privilege — not your producer admin key). A passphrase-protected key is safer if the monitor host is shared; BatchMode still works once the agent holds the key:

```
ssh-keygen -t ed25519 -f ~/.ssh/cardano_monitor -C "cardano@monitor"
```

Copy your new public key to each device you will monitor (prefer a restricted OS user on producers):

```
ssh-copy-id -i ~/.ssh/cardano_monitor.pub user@xxx.xxx.x.xx
ssh -i ~/.ssh/cardano_monitor -o IdentitiesOnly=yes user@xxx.xxx.x.xx
```

On first connect, host keys are recorded in `~/.ssh/known_hosts` (`StrictHostKeyChecking=accept-new`). Do not disable host-key checking.

---

## Usage

Once you have edited the hosts.yaml file, you can run the monitor:
When running, you can navigate to each node using number keys, and press `x` to exit the session.

```
./scripts/manager.sh
```

Validate SSH connectivity first:

```
./scripts/manager.sh --check
```

---

## Fleet updates

`./scripts/fleet.sh` updates Cardano nodes across the same `hosts.yaml` inventory used by the monitor (via SSH BatchMode). It drives [spo-operational-scripts](https://github.com/devhalls/spo-operational-scripts) on each host: `git pull` → set `NODE_VERSION` → `scripts/node.sh update --yes` → verify.

**Prerequisites**

- Passwordless SSH already working for the monitor (`./scripts/manager.sh --check`)
- Each target host has a git checkout of spo-operational-scripts (the path in `workdir`) with the release you want already published/pushed
- Add fleet fields to `hosts.yaml`:

```yaml
role: relay          # or producer — required for update ordering
workdir: "Cardano"   # remote dir containing scripts/node.sh and env
                     # optional: derived from first pane script if omitted
```

Hosts without `role` are listed in `status` / `dry-run` but skipped by `update` (e.g. Midnight docker stacks).

**Safety**

- Stops and restarts the node on each host — destructive. Prefer testnets first.
- Relays update **in parallel**, then producers **sequentially**. If any relay fails, producers are aborted.
- One local confirm before mutations; pass `--yes` to skip that confirm.
- Keep `./scripts/manager.sh` open in another terminal to watch tips while updating.

**Examples**

```
./scripts/fleet.sh check
./scripts/fleet.sh status
./scripts/fleet.sh dry-run --version 11.1.2
./scripts/fleet.sh update --version 11.1.2
./scripts/fleet.sh update --version 11.1.2 --hosts 'Relay'   # title regex filter
./scripts/fleet.sh update --version 11.1.2 --no-pull --yes
```

Requires spo-operational-scripts with `node.sh update --yes` support on the remotes.

---

## Repository info

### Contributors

* Upstream SPO - @upstream_ada
* Devhalls - @devhalls

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version:

1. Branch from `master` (`feature/<slug>` or `fix/<slug>`)
2. `./scripts/install-hooks.sh`
3. Tag-line commits only, e.g. `[SEC] Pin and verify yq downloads`
4. Open a focused PR

Security reports: see [SECURITY.md](SECURITY.md).

### License

Distributed under the GPL-3.0 License. See LICENSE.txt for more information.

### Links

- [Upstream SPO website](https://upstream.org.uk)
- [Upstream Twitter](https://x.com/Upstream_ada)
- [Upstream Cardano Devopp Scripts](https://github.com/devhalls/spo-operational-scripts)
