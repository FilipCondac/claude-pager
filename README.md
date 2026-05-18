# claude-pager

Approve or deny Claude Code permission prompts from your phone, anywhere.

No Tailscale. No SSH server. No iOS Shortcuts. No port forwarding.

## How it works

```
Claude (Mac)  ──Notification hook──▶  ntfy.sh/<request-topic>  ──push──▶  iPhone
                                                                              │
                                                                              │ tap [Approve]
                                                                              ▼
Mac daemon  ◀──long-poll──  ntfy.sh/<response-topic>  ◀──HTTP POST (signed)──┘
     │
     └──▶  tmux send-keys → the Claude session that asked
```

The Mac never accepts inbound connections — the daemon makes one outbound HTTPS stream to ntfy.sh and waits.

## Notification body

Each approval push includes what Claude actually wants to do, so you can decide from your phone without context-switching to the Mac:

```
Approve Bash?
Claude needs your permission to use Bash

$ rm -rf node_modules && npm install

in my-project
```

## Install

### Homebrew (recommended once released)

```
brew tap REPLACE_OWNER/claude-pager
brew install claude-pager
CLAUDE_PAGER_PLIST_TEMPLATE="$(brew --prefix)/share/claude-pager/launchd/com.claudepager.daemon.plist.template" \
  claude-pager-setup
```

### From source

```
git clone <repo> ~/claude-pager
cd ~/claude-pager
./install.sh
```

Either path:

1. Drops the daemon + hook somewhere PATH-reachable
2. Generates unique topic slugs and a 32-byte HMAC secret in `~/.config/claude-pager/config.json` (mode 600)
3. Installs a LaunchAgent so the daemon runs at login and restarts on crash
4. Wires the Notification hook into `~/.claude/settings.json`
5. Prints the topic name to subscribe in the ntfy iOS app

Then:

```
tmux new -s claude
claude
# Ctrl-b d to detach; your phone can now approve prompts
```

## On your phone

1. Install **ntfy** from the App Store
2. Tap `+`, enter the topic name the installer printed, leave server as `ntfy.sh`, subscribe
3. Done — approvals will push as actionable notifications

## Multi-session

`claude-pager` records the tmux session each prompt came from, so if you have three Claudes running in `claude:0`, `agents:0`, and `dev:0`, votes route to the right one. Just run each Claude inside a tmux session.

If you run Claude outside of tmux, the daemon falls back to `tmux_target` in `config.json` (default `claude:0`).

## Security

- Each install gets unique request/response topic slugs (22 chars of base64 entropy each).
- Every notification carries two action-button payloads signed with HMAC-SHA256.
- The daemon verifies the signature and that the nonce matches an outstanding prompt, then deletes the nonce (replay protection).
- ntfy.sh is a public free relay — anyone who learns your topic slug can read the prompts but cannot forge a valid vote without the HMAC secret on the Mac. If reading the prompts is unacceptable, self-host ntfy and change `server` in `config.json`.

## Limitations

- Mac must be awake. Either keep it plugged in with "Prevent automatic sleeping when display is off" enabled, or run Claude under `caffeinate -dis`.
- Assumes Claude Code's permission prompts accept `1` / `2` as approve / deny shortcuts. Override with `approve_key` / `deny_key` in `config.json`.

## Uninstall

```
./uninstall.sh
```

## Commands

- `claude-pager-status` — daemon state, config, inflight prompts, recent log
- `claude-pager-test` — end-to-end self-test (fires a notification you can tap)
- `claude-pager-setup` — re-run wiring after editing config or upgrading

## Configuration

`~/.config/claude-pager/config.json`:

| key | default | what |
|---|---|---|
| `gate` | `["Bash","Write","Edit","WebFetch"]` | which tools fire a notification |
| `delay_seconds` | `20` | wait before notifying; if you respond locally first, no buzz. Can be a per-tool dict: `{"Bash": 20, "Write": 5, "default": 15}` |
| `notify_on_idle` | `false` | also push when Claude is idle waiting for your next message |
| `caffeinate` | `true` | daemon auto-runs `caffeinate -dis` while any prompt is pending; releases when none |
| `confirm_delivery` | `true` | after you tap Approve/Deny, push a low-priority "✓ delivered" follow-up, then a "✓ tool done" or "✗ tool failed" once the tool runs |
| `tmux_target` | `claude:0` | fallback target if hook can't detect tmux session |
| `approve_key` / `allow_always_key` / `deny_key` | `1` / `2` / `3` | keystroke sent to Claude on phone response. Match Claude Code's permission menu: `1` = yes once, `2` = yes and allowlist, `3` = no |

To debug a single hook invocation: `CLAUDE_PAGER_DEBUG=1` in env, then read `~/Library/Logs/claude-pager-hook.log`.

## Logs

```
tail -f ~/Library/Logs/claude-pager.log
```
