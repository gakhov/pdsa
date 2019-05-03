from libc.stdint cimport uint8_t, uint16_t, uint32_t
from cpython.array cimport array

cdef class HyperLogLog:

    cdef uint8_t precision
    cdef uint8_t size
    cdef uint16_t num_of_counters

    cdef array _counter
    cdef uint32_t _seed
    cdef float _alpha

    cpdef void add(self, object element) except *
    cpdef size_t count(self)
    cpdef size_t sizeof(self)

    cdef uint32_t _hash(self, object element, uint32_t seed)
    cdef float _weight(self)
    cdef uint8_t _rank(self, uint32_t value)
