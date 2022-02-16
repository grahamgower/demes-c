#!/bin/bash

export RESOLVE=../resolve
export MOCKED_RESOLVE=./mocked-resolve

die() {
    echo $@
    exit 255
}
export -f die

resolve() {
    yaml=$1
    $RESOLVE $yaml > /dev/null
    if [ $? != 0 ]; then
        die "$yaml: failed to resolve valid model"
    fi
}
export -f resolve

# Check that the fully-resolved output for a model is resolved identically.
idempotent() {
    yaml=$1
    sum1=$($RESOLVE $yaml | md5sum | cut -f1 -d" ")
    sum2=$($RESOLVE $yaml | $RESOLVE /dev/stdin | md5sum | cut -f1 -d" ")
    if [ $sum1 != $sum2 ]; then
        die "$yaml: resolver is not idempotent"
    fi
}
export -f idempotent

# Check that the choice of locale doesn't alter the output.
locale_independent() {
    yaml=$1
    sum1=$(LANG=C $RESOLVE $yaml | md5sum | cut -f1 -d" ")
    sum2=$(LANG=en_DK.UTF-8 $RESOLVE $yaml | md5sum | cut -f1 -d" ")
    if [ $sum1 != $sum2 ]; then
        die "$yaml: resolver is not locale-independent"
    fi
}
export -f locale_independent

assert_failure() {
    yaml=$1
    $RESOLVE $yaml > /dev/null 2>&1
    ret=$?
    if [ $ret = 0 ]; then
        die "$yaml: failed to reject invalid model"
    fi
    if [ $ret -gt 128 ]; then
        die "$yaml: resolver exited abnormally"
    fi
}
export -f assert_failure

mocked_resolve() {
    yaml=$1
    $MOCKED_RESOLVE $yaml > /dev/null 2>&1
    if [ $? != 0 ]; then
        die "$yaml: mocked resolve failed"
    fi
}
export -f mocked_resolve

$RESOLVE >/dev/null 2>&1 \
    && die "resolver succeeded, despite no input file"
$MOCKED_RESOLVE >/dev/null 2>&1 \
    && die "mocked resolver succeeded, despite no input file"

find test-cases/valid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'resolve "$@"' bash \
    || exit 1

find test-cases/valid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'idempotent "$@"' bash \
    || exit 1

find test-cases/valid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'locale_independent "$@"' bash \
    || exit 1

find test-cases/invalid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'assert_failure "$@"' bash \
    || exit 1

find test-cases/valid -name \*.yaml -print0 \
    | xargs -0 -n1 bash -c 'mocked_resolve "$@"' bash \
    || exit 1
