#!/usr/bin/env bats
#
# bin/screenshot names the screenshot after the game being played, using a
# name the sd card can store.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    PAK_DIR="$BATS_TEST_TMPDIR/Screenshot Monitor.pak"
    STUB_DIR="$BATS_TEST_TMPDIR/stubs"
    WRITTEN="$BATS_TEST_TMPDIR/written"

    export SDCARD_PATH="$BATS_TEST_TMPDIR/sdcard"
    RECENT="$SDCARD_PATH/.userdata/shared/.minui/recent.txt"
    mkdir -p "$(dirname "$RECENT")"

    mkdir -p "$PAK_DIR/bin" "$STUB_DIR"
    cp "$REPO_ROOT/bin/screenshot" "$REPO_ROOT/bin/sanitize-filename" "$PAK_DIR/bin/"

    # the pngwrite stub records the path it was asked to write
    cat >"$STUB_DIR/pngwrite" <<EOF
#!/bin/sh
printf '%s\n' "\$1" >"$WRITTEN"
touch "\$1"
EOF

    # the pgrep stub only finds the process named in \$RUNNING
    cat >"$STUB_DIR/pgrep" <<'EOF'
#!/bin/sh
[ "$1" = "$RUNNING" ]
EOF
    chmod +x "$STUB_DIR/pngwrite" "$STUB_DIR/pgrep"

    export PATH="$STUB_DIR:$PAK_DIR/bin:$PATH"
}

date_pattern='[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}'

@test "in game screenshots with a colon in the name are written with a valid name" {
    printf '/Roms/Arcade (FBN)/mmatrix.zip\tMars Matrix: Hyper Solid Shooting\n' >"$RECENT"
    RUNNING=minarch.elf run "$PAK_DIR/bin/screenshot"
    [ "$status" -eq 0 ]
    [[ "$(cat "$WRITTEN")" =~ ^"$SDCARD_PATH/Screenshots/Mars Matrix - Hyper Solid Shooting."$date_pattern".png"$ ]]
    [ -f "$(cat "$WRITTEN")" ]
}

@test "the rom filename is used when the entry has no name" {
    printf '/Roms/Game Boy (GB)/Tetris: Deluxe (World).gb\n' >"$RECENT"
    RUNNING=minarch.elf run "$PAK_DIR/bin/screenshot"
    [ "$status" -eq 0 ]
    [[ "$(cat "$WRITTEN")" =~ ^"$SDCARD_PATH/Screenshots/Tetris - Deluxe (World)."$date_pattern".png"$ ]]
}

@test "windows line endings do not leak into the filename" {
    printf '/Roms/Arcade (FBN)/mmatrix.zip\tMars Matrix\r\n' >"$RECENT"
    RUNNING=minarch.elf run "$PAK_DIR/bin/screenshot"
    [ "$status" -eq 0 ]
    [[ "$(cat "$WRITTEN")" =~ ^"$SDCARD_PATH/Screenshots/Mars Matrix."$date_pattern".png"$ ]]
}

@test "screenshots outside of a game use the Screenshot prefix" {
    printf '/Roms/Arcade (FBN)/mmatrix.zip\tMars Matrix: Hyper Solid Shooting\n' >"$RECENT"
    RUNNING=none run "$PAK_DIR/bin/screenshot"
    [ "$status" -eq 0 ]
    [[ "$(cat "$WRITTEN")" =~ ^"$SDCARD_PATH/Screenshots/Screenshot."$date_pattern".png"$ ]]
}

@test "falls back to the Screenshot prefix without a recent game" {
    RUNNING=minarch.elf run "$PAK_DIR/bin/screenshot"
    [ "$status" -eq 0 ]
    [[ "$(cat "$WRITTEN")" =~ ^"$SDCARD_PATH/Screenshots/Screenshot."$date_pattern".png"$ ]]
}

@test "falls back to the Screenshot prefix when the name has no usable characters" {
    printf '/Roms/Arcade (FBN)/mmatrix.zip\t...\n' >"$RECENT"
    RUNNING=minarch.elf run "$PAK_DIR/bin/screenshot"
    [ "$status" -eq 0 ]
    [[ "$(cat "$WRITTEN")" =~ ^"$SDCARD_PATH/Screenshots/Screenshot."$date_pattern".png"$ ]]
}
