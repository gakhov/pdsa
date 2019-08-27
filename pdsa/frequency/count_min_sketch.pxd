from libc.stdint cimport uint64_t, uint32_t, uint8_t


cdef class CountMinSketch:
    cdef uint32_t _MAX_COUNTER_VALUE

    cdef uint8_t num_of_counters
    cdef uint32_t length_of_counter

    cdef uint64_t _length
    cdef uint8_t[:] _seeds
    cdef uint32_t[:] _counter

    cpdef void add(self, object element) except *
    cpdef uint32_t frequency(self, object element) except *
    cpdef size_t sizeof(self)

    cdef bint _increment_counter(self, const uint64_t index)
    cdef uint32_t _hash(self, object element, uint8_t seed)
