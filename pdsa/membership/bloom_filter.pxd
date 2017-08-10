from libc.stdint cimport uint32_t, uint8_t

from pdsa.helpers.storage.bitvector cimport BitVector

cdef class BloomFilter:
    cdef size_t length
    cdef uint8_t num_of_hashes

    cdef size_t capacity
    cdef float error_rate

    cdef uint8_t[:] _seeds
    cdef BitVector _table

    cpdef void add(self, object element) except *
    cpdef bint test(self, object element) except *
    cpdef size_t count(self)
    cpdef size_t sizeof(self)

    cdef uint32_t _hash(self, object element, uint8_t seed)
