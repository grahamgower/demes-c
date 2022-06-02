#!/bin/bash

export RESOLVE=../resolve

die() {
    echo $@
    exit 255
}
export -f die

memcheck() {
    yaml=$1
    vg_out=$(mktemp --tmpdir demes-c-memcheck.XXXXXX)
    valgrind \
        -q --leak-check=full --error-exitcode=255 --log-file=$vg_out \
        $RESOLVE $yaml >/dev/null 2>&1
    ret=$?
    if [ $ret -ge 128 ]; then
        echo "$yaml: memory error"
        cat $vg_out
        rm $vg_out
        exit 255
    fi
    rm $vg_out
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

JOBS=$(python3 -c "import os; print(os.cpu_count())")

find test-cases/valid -name \*.yaml -print0 \
    | xargs -0 -n1 -P$JOBS bash -c 'memcheck_valid "$@"' bash \
    || exit 1

find test-cases/invalid -name \*.yaml -print0 \
    | xargs -0 -n1 -P$JOBS bash -c 'memcheck_invalid "$@"' bash \
    || exit 1
