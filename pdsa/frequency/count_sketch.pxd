from libc.stdint cimport uint64_t, uint32_t, uint8_t
from libc.stdint cimport int32_t


cdef class CountSketch:
    cdef int32_t _MAX_COUNTER_VALUE
    cdef int32_t _MIN_COUNTER_VALUE

    cdef uint8_t num_of_counters
    cdef uint32_t length_of_counter

    cdef uint64_t _length
    cdef uint8_t[:] _seeds
    cdef uint8_t[:] _seeds_for_switcher
    cdef int32_t[:] _counter

    cpdef void add(self, object element) except *
    cpdef uint32_t frequency(self, object element) except *
    cpdef size_t sizeof(self)

    cdef bint _update_counter(self, const uint64_t index, const bint reverse)
    cdef uint32_t _hash(self, object element, uint8_t seed)
