from cpython.array cimport array
from libc.stdint cimport uint32_t, uint16_t, uint8_t


cdef class RandomSampling:
    cdef uint16_t number_of_buffers
    cdef uint16_t buffer_capacity
    cdef uint8_t height

    cdef array _buffers
    cdef array _buffers
    cdef array _buffers

    cpdef void consume(self, object dataset)

    cpdef uint32_t quantile_query(self, float quantile) except *
    cpdef size_t inverse_quantile_query(self, uint32_t element) except *
    cpdef size_t interval_query(self, uint32_t start, uint32_t end) except *

    cpdef size_t sizeof(self)
    cpdef size_t count(self)

    cdef uint8_t _active_level(self)
    cdef void _collapse(self, uint8_t active_level)
    cdef uint16_t _get_next_empty_buffer_id(self, uint8_t active_level)