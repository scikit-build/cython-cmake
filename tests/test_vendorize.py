from __future__ import annotations

import sys
from pathlib import Path

import pytest

from cython_cmake.__main__ import main

DIR = Path(__file__).parent.resolve()
FIND_CYTHON = DIR.parent.joinpath("src/cython_cmake/cmake/FindCython.cmake").read_text()
USE_CYTHON = DIR.parent.joinpath("src/cython_cmake/cmake/UseCython.cmake").read_text()


def test_copy_files(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    path = tmp_path / "copy_all"
    path.mkdir()

    monkeypatch.setattr(sys, "argv", [sys.executable, "vendor", str(path)])
    main()

    assert path.joinpath("FindCython.cmake").read_text() == FIND_CYTHON
    assert path.joinpath("UseCython.cmake").read_text() == USE_CYTHON


def test_copy_only_find(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    path = tmp_path / "copy_find"
    path.mkdir()

    monkeypatch.setattr(
        sys, "argv", [sys.executable, "vendor", str(path), "--member", "FindCython"]
    )
    main()

    assert path.joinpath("FindCython.cmake").read_text() == FIND_CYTHON
    assert not path.joinpath("UseCython.cmake").exists()
