import math
import json
import operator
import pathlib
import subprocess

import pytest
import ruamel.yaml


def resolve_c(filename) -> dict:
    """Resolve YAML file using the C resolver."""
    p = subprocess.Popen(["./resolve", filename], stdout=subprocess.PIPE)
    with ruamel.yaml.YAML(typ="safe") as yaml:
        return yaml.load(p.stdout)


def resolve_ref(filename) -> dict:
    """Resolve YAML file using the reference implementation."""
    p = subprocess.Popen(
        ["python3", "demes-spec/reference_implementation/resolve_yaml.py", filename],
        stdout=subprocess.PIPE,
    )
    return json.load(p.stdout)


def dict_isclose(d1, d2, rel_tol=1e-9, abs_tol=1e-12):
    """Return True if d1 and d2 are close, False otherwise."""
    match (d1, d2):
        case (dict(), dict()):
            return d1.keys() == d2.keys() and all(
                dict_isclose(d1[k], d2[k], rel_tol=rel_tol, abs_tol=abs_tol)
                for k in d1
            )
        case (list(), list()):
            return all(
                dict_isclose(l1, l2, rel_tol=rel_tol, abs_tol=abs_tol)
                for l1, l2 in zip(d1, d2)
            )
        case (int() | float(), int() | float()):
            return math.isclose(d1, d2, rel_tol=rel_tol, abs_tol=abs_tol)
        case _:
            return d1 == d2


def dict_map(f, d):
    """Apply f to all terminal elements of d."""
    match d:
        case dict():
            return {k: dict_map(f, v) for k, v in d.items()}
        case list():
            return [dict_map(f, x) for x in d]
        case _:
            return f(d)


def input_files():
    input_dir = pathlib.Path("tests") / "test-cases" / "valid"
    files = list(input_dir.glob("*.yaml"))
    assert len(files) > 1
    return files


@pytest.mark.parametrize("filename", input_files())
def test_c_resolver_against_reference_implementation(filename):
    d1 = resolve_ref(filename)
    d2 = resolve_c(filename)

    for data in (d1, d2):
        # TODO: support metadata
        if "metadata" in data:
            del data["metadata"]

    # Normalise infinities so they're all floats.
    cast_inf = lambda x: math.inf if x == "Infinity" else x
    d1 = dict_map(cast_inf, d1)
    d2 = dict_map(cast_inf, d2)

    # The order of migrations could be different, depending on the order in
    # which symmetric migrations were resolved into pairs.
    migrations_key = operator.itemgetter("source", "dest", "end_time")
    d1["migrations"].sort(key=migrations_key)
    d2["migrations"].sort(key=migrations_key)

    if not dict_isclose(d1, d2):
        # Assert equality (which will fail) so that pytest prints a nice diff.
        assert d1 == d2
