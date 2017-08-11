from libc.stdint cimport uint32_t, uint8_t

from pdsa.helpers.storage.bitvector cimport BitVector
from pdsa.helpers.storage.bitvector_counter cimport BitVectorCounter

cdef class CountingBloomFilter:
    cdef size_t length
    cdef uint8_t num_of_hashes

    cdef size_t capacity
    cdef float error_rate

    cdef uint8_t[:] _seeds
    cdef BitVector _table
    cdef BitVectorCounter _counter

    cpdef void add(self, object element) except *
    cpdef bint test(self, object element) except *
    cpdef bint remove(self, object element) except *
    cpdef size_t count(self)
    cpdef size_t sizeof(self)

    cdef uint32_t _hash(self, object element, uint8_t seed)
