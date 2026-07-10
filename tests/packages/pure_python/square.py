# cython: language_level=3
"""Pure-Python mode module: valid Python, optionally compiled by Cython."""

import cython


def square(x: cython.double) -> cython.double:
    return x * x
