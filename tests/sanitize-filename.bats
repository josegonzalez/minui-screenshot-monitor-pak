#!/usr/bin/env bats
#
# bin/sanitize-filename turns a game name into something that can be stored
# as a filename on a FAT32/exFAT sd card.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SANITIZE="$REPO_ROOT/bin/sanitize-filename"
}

@test "plain and non-ascii names are unchanged" {
    for name in "Super Mario Bros." "Pokémon Red" "Street Fighter II' - Champion Edition"; do
        run "$SANITIZE" "$name"
        [ "$status" -eq 0 ]
        [ "$output" = "$name" ]
    done
}

@test "colons become a spaced hyphen" {
    run "$SANITIZE" "Mars Matrix: Hyper Solid Shooting"
    [ "$status" -eq 0 ]
    [ "$output" = "Mars Matrix - Hyper Solid Shooting" ]

    run "$SANITIZE" "Re:Zero"
    [ "$output" = "Re - Zero" ]

    run "$SANITIZE" "A : B"
    [ "$output" = "A - B" ]
}

@test "other invalid characters become underscores" {
    for char in '\' '/' '*' '?' '"' '<' '>' '|'; do
        run "$SANITIZE" "a${char}b"
        [ "$status" -eq 0 ]
        [ "$output" = "a_b" ]
    done

    run "$SANITIZE" "???"
    [ "$output" = "___" ]
}

@test "control characters and windows line endings are removed" {
    run "$SANITIZE" "$(printf 'Some\tGame\r')"
    [ "$status" -eq 0 ]
    [ "$output" = "SomeGame" ]
}

@test "leading dots and spaces are stripped so the file is not hidden" {
    run "$SANITIZE" ".hack//Infection"
    [ "$output" = "hack__Infection" ]

    run "$SANITIZE" "  . Game  "
    [ "$output" = "Game" ]
}

@test "repeated spaces are collapsed" {
    run "$SANITIZE" "Some    Game"
    [ "$output" = "Some Game" ]
}

@test "names with no usable characters produce empty output" {
    for name in "" " " "..." "$(printf '\t\r')"; do
        run "$SANITIZE" "$name"
        [ "$status" -eq 0 ]
        [ -z "$output" ]
    done
}
