# cython: language_level=3
# distutils: language = c++

cdef extern from "mylib.hpp":
    cdef cppclass Multiplier:
        Multiplier(int)
        int compute(int)


cdef class PyMultiplier:
    cdef Multiplier* _c

    def __cinit__(self, int factor):
        self._c = new Multiplier(factor)

    def __dealloc__(self):
        del self._c

    def compute(self, int value):
        return self._c.compute(value)
