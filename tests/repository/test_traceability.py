"""Traceability between the requirements model and the tests.

The model is read through the JSON export of the SysML v2 Pilot Implementation,
never by parsing the text ourselves.
"""

import tomllib

import generators
from sysml_model import (
    ROOT,
    children,
    export_model,
    is_requirement,
    names_of_tests,
    verifications,
)


def test_R4_every_requirement_verified():
    model = export_model()

    found = verifications(model)
    verified = set().union(*found.values())
    names = set(found)

    def is_verified(requirement):
        if requirement["@id"] in verified:
            return True
        nested = [c for c in children(model, requirement) if is_requirement(model, c)]
        return bool(nested) and all(is_verified(c) for c in nested)

    requirements = [e for e in model.values() if is_requirement(model, e)]
    assert requirements, "no requirement found in the model"
    unverified = sorted(
        r["declaredShortName"] for r in requirements if not is_verified(r)
    )
    assert not unverified, f"requirements without a verification: {unverified}"

    # Every verification is a test of the same name, or is listed as pending.
    tests = names_of_tests()
    pending_file = ROOT / "tests" / "pending.toml"
    pending = set(tomllib.loads(pending_file.read_text())["pending"])
    assert not names - tests - pending, (
        f"verifications with no test: {sorted(names - tests - pending)}"
    )
    assert not tests - names, (
        f"tests that verify nothing in the model: {sorted(tests - names)}"
    )
    assert not pending & tests, (
        f"written tests still listed as pending: {sorted(pending & tests)}"
    )
    assert not pending - names, (
        f"pending entries not in the model: {sorted(pending - names)}"
    )

    # The list is generated, so it is also exactly the computed one.
    assert pending_file.read_text() == generators.render_pending(names, tests), (
        "tests/pending.toml is out of date: run `mise run generate`"
    )
