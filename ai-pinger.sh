#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/ai-pinger.log"
TIMEOUT_SEC=120

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

ping_claude() {
    if command -v claude &>/dev/null; then
        log "Claude Code: pinging..."
        if timeout "$TIMEOUT_SEC" claude -p "Hi" >/dev/null 2>&1; then
            log "Claude Code: OK"
        else
            local rc=$?
            log "Claude Code: FAILED (exit code $rc)"
        fi
    else
        log "Claude Code: SKIPPED (binary not found)"
    fi
}

ping_codex() {
    local cmd=""
    if command -v codex &>/dev/null; then
        cmd="codex"
    elif command -v openai &>/dev/null && openai --help 2>/dev/null | grep -qi codex; then
        cmd="openai codex"
    else
        log "OpenAI Codex: SKIPPED (binary not found)"
        return
    fi

    log "OpenAI Codex: pinging ($cmd)..."
    if timeout "$TIMEOUT_SEC" $cmd -p "Hi" >/dev/null 2>&1; then
        log "OpenAI Codex: OK"
    else
        local rc=$?
        log "OpenAI Codex: FAILED (exit code $rc)"
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
