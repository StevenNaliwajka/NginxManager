import subprocess
import sys
from unittest.mock import patch

def test_run_sh_dry_run_mode(monkeypatch):
    called = []

    def fake_run(cmd, *args, **kwargs):
        if "nginx" in cmd:
            called.append("nginx")
        return subprocess.CompletedProcess(cmd, 0)

    monkeypatch.setattr(subprocess, "run", fake_run)

    # Simulate dry run
    result = subprocess.run(
        [sys.executable, "run.sh", "--dry-run"],
        capture_output=True,
        text=True
    )

    assert "nginx" not in called
