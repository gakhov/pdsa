from libc.stdint cimport uint32_t, uint8_t

from pdsa.helpers.storage.bitvector cimport BitVector

cdef class LinearCounter:
    cdef size_t length

    cdef size_t capacity

    cdef uint8_t _seed
    cdef BitVector _counter

    cpdef void add(self, object element) except *
    cpdef size_t count(self)
    cpdef size_t sizeof(self)

    cdef uint32_t _hash(self, object element, uint8_t seed)
