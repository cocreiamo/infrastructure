"""Reading model/infrastructure.sysml through the JSON export of the SysML v2 Pilot
Implementation, never by parsing the text ourselves.
"""

import ast
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def export_model(source="model/infrastructure.sysml"):
    """Elements of a SysML file (default: the model), by id."""
    path = subprocess.run(
        [str(ROOT / "mise-tasks" / "model" / "export"), str(source)],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    exported = json.loads(Path(path).read_text())
    shutil.rmtree(Path(path).parent)  # the export task makes one directory per call
    elements = (e.get("payload", e) for e in exported)
    return {e["@id"]: e for e in elements}


def relationships(model, element, kind):
    for ref in element.get("ownedRelationship", []):
        relationship = model.get(ref["@id"])
        if relationship is not None and relationship["@type"] == kind:
            yield relationship


def children(model, element, kind=None):
    for ref in element.get("ownedRelationship", []):
        relationship = model.get(ref["@id"])
        if relationship is None or (kind and relationship["@type"] != kind):
            continue
        for child in relationship.get("ownedRelatedElement", []):
            if child["@id"] in model:
                yield model[child["@id"]]


def referenced(model, element):
    """The feature a `verify x` or `verify x.y` refers to, if any."""
    for subsetting in relationships(model, element, "ReferenceSubsetting"):
        target = model.get(subsetting["referencedFeature"]["@id"])
        if target is None:
            return None
        chain = list(relationships(model, target, "FeatureChaining"))
        if chain:  # `x.y`: the last feature of the chain
            return model.get(chain[-1]["chainingFeature"]["@id"])
        return target
    return None


def is_requirement(model, element):
    return (
        element["@type"] == "RequirementUsage"
        and element.get("declaredShortName")
        and referenced(model, element) is None
    )


def verifications(model):
    """The verification definitions of the model, by name, with what they verify."""
    found = {}
    for element in model.values():
        if element["@type"] != "VerificationCaseDefinition":
            continue
        targets = set()
        for objective in children(model, element, "ObjectiveMembership"):
            for verify in children(
                model, objective, "RequirementVerificationMembership"
            ):
                target = referenced(model, verify)
                if target is not None:
                    targets.add(target["@id"])
        found[element["declaredName"]] = targets
    return found


def names_of_tests():
    """Names of the written tests that implement a verification (test_R...).

    A test is a Python function under tests/, or a run of the tests of a unit
    (`run "test_R..."` in a *.tftest.hcl file).
    """
    names = set()
    for path in (ROOT / "tests").rglob("test_*.py"):
        tree = ast.parse(path.read_text())
        names |= {
            node.name
            for node in ast.walk(tree)
            if isinstance(node, ast.FunctionDef) and node.name.startswith("test_R")
        }
    for path in unit_test_files():
        names |= set(re.findall(r'^run "(test_R\w+)"', path.read_text(), re.MULTILINE))
    return names


def unit_test_files():
    """The test files of the units, wherever they are, outside the cache."""
    return sorted(
        p
        for p in ROOT.rglob("*.tftest.hcl")
        if ".cache" not in p.relative_to(ROOT).parts
    )
