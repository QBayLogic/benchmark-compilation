VERBOSE ?=
DEBUG ?=
TRACE ?=
SHELL := $(shell which bash)

all: bench

bench:
	@./bench/bench.sh $(if ${VERBOSE},--verbose) $(if ${DEBUG},--debug) $(if ${TRACE},--trace) benchmark
prepare:
	@./bench/bench.sh $(if ${VERBOSE},--verbose) $(if ${DEBUG},--debug) $(if ${TRACE},--trace) prepare
measure:
	@./bench/bench.sh $(if ${VERBOSE},--verbose) $(if ${DEBUG},--debug) $(if ${TRACE},--trace) measure

.PHONY: all bench cls
cls:
	@echo -en "\ec"
