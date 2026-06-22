from __future__ import annotations

import enum
import sys
from typing import TYPE_CHECKING

if TYPE_CHECKING:
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
    for member in Members:
        # Member names match the .cmake filenames (FindCython, UseCython).
        if member in members:
            filename = f"{member.name}.cmake"
            source = cmake_dir / filename
            (target / filename).write_text(
                source.read_text(encoding="utf-8"), encoding="utf-8"
            )
