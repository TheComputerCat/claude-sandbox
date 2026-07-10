# claude-sandbox

A disposable Docker sandbox for running [Claude Code](https://github.com/anthropics/claude-code) over SSH, isolated from the host via Colima.

> Personal playground. Not hardened for untrusted code or multi-user use.

## Requirements

- macOS with [Colima](https://github.com/abiosoft/colima) and Docker CLI
- An SSH keypair to authenticate into the container, e.g.:
  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/claude_sandbox
  ```

## Setup

```bash
make build   # builds the image, injecting ~/.ssh/claude_sandbox.pub
make claude  # starts Colima, runs the container, opens Claude Code
```

Connect from another terminal or VS Code Remote-SSH:

```bash
ssh claude@localhost -p 2222
```

## What's inside

Debian trixie-slim (arm64) with:

- Claude Code, Node/npm
- `uv`, `rustup`/`cargo`, `build-essential`
- `openssh-server`, `git`, `tmux`, `vim`

## Structure

| File | Purpose |
|---|---|
| `Dockerfile` | Image build steps, in order: system packages, user/SSH setup, language toolchains, sshd config |
| `entrypoint.sh` | Restores persisted SSH host keys/authorized_keys, then starts `sshd` |
| `Makefile` | `build`, `start`, `stop`, `run`, `claude` targets |

## Persistence

`/home/claude` is a named Docker volume (`claude-home`), so it survives container restarts. Anything installed there at build time (not the case here) would get shadowed by the volume on first run: this is why `uv`, `cargo`, and npm globals are installed under `/opt` instead.

## Troubleshooting

**"WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED"**
Expected the first time you rebuild after the host-key persistence logic changes, or if the volume is deleted. Clear the stale entry and reconnect:
```bash
ssh-keygen -R "[localhost]:2222"
```

**A binary you expect isn't found over SSH**
Check it didn't get installed to a path under `/home/claude` (see Persistence above): anything there needs an explicit restore step in `entrypoint.sh`, or should live in `/opt` instead.