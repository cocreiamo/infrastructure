"""Make the generators of `mise run generate` importable by the tests."""

import sys

from sysml_model import ROOT

sys.path.insert(0, str(ROOT / "mise-tasks" / "generate"))
