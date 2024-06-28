from __future__ import annotations

import importlib.metadata
import shutil
import zipfile
from pathlib import Path

from scikit_build_core.build import build_wheel

import cython_cmake as m

DIR = Path(__file__).parent.resolve()


def test_version():
    assert importlib.metadata.version("cython_cmake") == m.__version__


def test_simple(monkeypatch, tmp_path):
    monkeypatch.chdir(DIR / "packages/simple")
    build_dir = tmp_path / "build"

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "simple.c.dep" in build_files
    assert "simple.c" in build_files


def test_implicit_cxx(monkeypatch, tmp_path):
    package_dir = tmp_path / "pkg2"
    shutil.copytree(DIR / "packages/simple", package_dir)
    monkeypatch.chdir(package_dir)

    cmakelists = Path("CMakeLists.txt")
    txt = (
        cmakelists.read_text()
        .replace("LANGUAGE C", "")
        .replace("LANGUAGES C", "LANGUAGES CXX")
    )
    cmakelists.write_text(txt)

    wheel = build_wheel(
        str(tmp_path), {"build-dir": "build", "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in Path("build").iterdir()}
    assert "simple.cxx.dep" in build_files
    assert "simple.cxx" in build_files


def test_directive_cxx(monkeypatch, tmp_path):
    package_dir = tmp_path / "pkg3"
    shutil.copytree(DIR / "packages/simple", package_dir)
    monkeypatch.chdir(package_dir)

    cmakelists = Path("CMakeLists.txt")
    txt = (
        cmakelists.read_text()
        .replace("LANGUAGE C", "")
        .replace("LANGUAGES C", "LANGUAGES CXX")
    )
    cmakelists.write_text(txt)

    simple = Path("simple.pyx")
    txt = simple.read_text()
    simple.write_text(f"# distutils: language=c++\n{txt}")

    wheel = build_wheel(
        str(tmp_path), {"build-dir": "build", "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in Path("build").iterdir()}
    assert "simple.cxx.dep" in build_files
    assert "simple.cxx" in build_files
