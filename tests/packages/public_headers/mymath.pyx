# cython: language_level=3

cdef public int add_one(int x):
    return x + 1

cdef api int add_two(int x):
    return x + 2
