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

## Vendoring

You can vendor FindCython and/or UseCython into your package, as well. This
avoids requiring a dependency at build time and protects you against changes in
this package, at the expense of requiring manual re-vendoring to get bugfixes
and/or improvements. This mechanism is also ideal if you want to support direct
builds, outside of scikit-build-core.

You should make a CMake helper directory, such as `cmake`. Add this to your
`CMakeLists.txt` like this:

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
```

Then, you can vendor our files into that folder:

```bash
pipx run cython-cmake vendor cmake
```

If you want to just vendor one of the two files, use `--member FindCython` or
`--member UseCython`. You can rerun this command to revendor. The directory must
already exist.

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
