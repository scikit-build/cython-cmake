from __future__ import annotations

import importlib.metadata
import shutil
import subprocess
import zipfile
from pathlib import Path

import pytest
from scikit_build_core.build import build_wheel

import cython_cmake as m

DIR = Path(__file__).parent.resolve()

CYTHON_VERSION = tuple(
    int(x) for x in importlib.metadata.version("cython").split(".")[:2]
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


def test_pure_python(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    # Cython also compiles pure-Python ".py" modules (PEP 484 / "pure Python
    # mode"); cython_transpile is filename-agnostic so this should just work.
    monkeypatch.chdir(DIR / "packages/pure_python")
    build_dir = tmp_path / "build"

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "square.c.dep" in build_files
    assert "square.c" in build_files


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

    # MODULE_NAME should give the module its fully-qualified dotted name, even
    # though it lives outside any package directory Cython could walk.
    module3_c = (build_dir / "__/module.c").read_text()
    assert "package1.package3.module" in module3_c


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


def test_include_directories(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.chdir(DIR / "packages/include_directories")
    build_dir = tmp_path / "build"

    # simple.pyx cimports helper.pxd, which lives in the includes/ subdir rather
    # than next to the source, so the cimport only resolves via the
    # INCLUDE_DIRECTORIES keyword.
    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
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


def test_public_headers(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.chdir(DIR / "packages/public_headers")
    build_dir = tmp_path / "build"

    # mymath.pyx has cdef public / cdef api declarations; a separate target
    # #includes the generated headers. Without cython_transpile declaring them
    # as outputs (and returning their paths for OBJECT_DEPENDS), that target has
    # no rule ordering it after Cython and the build races on the header.
    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "mymath.c" in build_files
    assert "mymath.h" in build_files
    assert "mymath_api.h" in build_files


def test_public_headers_multisuffix_output(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    package_dir = tmp_path / "pkg_headers"
    shutil.copytree(DIR / "packages/public_headers", package_dir)
    monkeypatch.chdir(package_dir)

    build_dir = tmp_path / "build"

    # Cython names the headers by stripping only the final extension of the
    # output file (os.path.splitext), so OUTPUT mymath.generated.c yields
    # mymath.generated.h / mymath.generated_api.h. Assert the returned
    # variables point at those, not at mymath.h (NAME_WE would strip both).
    cmakelists = Path("CMakeLists.txt")
    txt = cmakelists.read_text().replace(
        "OUTPUT_VARIABLE mymath_c",
        'OUTPUT "mymath.generated.c"\n  OUTPUT_VARIABLE mymath_c',
    )
    txt += (
        '\nset(_expected "${CMAKE_CURRENT_BINARY_DIR}/mymath.generated.h")\n'
        "if(NOT mymath_h STREQUAL _expected)\n"
        '  message(FATAL_ERROR "wrong public header path: ${mymath_h}")\n'
        "endif()\n"
        'set(_expected "${CMAKE_CURRENT_BINARY_DIR}/mymath.generated_api.h")\n'
        "if(NOT mymath_api_h STREQUAL _expected)\n"
        '  message(FATAL_ERROR "wrong api header path: ${mymath_api_h}")\n'
        "endif()\n"
    )
    cmakelists.write_text(txt)

    consumer = Path("consumer.c")
    consumer.write_text(
        consumer.read_text().replace('"mymath.h"', '"mymath.generated.h"')
    )

    wheel = build_wheel(
        str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []}
    )

    with zipfile.ZipFile(tmp_path / wheel) as f:
        file_names = set(f.namelist())
    assert len(file_names) == 4

    build_files = {x.name for x in build_dir.iterdir()}
    assert "mymath.generated.c" in build_files
    assert "mymath.generated.h" in build_files
    assert "mymath.generated_api.h" in build_files


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

    # The annotation HTML must be declared as a BYPRODUCTS of the custom
    # command so the build system knows to clean it up. Only Ninja is
    # guaranteed to remove byproducts on clean (MSBuild is not).
    if build_dir.joinpath("build.ninja").is_file():
        cmake = shutil.which("cmake")
        assert cmake is not None
        subprocess.run(
            [cmake, "--build", str(build_dir), "--target", "clean"], check=True
        )
        build_files = {x.name for x in build_dir.iterdir()}
        assert "simple.html" not in build_files


@pytest.mark.skipif(
    CYTHON_VERSION < (3, 1),
    reason="freethreading_compatible directive needs Cython 3.1+",
)
def test_freethreading_compatible(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    package_dir = tmp_path / "pkg7"
    shutil.copytree(DIR / "packages/simple", package_dir)
    monkeypatch.chdir(package_dir)

    build_dir = tmp_path / "build"

    cmakelists = Path("CMakeLists.txt")
    txt = cmakelists.read_text().replace(
        "# PLACEHOLDER", 'CYTHON_ARGS "-X;freethreading_compatible=True"'
    )
    cmakelists.write_text(txt)

    build_wheel(str(tmp_path), {"build-dir": str(build_dir), "wheel.license-files": []})

    # The module declares it runs without the GIL only when the directive is set.
    generated_c = (build_dir / "simple.c").read_text()
    assert "PyUnstable_Module_SetGIL(__pyx_m, Py_MOD_GIL_NOT_USED)" in generated_c
