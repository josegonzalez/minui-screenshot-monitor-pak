#!/usr/bin/env bats
#
# bin/service-on reads the hotkey file and starts the monitor with a hotkey
# minui-btntest accepts, refusing to start it at all when the hotkey is invalid.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    PAK_DIR="$BATS_TEST_TMPDIR/Screenshot Monitor.pak"
    RECORDED="$BATS_TEST_TMPDIR/recorded-hotkey"

    export SDCARD_PATH="$BATS_TEST_TMPDIR/sdcard"
    export USERDATA_PATH="$BATS_TEST_TMPDIR/userdata"
    export LOGS_PATH="$BATS_TEST_TMPDIR/logs"
    export PLATFORM="test"
    mkdir -p "$SDCARD_PATH" "$USERDATA_PATH/Screenshot Monitor" "$LOGS_PATH"

    mkdir -p "$PAK_DIR/bin/arm" "$PAK_DIR/bin/arm64"
    cp "$REPO_ROOT/bin/service-on" "$REPO_ROOT/bin/normalize-hotkey" "$PAK_DIR/bin/"

    # the stub monitor records the hotkey it was started with
    for architecture in arm arm64; do
        cat >"$PAK_DIR/bin/$architecture/screenshot-monitor" <<EOF
#!/bin/sh
printf '%s' "\$HOTKEY" >"$RECORDED.tmp"
mv "$RECORDED.tmp" "$RECORDED"
EOF
        chmod +x "$PAK_DIR/bin/$architecture/screenshot-monitor"
    done
}

# service-on starts the monitor in the background, so wait for it to record
recorded_hotkey() {
    for _ in $(seq 1 50); do
        if [ -f "$RECORDED" ]; then
            cat "$RECORDED"
            return 0
        fi
        sleep 0.1
    done
    return 1
}

@test "defaults to btn_l2 when there is no hotkey file" {
    run "$PAK_DIR/bin/service-on"
    [ "$status" -eq 0 ]
    [ "$(recorded_hotkey)" = "btn_l2" ]
}

@test "defaults to btn_l2 when the hotkey file is blank" {
    printf '\n' >"$USERDATA_PATH/Screenshot Monitor/hotkey"
    run "$PAK_DIR/bin/service-on"
    [ "$status" -eq 0 ]
    [ "$(recorded_hotkey)" = "btn_l2" ]
}

@test "normalizes a bare button name" {
    printf 'L2\n' >"$USERDATA_PATH/Screenshot Monitor/hotkey"
    run "$PAK_DIR/bin/service-on"
    [ "$status" -eq 0 ]
    [ "$(recorded_hotkey)" = "btn_l2" ]
}

@test "normalizes a combination" {
    printf 'l1,r1\r\n' >"$USERDATA_PATH/Screenshot Monitor/hotkey"
    run "$PAK_DIR/bin/service-on"
    [ "$status" -eq 0 ]
    [ "$(recorded_hotkey)" = "btn_l1,btn_r1" ]
}

@test "exits 2 and never starts the monitor on an invalid hotkey" {
    printf 'foo\n' >"$USERDATA_PATH/Screenshot Monitor/hotkey"
    run "$PAK_DIR/bin/service-on"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Invalid hotkey: foo"* ]]
    sleep 0.5
    [ ! -f "$RECORDED" ]
}
