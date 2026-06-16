import subprocess
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "src"
sys.path.insert(0, str(SRC))

from Kathara import version


def test_placeholder_runs():
    out = subprocess.run(
        [sys.executable, str(SRC / "kathara.py")],
        capture_output=True, text=True, check=True,
    )
    assert "placeholder kathara" in out.stdout


def test_version_is_semver():
    parts = version.parse(version.CURRENT_VERSION)
    assert len(parts) == 3
    assert all(isinstance(p, int) for p in parts)


def test_less_than():
    assert version.less_than("1.0.0", "1.0.1")
    assert not version.less_than("2.0.0", "1.9.9")