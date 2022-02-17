import subprocess
import tempfile
import pathlib

import pytest
import hypothesis as hyp
import demes
import demes.hypothesis_strategies


def resolve(filename: str) -> str:
    """
    Load a YAML file, resolve it using the C resolver, and return the
    fully-qualified YAML string.
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        outfile = pathlib.Path(tmpdir) / "out.yaml"
        subprocess.run(f"./resolve {filename} > {outfile}", shell=True, check=True)
        with open(outfile) as f:
            return f.read()


@hyp.settings(
    max_examples=1000,
    deadline=None,
    suppress_health_check=[hyp.HealthCheck.too_slow, hyp.HealthCheck.filter_too_much],
)
@hyp.given(demes.hypothesis_strategies.graphs())
def test_random_graphs(graph1):
    with tempfile.TemporaryDirectory() as tmpdir:
        infile = pathlib.Path(tmpdir) / "in.yaml"
        demes.dump(graph1, infile)
        outstring = resolve(infile)
        graph2 = demes.loads(outstring)
        graph1.assert_close(graph2)


def input_files():
    input_dir = pathlib.Path("tests") / "test-cases" / "valid"
    files = list(input_dir.glob("*.yaml"))
    assert len(files) > 1
    return files


@pytest.mark.parametrize("filename", input_files())
def test_example_graphs(filename):
    graph1 = demes.load(filename)
    outstring = resolve(filename)
    graph2 = demes.loads(outstring)
