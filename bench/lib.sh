#!/usr/bin/env bash

errormsg() {
    echo -e ";  ERROR: $*" >&2
}

fatalmsg() {
    echo    ";  FATAL" >&2
    echo -e ";  FATAL: $*" >&2
    echo    ";  FATAL" >&2
}

oprint() {
    echo -e "--( $*" >&2
}

vprint() {
    test -n "$verbose" &&
    echo -e "--( $*" >&2
}

dprint() {
    test -n "$debug" &&
    echo -e "--( $*" >&2
}

fail() {
    errormsg "$*"
    exit 1
}

jqev() {
        local val=$1; shift
        jq --null-input --raw-output "$val" "$@"
}

jqevq() {
        local val=$1 q=$2; shift 2
        jqev "($val) | $q" "$@"
}

jqevqlist() {
        local val=$1 q=$2; shift 2
        jqevq "$val" "$q | join (\" \")" "$@"
}

json_file_append() {
        local f=$1 extra=$2 tmp; shift 2
        tmp=$(mktemp --tmpdir)

        test -f "$f" || echo "{}" > "$f"
        jq ' $origf[0] as $orig
           | $orig + ('"$extra"')
           ' --slurpfile origf "$f" "$@" > "$tmp"
        mv "$tmp"  "$f"
}

json_file_prepend() {
        local f=$1 extra=$2 tmp; shift 2
        tmp=$(mktemp --tmpdir)

        test -f "$f" || echo "{}" > "$f"
        jq ' $origf[0] as $orig
           | ('"$extra"') + $orig
           ' --slurpfile origf "$f" "$@" > "$tmp"
        mv "$tmp"  "$f"
}

words_to_lines() {
        sed 's_ _\n_g'
}

args_to_json() {
        words_to_lines <<<"$@" | jq --raw-input | jq --slurp --compact-output
}

map() {
        f=$1; shift

        for x in "$@"
        do $f $x || return 1
        done
}
