# A .pxd that lives in a directory not next to the source, only reachable via
# the INCLUDE_DIRECTORIES keyword (mimics a cimport-able installed package).
cdef inline double helper_square(double x):
    return x * x
