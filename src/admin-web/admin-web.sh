#!/bin/bash
#
# admin-web.sh — RideHermes 运营管理后台 启动/停止/状态 管理脚本
#
# Usage:
#   ./admin-web.sh start     启动开发服务器 (后台运行)
#   ./admin-web.sh stop      停止开发服务器
#   ./admin-web.sh restart   重启开发服务器
#   ./admin-web.sh status    查看服务状态
#   ./admin-web.sh logs      查看实时日志

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="${SCRIPT_DIR}/.admin-web.pid"
LOG_FILE="${SCRIPT_DIR}/admin-web.log"
PORT=3002
BACKEND_PORT=8080
BACKEND_HOST="127.0.0.1"

# ─── helpers ───────────────────────────────────────────────────

red()    { echo -e "\033[31m$1\033[0m"; }
green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue()   { echo -e "\033[34m$1\033[0m"; }

get_pid() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        fi
    fi
    # Fallback: find by port
    local pid
    pid=$(ss -tlnp 2>/dev/null | grep -F ":$PORT" | grep -oP 'pid=\K[0-9]+' | head -1 || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo "$pid"
        return 0
    fi
    return 1
}

check_backend() {
    if ss -tlnp 2>/dev/null | grep -qF ":$BACKEND_PORT"; then
        return 0
    fi
    return 1
}

# ─── status ────────────────────────────────────────────────────

cmd_status() {
    echo ""
    blue "  RideHermes Admin Web — 状态"
    echo "  ─────────────────────────────"

    # Backend
    if check_backend; then
        green "  后端服务     :8080   ✓ 运行中"
    else
        red "  后端服务     :8080   ✗ 未运行"
    fi

    # Admin web
    local pid
    if pid=$(get_pid); then
        green "  管理后台    :$PORT   ✓ 运行中  (pid=$pid)"
        echo "                           http://localhost:$PORT"
    else
        yellow "  管理后台    :$PORT   — 未运行"
    fi

    # PID file
    if [ -f "$PID_FILE" ]; then
        echo "  PID 文件     $PID_FILE"
    fi

    echo ""
}

# ─── start ─────────────────────────────────────────────────────

cmd_start() {
    if get_pid > /dev/null 2>&1; then
        yellow "  管理后台已在运行中 (port $PORT)"
        cmd_status
        return 0
    fi

    if ! check_backend; then
        yellow "  ⚠ 后端服务未检测到，请确认后端已启动 ($BACKEND_PORT)"
    fi

    echo -n "  正在启动 admin-web ... "

    cd "$SCRIPT_DIR"

    # Start Vite dev server in background
    nohup npx vite --host 0.0.0.0 --port "$PORT" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    # Wait for it to be ready (up to 15s)
    local waited=0
    while [ $waited -lt 15 ]; do
        if ss -tlnp 2>/dev/null | grep -qF ":$PORT"; then
            echo ""
            green "  ✓ 管理后台已启动"
            echo ""
            blue "    地址:  http://localhost:$PORT"
            blue "    日志:  tail -f $LOG_FILE"
            echo ""
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    # Timeout — check if process died
    if ! kill -0 "$pid" 2>/dev/null; then
        red "  ✗ 启动失败，查看日志: $LOG_FILE"
        rm -f "$PID_FILE"
        tail -20 "$LOG_FILE"
        return 1
    fi

    echo ""
    green "  ✓ 管理后台已启动  (pid=$pid)"
    echo ""
    blue "    地址:  http://localhost:$PORT"
    echo ""
}

# ─── stop ──────────────────────────────────────────────────────

cmd_stop() {
    local pid
    if ! pid=$(get_pid); then
        yellow "  管理后台未在运行"
        rm -f "$PID_FILE"
        return 0
    fi

    echo -n "  正在停止 admin-web (pid=$pid) ... "

    # Kill the process group (Vite dev server + HMR)
    kill "$pid" 2>/dev/null || true

    # Wait for graceful shutdown
    local waited=0
    while kill -0 "$pid" 2>/dev/null && [ $waited -lt 10 ]; do
        sleep 1
        waited=$((waited + 1))
    done

    # Force kill if still alive
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
        sleep 1
    fi

    rm -f "$PID_FILE"
    echo ""
    green "  ✓ 已停止"
    echo ""
}

# ─── restart ───────────────────────────────────────────────────

cmd_restart() {
    cmd_stop
    sleep 1
    cmd_start
}

# ─── logs ──────────────────────────────────────────────────────

cmd_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        yellow "  日志文件不存在: $LOG_FILE"
    fi
}

# ─── main ──────────────────────────────────────────────────────

case "${1:-}" in
    start)   cmd_start ;;
    stop)    cmd_stop ;;
    restart) cmd_restart ;;
    status)  cmd_status ;;
    logs)    cmd_logs ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "  start    启动 Vite 开发服务器（后台）"
        echo "  stop     停止开发服务器"
        echo "  restart  重启开发服务器"
        echo "  status   查看管理后台和后端服务状态"
        echo "  logs     查看实时日志"
        echo ""
        exit 1
        ;;
esac
