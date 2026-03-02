from __future__ import annotations

import enum
import sys
from pathlib import Path

if sys.version_info < (3, 9):
    from importlib_resources import files
else:
    from importlib.resources import files

__all__ = ["Members", "vendorize"]


def __dir__() -> list[str]:
    return __all__


class Members(enum.Flag):
    FindCython = enum.auto()
    UseCython = enum.auto()


def vendorize(
    target: Path, members: Members = Members.FindCython | Members.UseCython
) -> None:
    """
    Vendorize files into a directory. Directory must exist.
    """
    if not target.is_dir():
        msg = f"Target directory {target} does not exist"
        raise AssertionError(msg)

    cmake_dir = files("cython_cmake") / "cmake"
    if Members.FindCython in members:
        find = cmake_dir / "FindCython.cmake"
        find_target = target / "FindCython.cmake"
        find_target.write_text(find.read_text(encoding="utf-8"), encoding="utf-8")

    if Members.UseCython in members:
        use = cmake_dir / "UseCython.cmake"
        use_target = target / "UseCython.cmake"
        use_target.write_text(use.read_text(encoding="utf-8"), encoding="utf-8")
