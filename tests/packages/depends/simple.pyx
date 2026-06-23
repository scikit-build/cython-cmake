# cython: language_level=3
from helper cimport helper_square


def square(double x):
    return helper_square(x)
