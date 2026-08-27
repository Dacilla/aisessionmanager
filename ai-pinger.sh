#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/ai-pinger.log"
TIMEOUT_SEC=120
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
WEBHOOK_TIMEOUT=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

ensure_log_writable() {
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "[$(date)] FATAL: cannot create $LOG_FILE" >&2
            exit 1
        }
    fi
}

notify_failure() {
    local tool="$1"
    local rc="$2"
    local detail="$3"

    if [[ -z "$DISCORD_WEBHOOK_URL" ]]; then
        return 0
    fi

    local payload
    payload=$(cat <<EOF
{
  "content": ":warning: **AI Session Pinger FAILED** — \`${tool}\` (exit ${rc}) at $(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "embeds": [{
    "title": "${tool} ping failed",
    "description": $(printf '%s' "$detail" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()[:1000]))'),
    "color": 15158332
  }]
}
EOF
)

    if ! curl -fsS --max-time "$WEBHOOK_TIMEOUT" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$DISCORD_WEBHOOK_URL" >/dev/null 2>>"$LOG_FILE"; then
        log "WARN: webhook notification failed (see journal for curl error)"
    fi
}

ping_claude() {
    if command -v claude &>/dev/null; then
        local err
        err=$(mktemp)
        log "Claude Code: pinging..."
        if timeout "$TIMEOUT_SEC" claude -p "Hi" >/dev/null 2>"$err"; then
            log "Claude Code: OK"
        else
            local rc=$?
            local detail
            detail=$(head -c 2000 "$err" | tr -d '\0' || true)
            log "Claude Code: FAILED (exit code $rc)"
            [[ -n "$detail" ]] && log "Claude Code: stderr: $detail"
            notify_failure "Claude Code" "$rc" "$detail"
        fi
        rm -f "$err"
    else
        log "Claude Code: SKIPPED (binary not found)"
    fi
}

ping_codex() {
    if command -v codex &>/dev/null; then
        local err
        err=$(mktemp)
        log "OpenAI Codex: pinging..."
        if timeout "$TIMEOUT_SEC" codex exec --skip-git-repo-check "Hi" >/dev/null 2>"$err"; then
            log "OpenAI Codex: OK"
        else
            local rc=$?
            local detail
            detail=$(head -c 2000 "$err" | tr -d '\0' || true)
            log "OpenAI Codex: FAILED (exit code $rc)"
            [[ -n "$detail" ]] && log "OpenAI Codex: stderr: $detail"
            notify_failure "OpenAI Codex" "$rc" "$detail"
        fi
        rm -f "$err"
    elif command -v openai &>/dev/null && openai --help 2>/dev/null | grep -qi codex; then
        local err
        err=$(mktemp)
        log "OpenAI Codex: pinging (via openai)..."
        if timeout "$TIMEOUT_SEC" openai codex -p "Hi" >/dev/null 2>"$err"; then
            log "OpenAI Codex: OK"
        else
            local rc=$?
            local detail
            detail=$(head -c 2000 "$err" | tr -d '\0' || true)
            log "OpenAI Codex: FAILED (exit code $rc)"
            [[ -n "$detail" ]] && log "OpenAI Codex: stderr: $detail"
            notify_failure "OpenAI Codex" "$rc" "$detail"
        fi
        rm -f "$err"
    else
        log "OpenAI Codex: SKIPPED (binary not found)"
    fi
}

main() {
    ensure_log_writable
    log "=== Session ping starting ==="
    ping_claude
    ping_codex
    log "=== Session ping complete ==="
}

main
