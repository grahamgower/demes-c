#!/bin/bash

export RESOLVE=../resolve
export MOCKED_RESOLVE=./mocked-resolve

die() {
    echo $@
    exit 255
}
export -f die

# Check that the fully-resolved output for a model is resolved identically.
idempotent() {
    yaml=$1
    # echo "idempotent: $yaml"
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
    # echo "locale_independent: $yaml"
    sum1=$(LANG=C $RESOLVE $yaml | md5sum | cut -f1 -d" ")
    sum2=$(LANG=en_DK.UTF-8 $RESOLVE $yaml | md5sum | cut -f1 -d" ")
    if [ $sum1 != $sum2 ]; then
        die "$yaml: resolver is not locale-independent"
    fi
}
export -f locale_independent

find input/valid -name \*.yaml -print0 \
    | xargs -0 -n1 $RESOLVE \
    >/dev/null \
    || die "resolve valid"

find input/valid -name \*.yaml -print0 \
    | xargs -0 -n1 xargs -0 -n1 bash -c 'idempotent "$@"' bash \
    >/dev/null \
    || die "resolve valid"

find input/valid -name \*.yaml -print0 \
    | xargs -0 -n1 xargs -0 -n1 bash -c 'locale_independent "$@"' bash \
    >/dev/null \
    || die "resolve valid"

find input/invalid -name \*.yaml -print0 \
    | xargs -0 -n1 $RESOLVE \
    >/dev/null 2>&1 \
    && die "resolve invalid"

find input/valid -name \*.yaml -print0 \
    | xargs -0 -n1 $MOCKED_RESOLVE \
    >/dev/null 2>&1 \
    || die "mocked-resolve valid"
