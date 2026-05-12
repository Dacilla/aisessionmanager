# AI Session Pinger

Keeps your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Codex CLI](https://github.com/openai/codex) 5-hour rolling session windows alive throughout your workday.

## The Problem

Claude Code and Codex CLI use a **5-hour rolling window** for their subscription limits. If you start a session at 9 AM and work straight through, your credits run out at 2 PM — right in the middle of the afternoon, with no refresh until 5 PM when your workday is already over.

## The Solution

This script pings both CLIs with a trivial query at strategic times so the 5-hour window always expires **after** your workday ends:

```
8:00 AM  →  ping starts session 1  →  expires at 1:00 PM (mid-day)
1:00 PM  →  ping starts session 2  →  expires at 6:00 PM (after work)
```

You get full credit coverage from 9 AM to 5 PM, Monday through Thursday.

## Installation

```bash
git clone https://github.com/Dacilla/aisessionmanager.git
cd aisessionmanager
sudo ./setup.sh
```

The setup script:
1. Copies `ai-pinger.sh` to `/usr/local/bin/`
2. Installs the systemd service and timer units
3. Creates the log file at `/var/log/ai-pinger.log`
4. Enables and starts the timer

## Requirements

- Ubuntu / Debian (any distro with systemd)
- `claude` CLI installed and authenticated ([Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/overview))
- `codex` CLI installed and authenticated ([Codex CLI docs](https://github.com/openai/codex))

If a CLI is not installed, the script skips it gracefully and logs the skip.

## Verification

```bash
systemctl status ai-pinger.timer      # check timer state
systemctl list-timers ai-pinger.timer  # see next run time
journalctl -u ai-pinger.service        # systemd logs
tail -f /var/log/ai-pinger.log         # app log file
```

## Manual Test

```bash
sudo systemctl start ai-pinger.service
journalctl -u ai-pinger.service --no-pager -n 10
```

## Schedule

| Day | Time | Action |
|---|---|---|
| Mon–Thu | 08:00 | Start 1st 5h window (expires 13:00) |
| Mon–Thu | 13:00 | Start 2nd 5h window (expires 18:00) |
| Fri–Sun | — | No pings (weekend) |

`RandomizedDelaySec=30` adds a small jitter so pings don't hit exactly on the minute.

## License

MIT
