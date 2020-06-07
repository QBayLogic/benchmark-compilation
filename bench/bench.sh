#!/usr/bin/env bash

set -eu -o pipefail -o allexport

basedir=$(dirname "$(realpath "$0")")
. "$basedir"/lib.sh

## These are RTS options that avoid penalising high-core CPUs.
##
## Note, that the truly optimal values for -qn and -A probably depend on the
## actual core count and the size of L3$, respectively.
high_core_rtsopts="-qn8 -A32M"

usage() {
        cat >&2 <<EOF
Usage:  $(basename "$0") OPTIONS.. [COMMAND=measure]

Options:

    --cores N             Pass -j N to GHC: compile N modules in parallel
    --iterations N        Perform N iterations, instead of profile defaults

    --cls
    --debug, --trace
    --help

Commands:

    prepare       Prebuild the default profile, so all costs irrelevant
                    to the benchmark are paid for upfront.
                    The default profile is the first one in $specs_filename
    measure       Perform the actual build benchmark using the default profile,
                    and printing out its runtime.
                    WARNING:  the 'prepare' phase must be performed before this
    benchmark     Equivalent to 'prepare' and 'measure'
    all           Benchmark on all profiles in $specs_filename

EOF
}

default_op='benchmark'
specs_filename=./'profile-specs.json'
specs_json=$(realpath "$basedir"/../$specs_filename)
default_profile_spec=$(jq '.[0]' "$specs_json")

function main() {
        local verbose debug trace= profspec prof nix_shell_cmd
        local name= cores= iterations=

        while test $# -ge 1
        do case "$1" in
           --cores | -c )      if test "$2" = 'all'
                               then cores=0; else cores=$2; fi; shift;;
           --iterations | -n ) iterations=$2; shift;;

           --cls )             echo -en "\ec";;
           --verbose )         verbose=t;;
           --debug )           verbose=t; debug=t;;
           --trace )           verbose=t; debug=t; trace=t; set -x;;
           --help | -h )       usage; exit;;
           * )                 break;; esac; shift; done

        op=${1:-$default_op}; shift || true

        profspec=$(jqev "
                   ($default_profile_spec) +
                   (\$ARGS.positional | add)
                   " --jsonargs \
                     ${cores:+     "{ \"cores\":      $cores }"} \
                     ${iterations:+"{ \"iterations\": $iterations }"})

        oprint "profile spec: $(jq -C . <<<$profspec)"

        prof=$(compute_profile_from_spec "$profspec")

        case "$op" in
                benchmark ) nix_shell_cmd="prepare_profile '$prof'; measure_profile '$prof'";;
                prepare )   nix_shell_cmd="prepare_profile '$prof'";;
                measure )   nix_shell_cmd="measure_profile '$prof'";;
                all )       nix_shell_cmd="
                   for i in $(seq 0 $(($(jq length $specs_json) - 1)) | xargs echo)
                   do spec=\$(jq \".[\$i]
                                 \" --argjson i \$i $specs_json)
                      prof=\$(compute_profile_from_spec \"\$spec\")
                      prepare_profile \"\$prof\"
                      measure_profile \"\$prof\"
                   done
                   ";;
                * ) fail "unknown op: $op";;
        esac

        nix-shell --run "${trace:+set -x;} $nix_shell_cmd"
}

function profile_spec_derivations() {
        jqevq "$1" '.attributes | join(" ")' |
        words_to_lines |
        while read drv
              test -n "$drv"
        do nix-instantiate -A "$drv" 2>/dev/null | jq --raw-input
        done | jq --slurp
}

function compute_profile_from_spec() {
        local spec=$1 derivations; shift

        derivations=$(profile_spec_derivations "$spec")

        jqev '$profile_spec +
        { derivations:      $derivations
        }
        ' --argjson 'profile_spec' "$spec" \
          --argjson 'derivations'  "$derivations"
}

function prepare_profile() {
        local prof=$1

        prebuild_profile "$prof"
        warmup_profile   "$prof"
}

function prebuild_profile() {
        local prof=$1 args drvs

        oprint "prebuilding profile: $(jq .name <<<$prof)"

        drvs=($(jqevqlist "$prof" .derivations))
        args=(
                --no-build-output
                --no-out-link
                --cores    4
                "${drvs[@]}"
        )
        dprint nix-build "${args[@]}"
        if   ! nix-build "${args[@]}"
        then errormsg "prebuild build failed for profile:\n$prof\n---------- 8< ----------"
             nix log "${drvs[@]}"
             exit 1; fi
}

function profile_build() {
        local prof=$1 drv=$2
        jqev "$prof
              | del(.derivations)
              | . +
                { derivation: \"$drv\"
                }"
}

function warmup_profile() {
        local prof=$1 args drvs

        oprint "warming up profile.."
        for drv in $(jqevqlist "$prof" .derivations)
        do build_derivation "$(profile_build "$prof" "$drv")"
        done
}

function measure_profile() {
        local prof=$1 build

        oprint "measure profile:\n$(jq . <<<$prof -C)\n"
        for i in $(seq 1 $(jq .iterations <<<$prof) | xargs echo)
        do time for drv in $(jqevqlist "$prof" .derivations)
                   do oprint "iteration $i, drv $drv"
                      build_derivation "$(profile_build "$prof" "$drv")"
                done
        done || true
}

function build_derivation() {
        local build=$1 args
        args=(
                --no-build-output
                --cores    "$(jqevq "$build" .cores)"
                           "$(jqevq "$build" .derivation)"
        )
        dprint    --realise --check "${args[@]}"
        nix-store --realise --check "${args[@]}" 2>/dev/null
}

## Note:  keep this at the very end, so bash is forced to parse everything,
##        before proceeding to execution.
main "$@"
