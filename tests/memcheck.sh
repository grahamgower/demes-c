#!/bin/bash

export RESOLVE=../resolve

die() {
    echo $@
    exit 255
}
export -f die

memcheck() {
    yaml=$1
    valgrind -q --leak-check=full --error-exitcode=255 $RESOLVE $yaml >/dev/null
    ret=$?
    if [ $ret -ge 128 ]; then
        die "$yaml: memory error"
    fi
    return $ret
}
export -f memcheck

# Resolve the valid example models under valgrind to check for memory errors.
memcheck_valid() {
    yaml=$1
    echo "memcheck_valid: $yaml"
    memcheck $yaml
    if [ $? != 0 ]; then
        die "$yaml: failed to resolve valid model"
    fi
}
export -f memcheck_valid

# Check that the resolver raises errors for invalid models,
# and that there are no memory leaks.
memcheck_invalid() {
    yaml=$1
    echo "memcheck_invalid: $yaml"
    memcheck $yaml
    if [ $? = 0 ]; then
        die "$yaml: failed to reject invalid model"
    fi
}
export -f memcheck_invalid


find test-cases/valid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'memcheck_valid "$@"' bash \
    || exit 1

find test-cases/invalid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'memcheck_invalid "$@"' bash \
    || exit 1
