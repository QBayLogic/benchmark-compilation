#!/usr/bin/env bash

set -eu -o pipefail -o allexport

basedir=$(dirname "$(realpath "$0")")
. "$basedir"/lib.sh

## These are RTS options that avoid penalising high-core CPUs.
##
## Note, that the truly optimal values for -qn and -A probably depend on the
## available memory bandwidth/latency and the size of L3$, respectively.
high_core_rtsopts="-qn8 -A32M"

usage() {
        cat >&2 <<EOF
Usage:  $(basename "$0") OPTIONS.. [COMMAND=measure]

Options:

    --cores N             Pass -j N to GHC: compile N modules in parallel
    --rtsopts RTSOPTS     Pass -RTS RTSOPTS +RTS to the compiler
                            NOTE:  default Nixpkgs-supplied RTS opts are:  -A64M
    --high-core-rtsopts   Use RTSOPTS best for high core count:  $high_core_rtsopts
    --iterations N        Perform N iterations, instead of profile defaults
    --profile N           Use N'th profile from $specs_json as base.  Default is 0.
                            Can be specified multiple times
    --attr NAME           Build NAME attribute from 'default.nix', instead of
                            profile defaults.  Can be specified multiple times

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
default_profiles=(0)
specs_filename=./'profile-specs.json'
specs_json=$(realpath "$basedir"/../$specs_filename)
verbose= debug= trace=

function main() {
        local profiles=()
        local name= cores= rtsopts= iterations= attrs=() args argsjson

        while test $# -ge 1
        do case "$1" in
           --profile | -p )    profiles=("${profiles[@]}" $2); shift;;
           --cores | -c )      if test "$2" = 'all'
                               then cores=0; else cores=$2; fi; shift;;
           --rtsopts | -r )    rtsopts=$2; shift;;
           --high-core-rtsopts | -h )
                               rtsopts=$high_core_rtsopts;;
           --iterations | -n ) iterations=$2; shift;;
           --attr | -a )       attrs=("${attrs[@]}" $2); shift;;

           --cls )             echo -en "\ec";;
           --dry-run )         dry_run=t;;
           --verbose )         verbose=t;;
           --debug )           verbose=t; debug=t;;
           --trace )           verbose=t; debug=t; trace=t; set -x;;
           --help | -h )       usage; exit;;
           * )                 break;; esac; shift; done

        args=(${attrs[0]:+  "{ \"attributes\": $(args_to_json "${attrs[@]}") }"}
              ${cores:+     "{ \"cores\":                      $cores }"}
              ${rtsopts:+   "{ \"rtsopts\":                  \"$rtsopts\" }"}
              ${iterations:+"{ \"iterations\":                 $iterations }"}
              ${dry_run:+   "{ \"dry_run\":                    true }"}
        )
        argsjson=$(merge_json_attrs "${args[@]}")
        oprint "args: $(jq -C . <<<$argsjson)"

        op=${1:-$default_op}; shift || true

        if test ${#profiles[*]} -eq 0
        then profiles=(${default_profiles[*]})
        else oprint "will use following profiles:"
             map2 show_profile "$argsjson" ${profiles[*]} 2>/dev/null; fi

        case "$op" in
        benchmark ) cmd="map2 benchmark_profile '$argsjson' ${profiles[*]}";;
        prepare )   cmd="map2   prepare_profile '$argsjson' ${profiles[*]}";;
        measure )   cmd="map2   measure_profile '$argsjson' ${profiles[*]}";;
        all )       local all_profiles
                    all_profiles=($(seq 0 $(($(jq length $specs_json) - 1)) |
                                    xargs echo))
                    cmd="map2 benchmark_profile '$argsjson' ${all_profiles[*]}";;
        * ) fail "unknown op: $op";;
        esac

        nix-shell --run "${trace:+set -x;} $cmd"
}

function args_to_profile() {
        local nr=$1 args=$2

        local def_profspec args profspec
        def_profspec=$(jq '.[$profile_nr]' "$specs_json" \
                          --argjson 'profile_nr' "$nr")
        vprint "base profile spec: $(jq -C . <<<$def_profspec)"

        profspec=$(merge_json_attrs "$def_profspec" "$args")

        vprint "profile spec: $(jq -C . <<<$profspec)"

        compute_profile_from_spec "$profspec"
}

function profile_spec_derivations() {
        local spec=$1 rtsopts xargs nix_args args; shift

        rtsopts=($(jq '.rtsopts // ""' <<<$spec --raw-output))
        if test ${#rtsopts[*]} -gt 0
        then nix_args=(--arg buildFlags
                       '["--ghc-options=\"+RTS '"${rtsopts[*]}"' -RTS\""]')
        else nix_args=(); fi

        jqevq "$spec" '.attributes | join(" ")' |
        words_to_lines |
        while read attr
              test -n "$attr"
        do args=(--attr "$attr" "${nix_args[@]}")
           nix-instantiate "${args[@]}" |
           jq --raw-input
        done | jq --slurp
}

function compute_profile_from_spec() {
        local spec=$1 nix_args derivations; shift

        derivations=$(profile_spec_derivations "$spec")

        jqev '$profile_spec +
        { derivations:      $derivations
        }
        ' --argjson 'profile_spec' "$spec" \
          --argjson 'derivations'  "$derivations"
}

###
###
###
function show_profile() {
        local args=$1 prof_nr=$2

        args_to_profile "$prof_nr" "$args" | jq . -C
}

function benchmark_profile() {
        local args=$1 prof_nr=$2 prof

        prof=$(args_to_profile "$prof_nr" "$args")

        do_prepare_profile "$prof"
        do_measure_profile "$prof"
}

function prepare_profile() {
        local args=$1 prof_nr=$2 prof

        prof=$(args_to_profile "$prof_nr" "$args")

        do_measure_profile "$prof"
}

function measure_profile() {
        local args=$1 prof_nr=$2 prof

        prof=$(args_to_profile "$prof_nr" "$args")

        do_measure_profile "$prof"
}

###
###
###
function do_prepare_profile() {
        local prof=$1

        prebuild_profile "$prof"
        warmup_profile   "$prof"
}

function prebuild_profile() {
        local prof=$1 args drvs

        oprint "prebuilding profile: $(jq -C . <<<$prof)"

        drvs=($(jqevqlist "$prof" .derivations))
        args=(
                --no-build-output
                --no-out-link
                --cores    4
                "${drvs[@]}"
        )

        local cmd=(nix-build "${args[@]}")

        if   jqtest .dry_run <<<$prof
        then echo   "${cmd[@]}" >&2
        elif dprint "${cmd[@]}"
                  ! "${cmd[@]}"
        then errormsg "prebuild build failed for profile: $prof\n---------- 8< ----------"
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

function do_measure_profile() {
        local prof=$1 build

        oprint "measure profile: $(jq . <<<$prof -C)\n"
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

        local cmd=(nix-store --realise --check "${args[@]}")

        if jqtest .dry_run <<<$prof
        then echo   "${cmd[@]}" >&2
        else dprint "${cmd[@]}"
                    "${cmd[@]}" 2>/dev/null
        fi
}

## Note:  keep this at the very end, so bash is forced to parse everything,
##        before proceeding to execution.
main "$@"
