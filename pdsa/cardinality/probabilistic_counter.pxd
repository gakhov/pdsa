from libc.stdint cimport uint8_t, uint16_t, uint32_t

from pdsa.helpers.storage.bitvector cimport BitVector

cdef class ProbabilisticCounter:

    cdef size_t length
    cdef uint8_t size
    cdef uint16_t num_of_counters
    cdef bint with_small_cardinality_correction

    cdef uint16_t _seed
    cdef BitVector _counter

    cpdef void add(self, object element) except *
    cpdef size_t count(self)
    cpdef size_t sizeof(self)

    cdef uint32_t _hash(self, object element, uint32_t seed)
    cdef uint8_t _rank(self, uint32_t value)
    cdef uint8_t _value_by_counter(self, uint16_t counter_index)
