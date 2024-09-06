from __future__ import annotations

import argparse
import enum
import functools
import operator
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from ._version import version as __version__
from .vendor import Members, vendorize

__all__ = ["main"]


def __dir__() -> list[str]:
    return __all__


class FlagAction(argparse.Action):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        enum_type = kwargs.pop("type", None)
        if enum_type is None:
            msg = "enum type is required"
            raise ValueError(msg)
        if not issubclass(enum_type, enum.Flag):
            msg = "type must be an Flag when using FlagAction"
            raise TypeError(msg)

        kwargs.setdefault("choices", tuple(e.name for e in enum_type))

        super().__init__(*args, **kwargs)

        self._enum = enum_type

    def __call__(
        self,
        parser: argparse.ArgumentParser,  # noqa: ARG002
        namespace: argparse.Namespace,
        values: str | Sequence[Any] | None,
        option_string: str | None = None,  # noqa: ARG002
    ) -> None:
        if not isinstance(values, list):
            values = [values]
        flags = functools.reduce(operator.or_, (self._enum[e] for e in values))
        setattr(namespace, self.dest, flags)


def main() -> None:
    """
    Entry point.
    """
    parser = argparse.ArgumentParser(
        prog="cython_cmake", description="CMake Cython module helper"
    )
    parser.add_argument(
        "--version", action="version", version=f"%(prog)s {__version__}"
    )
    subparser = parser.add_subparsers(required=True)
    vendor_parser = subparser.add_parser("vendor", help="Vendor CMake helpers")
    vendor_parser.add_argument(
        "target", type=Path, help="Directory to vendor the CMake helpers"
    )
    vendor_parser.add_argument(
        "--members",
        type=Members,
        nargs="*",
        action=FlagAction,
        default=functools.reduce(operator.or_, list(Members)),
        help="Members to vendor, defaults to all",
    )
    args = parser.parse_args()
    vendorize(args.target, args.members)


if __name__ == "__main__":
    main()
