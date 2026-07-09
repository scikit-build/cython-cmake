// A target other than the extension module, consuming the cdef public header
// Cython generates for mymath.pyx. It #includes the header and calls the
// exported function, proving the header is a real, dependable build output.
#include "mymath.h"

int consumer_add_one(int x) { return add_one(x); }
