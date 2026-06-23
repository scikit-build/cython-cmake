from __future__ import annotations

import importlib.metadata
import re
import shutil
import subprocess
import sys
import sysconfig
import zipfile
from pathlib import Path

import pytest
from scikit_build_core.build import build_wheel

import cython_cmake as m

DIR = Path(__file__).parent.resolve()


def _cmake_version() -> tuple[int, ...]:
    cmake = shutil.which("cmake")
    if cmake is None:
        return (0, 0)
    out = subprocess.run(
        [cmake, "--version"], capture_output=True, text=True, check=True
    ).stdout
    match = re.search(r"(\d+)\.(\d+)", out)
    return tuple(int(x) for x in match.groups()) if match else (0, 0)


# The Cython CMake language is experimental: it relies on the binary-dir-less
# try_compile signature (CMake >= 3.25) and does not yet install the built
# module on Windows multi-config generators.
cython_language = pytest.mark.skipif(
    sys.platform == "win32" or _cmake_version() < (3, 25),
    reason="Cython language requires CMake >= 3.25 and is unsupported on Windows",
)


def test_version() -> None:
    assert importlib.metadata.version("cython_cmake") == m.__version__


def test_simple(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
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


@cython_language
def test_simple_language(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.chdir(DIR / "packages/simple_language")
    build_dir = tmp_path / "build"

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    # The extension must carry exactly one (SOABI) suffix; a double ".so.so"
    # means WITH_SOABI saw a bad Python_SOABI (see CMakeDetermineCythonCompiler).
    ext_suffix = sysconfig.get_config_var("EXT_SUFFIX")
    assert f"simple{ext_suffix}" in file_names

    # Cython transpiles to C, which the C language part then compiles.
    cython_c = build_dir / "CMakeFiles/simple.dir/simple.pyx.o.c"
    assert cython_c.is_file()


@cython_language
def test_language_features(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.chdir(DIR / "packages/language_features")
    build_dir = tmp_path / "build"

    # Building at all proves include dirs reached cython: simple.pyx cimports
    # inc/helper.pxd, resolvable only via target_include_directories().
    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    ext_suffix = sysconfig.get_config_var("EXT_SUFFIX")
    assert f"simple{ext_suffix}" in file_names

    # CYTHON_ARGS=--annotate reached cython (and not the C compiler): it emits an
    # HTML report alongside the generated C.
    assert (build_dir / "CMakeFiles/simple.dir/simple.pyx.o.html").is_file()

    # cython -M produced a depfile that lists the cimported .pxd, so a change to
    # it triggers a rebuild.
    depfile = build_dir / "CMakeFiles/simple.dir/simple.pyx.o.c.dep"
    assert depfile.is_file()
    assert "helper.pxd" in depfile.read_text()


@pytest.mark.parametrize("output_arg", ["empty", "relative", "absolute"])
def test_output_argument(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path, output_arg: str
) -> None:
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


def test_implicit_cxx(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
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


def test_directive_cxx(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    package_dir = tmp_path / "pkg4"
    shutil.copytree(DIR / "packages/simple", package_dir)
    monkeypatch.chdir(package_dir)

    # Enable both C and CXX so the language is decided by the directive alone
    # (the deduction path is only reached when both languages are enabled).
    cmakelists = Path("CMakeLists.txt")
    txt = (
        cmakelists.read_text()
        .replace("LANGUAGE C", "")
        .replace("LANGUAGES C", "LANGUAGES C CXX")
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


def test_multiple_packages(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
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


def test_depends_generated_pxd(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    package_dir = tmp_path / "pkg7"
    shutil.copytree(DIR / "packages/depends", package_dir)
    monkeypatch.chdir(package_dir)

    build_dir = tmp_path / "build"

    # The .pyx cimports a .pxd that is generated by another target and does not
    # exist at configure time. Without the DEPENDS forwarding, cython would run
    # before the .pxd is generated and fail to find it.
    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "helper.pxd" in build_files
    assert "simple.c.dep" in build_files
    assert "simple.c" in build_files


def test_cpp_library(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.chdir(DIR / "packages/cpp_library")
    build_dir = tmp_path / "build"

    # The .pyx wraps a C++ class from a library built in the same project; the
    # extension module is linked against that library via target_link_libraries.
    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "wrapper.cxx.dep" in build_files
    assert "wrapper.cxx" in build_files


def test_genex_cython_args(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path, capfd: pytest.CaptureFixture[str]
) -> None:
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
