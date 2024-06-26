from __future__ import annotations

import importlib.metadata
import shutil
import subprocess


def _get_program(name: str) -> str:
    res = shutil.which(name)
    if res is None:
        return f"No {name} executable found on PATH"
    result = subprocess.run(
        [res, "--version"], check=True, text=True, capture_output=True
    )
    version = result.stdout.splitlines()[0]
    return f"{res}: {version}"


def pytest_report_header() -> str:
    interesting_packages = {
        "cmake",
        "ninja",
        "packaging",
        "pip",
        "scikit-build-core",
    }
    valid = []
    for package in interesting_packages:
        try:
            version = importlib.metadata.version(package)
        except ModuleNotFoundError:
            continue
        valid.append(f"{package}=={version}")
    reqs = " ".join(sorted(valid))
    pkg_line = f"installed packages of interest: {reqs}"
    prog_lines = [_get_program(n) for n in ("cmake3", "cmake", "ninja")]

    return "\n".join([pkg_line, *prog_lines])
