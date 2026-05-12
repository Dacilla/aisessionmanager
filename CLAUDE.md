# CLAUDE.md

A systemd timer that pings Claude Code and Codex CLI at 8 AM and 1 PM (Mon-Thu) to keep 5-hour session windows from expiring mid-workday. Runs as user `alex` with access to the user's CLI tools and auth credentials.

## Project structure

```
ai-pinger.sh     — bash script that sends a minimal "Hi" prompt to each CLI, logs results
ai-pinger.service — systemd oneshot service wrapping the script
ai-pinger.timer   — systemd timer with OnCalendar=Mon..Thu at 08:00 and 13:00
setup.sh          — one-shot root installer: copies files, enables timer
README.md         — docs
```

## The 5-hour window math

Session starts at 8 AM → expires at 1 PM. Re-trigger at 1 PM → expires at 6 PM. Full coverage for a 9-5 workday.

## Logging

- Text log: `/var/log/ai-pinger.log`
- Journal: `journalctl -u ai-pinger.service`

## Systemd commands

```bash
systemctl status ai-pinger.timer
systemctl list-timers ai-pinger.timer
systemctl start ai-pinger.service
journalctl -u ai-pinger.service -f
```

## Script details

- `ai-pinger.sh` exits gracefully if a CLI binary is not found (logs SKIPPED)
- Each ping has a 120s timeout
- Exit codes are captured and logged
- The timer uses `Persistent=true` so missed runs fire immediately after boot
