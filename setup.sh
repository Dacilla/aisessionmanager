#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "=== AI Session Pinger Setup ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/4] Installing ping script to /usr/local/bin..."
cp "$SCRIPT_DIR/ai-pinger.sh" /usr/local/bin/ai-pinger.sh
chmod +x /usr/local/bin/ai-pinger.sh

echo "[2/4] Installing systemd units..."
cp "$SCRIPT_DIR/ai-pinger.service" /etc/systemd/system/
cp "$SCRIPT_DIR/ai-pinger.timer" /etc/systemd/system/

echo "[3/5] Creating log file..."
touch /var/log/ai-pinger.log
chown alex:alex /var/log/ai-pinger.log
chmod 644 /var/log/ai-pinger.log

echo "[4/5] Creating env file for failure-notification webhook..."
if [[ ! -f /etc/ai-pinger.env ]]; then
    cat > /etc/ai-pinger.env <<'EOF'
# Discord webhook URL for failure notifications.
# Add a line like: DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
# Leave unset to disable notifications.
DISCORD_WEBHOOK_URL=
EOF
    chmod 600 /etc/ai-pinger.env
    echo "  Created /etc/ai-pinger.env (chmod 600). Edit it to set DISCORD_WEBHOOK_URL."
else
    echo "  /etc/ai-pinger.env already exists, leaving untouched."
fi

echo "[5/5] Enabling and starting timer..."
systemctl daemon-reload
systemctl enable --now ai-pinger.timer

echo ""
echo "Done. Verify with:"
echo "  systemctl status ai-pinger.timer"
echo "  systemctl list-timers ai-pinger.timer"
echo "  journalctl -u ai-pinger.service"
echo "  tail -f /var/log/ai-pinger.log"
echo ""
echo "To enable Discord failure notifications, edit /etc/ai-pinger.env and set DISCORD_WEBHOOK_URL, then:"
echo "  sudo systemctl daemon-reload"
