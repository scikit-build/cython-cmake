# cython-cmake

[![Actions Status][actions-badge]][actions-link]

<!--
[![Documentation Status][rtd-badge]][rtd-link]
-->

[![PyPI version][pypi-version]][pypi-link]
[![PyPI platforms][pypi-platforms]][pypi-link]

<!--
[![GitHub Discussion][github-discussions-badge]][github-discussions-link]
-->

<!-- SPHINX-START -->

This provides helpers for using Cython. Use:

```cmake
find_package(Cython MODULE REQUIRED VERSION 3.0)
```

If you find Python beforehand, the search will take this into account. You can
specify a version range on CMake 3.19+. This will define a `Cython::Cython`
target (along with a matching `CYTHON_EXECUTABLE` variable). It will also
provide the following helper function:

```cmake
Cython_compile_pyx(<pyx_file>
                  [LANGUAGE C | CXX]
                  [CYTHON_ARGS <args> ...]
                  [OUTPUT <OutputFile>]
                  [OUTPUT_VARIABLE <OutputVariable>]
                  )
```

This function takes a pyx file and makes a matching `.c` / `.cxx` file in the
current binary directory (exact path can be specified with `OUTPUT`). The
location of the produced file is placed in the variable specified by
`OUTPUT_VARIABLE` if given. Extra arguments to the Cython executable can be
given with `CYTHON_ARGS`, and if this is not set, it will take a default from a
`CYTHON_ARGS` variable.

If the `LANGUAGE` is not given, and both `C` and `CXX` are enabled globally,
then the language will try to be deduced from a `# distutils: language=...`
comment in the source file, and C will be used if not found.

This utility relies on the `DEPFILE` feature introduced for Ninja in CMake 3.7,
and added for Make in CMake 3.20, and Visual Studio & Xcode in CMake 3.21.

## Example

```cmake
find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED)

cython_compile_pyx(simple.pyx LANGUAGE C OUTPUT_VARIABLE simple_c)

python_add_library(simple MODULE "${simple_c}" WITH_SOABI)
```

## scikit-build-core

To use this package with scikit-build-core, you need to include it in your build
requirements:

```toml
[build-system]
requires = ["scikit-build-core", "cython", "cython-cmake"]
build-backend = "scikit_build_core.build"
```

It is also recommended to require CMake 3.21:

```toml
[tool.scikit-build]
cmake.version = ">=3.21"
```

<!-- prettier-ignore-start -->
[actions-badge]:            https://github.com/scikit-build/cython-cmake/workflows/CI/badge.svg
[actions-link]:             https://github.com/scikit-build/cython-cmake/actions
[github-discussions-badge]: https://img.shields.io/static/v1?label=Discussions&message=Ask&color=blue&logo=github
[github-discussions-link]:  https://github.com/scikit-build/cython-cmake/discussions
[pypi-link]:                https://pypi.org/project/cython-cmake/
[pypi-platforms]:           https://img.shields.io/pypi/pyversions/cython-cmake
[pypi-version]:             https://img.shields.io/pypi/v/cython-cmake
[rtd-badge]:                https://readthedocs.org/projects/cython-cmake/badge/?version=latest
[rtd-link]:                 https://cython-cmake.readthedocs.io/en/latest/?badge=latest

<!-- prettier-ignore-end -->
