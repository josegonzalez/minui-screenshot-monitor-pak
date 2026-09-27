#!/usr/bin/env bats
#
# bin/normalize-hotkey turns the contents of the hotkey file into a value
# minui-btntest accepts, and rejects anything it would fail to parse.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    NORMALIZE="$REPO_ROOT/bin/normalize-hotkey"
}

@test "bare, uppercase and prefixed names normalize to btn_l2" {
    for hotkey in L2 l2 BTN_L2 btn_l2 Btn_L2; do
        run "$NORMALIZE" "$hotkey"
        [ "$status" -eq 0 ]
        [ "$output" = "btn_l2" ]
    done
}

@test "surrounding whitespace and windows line endings are stripped" {
    run "$NORMALIZE" "$(printf ' btn_l2\r\n')"
    [ "$status" -eq 0 ]
    [ "$output" = "btn_l2" ]
}

@test "comma-separated combinations are normalized per entry" {
    run "$NORMALIZE" "l1,R1"
    [ "$status" -eq 0 ]
    [ "$output" = "btn_l1,btn_r1" ]

    run "$NORMALIZE" "l1, r1,"
    [ "$status" -eq 0 ]
    [ "$output" = "btn_l1,btn_r1" ]
}

@test "every documented minui-btntest button is accepted" {
    for button in a b x y l1 l2 l3 r1 r2 r3 menu minus plus power poweroff \
        select start up down left right dpad_up dpad_down dpad_left dpad_right \
        analog_up analog_down analog_left analog_right; do
        run "$NORMALIZE" "$button"
        [ "$status" -eq 0 ]
        [ "$output" = "btn_$button" ]
    done
}

@test "unknown buttons are rejected" {
    for hotkey in foo btn_foo l1,foo L4; do
        run "$NORMALIZE" "$hotkey"
        [ "$status" -eq 1 ]
        [[ "$output" == *"invalid button"* ]]
    done
}

@test "btn_none is rejected since it can never be pressed" {
    for hotkey in none btn_none l1,none; do
        run "$NORMALIZE" "$hotkey"
        [ "$status" -eq 1 ]
        [[ "$output" == *"invalid button: btn_none"* ]]
    done
}

@test "empty input produces empty output" {
    for hotkey in "" ",," " "; do
        run "$NORMALIZE" "$hotkey"
        [ "$status" -eq 0 ]
        [ -z "$output" ]
    done
}
