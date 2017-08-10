"""
BitVectorCounter.

BitVectorCounter is an array of C++ BitCounters (8 bits long, encoded
two 4-bits counters) that supports flatten navigation.
"""

import cython

from libc.math cimport ceil
from cpython.mem cimport PyMem_Malloc, PyMem_Free

cdef uint8_t NUMBER_OF_SUBCOUNTERS = 2


cdef class BitVectorCounter:

    __slots__ = ()

    @cython.boundscheck(False)
    @cython.wraparound(False)
    # @cython.cdivision(True)
    def __cinit__(self, const size_t length):
        """Allocate and initialize the vector of counters.

        NOTE: each BitCounter includes 2 counters (4-bits), so we
        the length can be rounded up to to closest even number.

        It's guaranteed that all counters in newly created structure will
        be reset (set to 0).
        """

        self.length = length + (-length & (NUMBER_OF_SUBCOUNTERS - 1))
        self.size = self.length // NUMBER_OF_SUBCOUNTERS

        self.vector = <BitCounter *>PyMem_Malloc(self.size * sizeof(BitCounter))

        cdef size_t bucket
        for bucket in range(self.size):
            self.vector[bucket].reset()


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def increment(self, const size_t index):
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t counter_number

        bucket, counter_number = divmod(index, NUMBER_OF_SUBCOUNTERS)
        return self.vector[bucket].inc(counter_number)


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def decrement(self, const size_t index):
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t counter_number

        bucket, counter_number = divmod(index, NUMBER_OF_SUBCOUNTERS)
        return self.vector[bucket].dec(counter_number)


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def __getitem__(self, const size_t index):
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t counter_number

        bucket, counter_number = divmod(index, NUMBER_OF_SUBCOUNTERS)
        return self.vector[bucket].value(counter_number)


    def __dealloc__(self):
        PyMem_Free(self.vector)

    def __repr__(self):
        return "<BitVectorCounter (size: {}, length: {})>".format(
            self.size,
            self.length
        )

    def __len__(self):
        return self.length

    cpdef size_t sizeof(self):
        return self.size * sizeof(BitCounter)

