# About
demes-c is A C library for parsing [Demes demographic models](https://popsim-consortium.github.io/demes-spec-docs/) using libyaml.

# Installation
Clone the repository and type `make`.
You may need to first install libyaml and/or edit the `Makefile` to provide its location.
This will build a static library `libdemes.a` and a `resolver` binary
that can resolve Demes YAML files.

# API
See `demes.h` and `resolver.c` to understand the interface.

# Gotchas
* metadata is accepted in input files but not available in the API (issue #13)
* errors are printed to stderr instead of being returned via the API (issue #18).
