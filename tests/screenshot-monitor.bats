#!/usr/bin/env bats
#
# bin/<arch>/screenshot-monitor runs a single minui-btntest watcher. It must
# exit rather than loop when minui-btntest fails, and must take the watcher
# down with it when service-off kills it.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    PAK_DIR="$BATS_TEST_TMPDIR/Screenshot Monitor.pak"
    CALLS="$BATS_TEST_TMPDIR/btntest-calls"
    STUB_PID="$BATS_TEST_TMPDIR/btntest-pid"
    STUB_TERM="$BATS_TEST_TMPDIR/btntest-term"
    SERVICE_LOG="$BATS_TEST_TMPDIR/logs/Screenshot Monitor.service.txt"

    export SDCARD_PATH="$BATS_TEST_TMPDIR/sdcard"
    export USERDATA_PATH="$BATS_TEST_TMPDIR/userdata"
    export LOGS_PATH="$BATS_TEST_TMPDIR/logs"
    export PLATFORM="test"
    export HOTKEY="btn_l2"
    mkdir -p "$SDCARD_PATH" "$USERDATA_PATH/Screenshot Monitor" "$LOGS_PATH"

    mkdir -p "$PAK_DIR/bin/arm" "$PAK_DIR/bin/arm64" "$PAK_DIR/bin/$PLATFORM"
    cp "$REPO_ROOT/bin/arm/screenshot-monitor" "$PAK_DIR/bin/arm/"
    cp "$REPO_ROOT/bin/arm64/screenshot-monitor" "$PAK_DIR/bin/arm64/"
    touch "$PAK_DIR/bin/screenshot" "$PAK_DIR/bin/sanitize-filename"

    # the stub records every call, then either exits with $STUB_EXIT
    # or blocks until it is sent SIGTERM when $STUB_EXIT is "block".
    # a monitor that keeps calling it is killed so the test fails instead of hanging
    cat >"$PAK_DIR/bin/$PLATFORM/minui-btntest" <<EOF
#!/bin/sh
echo "\$*" >>"$CALLS"
if [ "\$(wc -l <"$CALLS")" -gt 3 ]; then
    kill -KILL "\$PPID"
    exit 1
fi
if [ "\$STUB_EXIT" = "block" ]; then
    trap 'echo term >"$STUB_TERM"; exit 143' TERM
    echo "\$\$" >"$STUB_PID"
    while true; do
        sleep 0.1
    done
fi
exit "\${STUB_EXIT:-0}"
EOF
    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-btntest"

    architecture=arm
    if uname -m | grep -q '64'; then
        architecture=arm64
    fi
    MONITOR="$PAK_DIR/bin/$architecture/screenshot-monitor"
}

# wait_for <file> waits up to 5 seconds for a file to exist
wait_for() {
    for _ in $(seq 1 50); do
        [ -f "$1" ] && return 0
        sleep 0.1
    done
    return 1
}

@test "arm and arm64 monitors are identical" {
    cmp "$REPO_ROOT/bin/arm/screenshot-monitor" "$REPO_ROOT/bin/arm64/screenshot-monitor"
}

@test "runs a single watcher that takes a screenshot on the hotkey" {
    STUB_EXIT=0 run "$MONITOR"
    [ "$(cat "$CALLS")" = "watch is_pressed all btn_l2 -- screenshot" ]
}

@test "exits instead of looping when minui-btntest rejects the hotkey" {
    STUB_EXIT=10 run "$MONITOR"
    [ "$status" -eq 10 ]
    [ "$(wc -l <"$CALLS")" -eq 1 ]
    grep -q "Invalid hotkey: btn_l2" "$SERVICE_LOG"
}

@test "exits instead of looping when minui-btntest fails unexpectedly" {
    STUB_EXIT=1 run "$MONITOR"
    [ "$status" -eq 1 ]
    [ "$(wc -l <"$CALLS")" -eq 1 ]
    grep -q "minui-btntest exited unexpectedly (1)" "$SERVICE_LOG"
}

@test "refuses to start without a hotkey" {
    HOTKEY="" run "$MONITOR"
    [ "$status" -eq 1 ]
    [ ! -f "$CALLS" ]
    grep -q "No hotkey configured" "$SERVICE_LOG"
}

@test "stops the watcher when the monitor is terminated" {
    STUB_EXIT=block "$MONITOR" >/dev/null 2>&1 3>&- &
    monitor_pid=$!

    wait_for "$STUB_PID"
    stub_pid="$(cat "$STUB_PID")"

    kill -TERM "$monitor_pid"
    wait "$monitor_pid" || true

    wait_for "$STUB_TERM"
    for _ in $(seq 1 50); do
        kill -0 "$stub_pid" 2>/dev/null || break
        sleep 0.1
    done
    run kill -0 "$stub_pid"
    [ "$status" -ne 0 ]
}
