from libc.stdint cimport uint32_t

from pdsa.helpers.storage.bitvector cimport BitVector

cdef class ProbabilisticCounter:

    cdef size_t length
    cdef uint32_t size
    cdef uint32_t num_of_hashes

    cdef uint32_t[:] _seeds
    cdef BitVector _counter

    cpdef void add(self, object element) except *
    cpdef size_t count(self)
    cpdef size_t sizeof(self)

    cdef uint32_t _hash(self, object element, uint32_t seed)
    cdef uint32_t _rank(self, uint32_t value)
    cdef size_t _count_by_counter(self, uint32_t counter_index)
