from __future__ import annotations

import importlib.metadata
import shutil
import zipfile
from pathlib import Path

import pytest
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


@pytest.mark.parametrize("output_arg", ["empty", "relative", "absolute"])
def test_output_argument(monkeypatch, tmp_path, output_arg):
    package_dir = tmp_path / "pkg2"
    shutil.copytree(DIR / "packages/simple", package_dir)
    monkeypatch.chdir(package_dir)

    build_dir = tmp_path / "build"

    output_values = {
        "empty": "",
        "relative": "relative-custom.c",
        "absolute": (build_dir / "absolute-custom.c").as_posix(),
    }

    cmakelists = Path("CMakeLists.txt")
    txt = cmakelists.read_text().replace(
        "# PLACEHOLDER", f'OUTPUT "{output_values[output_arg]}"'
    )
    cmakelists.write_text(txt)

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    generated_file = {
        "empty": "simple.c",
        "relative": "relative-custom.c",
        "absolute": "absolute-custom.c",
    }[output_arg]

    build_files = {x.name for x in build_dir.iterdir()}
    assert f"{generated_file}.dep" in build_files
    assert generated_file in build_files


def test_implicit_cxx(monkeypatch, tmp_path):
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
    package_dir = tmp_path / "pkg4"
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


def test_multiple_packages(monkeypatch, tmp_path):
    package_dir = tmp_path / "pkg5"
    shutil.copytree(DIR / "packages/multiple_packages", package_dir)
    monkeypatch.chdir(package_dir)

    build_dir = tmp_path / "build"

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 6

    build_files = {x.name for x in build_dir.iterdir()}
    assert "module.c.dep" not in build_files
    assert "module.c" not in build_files

    package1_build_files = {x.name for x in (build_dir / "package1").iterdir()}
    assert "module.c.dep" in package1_build_files
    assert "module.c" in package1_build_files

    package2_build_files = {x.name for x in (build_dir / "package1/package2").iterdir()}
    assert "module.c.dep" in package2_build_files
    assert "module.c" in package2_build_files

    package3_build_files = {x.name for x in (build_dir / "__").iterdir()}
    assert "module.c.dep" in package3_build_files
    assert "module.c" in package3_build_files


def test_genex_cython_args(monkeypatch, tmp_path, capfd):
    package_dir = tmp_path / "pkg6"
    shutil.copytree(DIR / "packages/simple", package_dir)
    monkeypatch.chdir(package_dir)

    build_dir = tmp_path / "build"

    cmakelists = Path("CMakeLists.txt")
    txt = (
        cmakelists.read_text()
        .replace("LANGUAGE C", "")
        .replace("LANGUAGES C", "LANGUAGES CXX")
        .replace("# PLACEHOLDER", 'CYTHON_ARGS "$<1:--verbose;--annotate>"')
    )
    cmakelists.write_text(txt)

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "simple.cxx.dep" in build_files
    assert "simple.cxx" in build_files

    # Check side-effect of "--annotate"
    assert "simple.html" in build_files

    # Check side-effect of "--verbose"
    captured = capfd.readouterr()
    assert "Compiling " in captured.out or "Compiling " in captured.err
