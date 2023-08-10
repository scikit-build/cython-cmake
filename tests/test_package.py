from __future__ import annotations

import importlib.metadata

import cython_cmake as m


def test_version():
    assert importlib.metadata.version("cython_cmake") == m.__version__
