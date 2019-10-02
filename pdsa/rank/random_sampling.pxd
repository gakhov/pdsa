from cpython.array cimport array
from libc.stdint cimport uint32_t, uint16_t, uint8_t


cdef class RandomSampling:
    cdef uint16_t number_of_buffers
    cdef uint16_t buffer_capacity
    cdef uint8_t height

    cdef size_t _number_of_elements
    cdef uint32_t _length

    cdef list _queue
    cdef array _buffer
    cdef array _element_existance_mask
    cdef array _buffer_levels
    cdef array _buffer_emptiness_mask

    cpdef uint32_t quantile_query(self, float quantile) except *
    cpdef size_t inverse_quantile_query(self, uint32_t element) except *
    cpdef size_t interval_query(self, uint32_t start, uint32_t end) except *

    cpdef size_t sizeof(self)
    cpdef size_t count(self)
    cpdef void add(self, uint32_t element)

    cdef uint8_t _active_level(self)
    cdef uint16_t _next_buffer_id(self, uint8_t active_level)
    cdef void _collapse(self, uint8_t active_level)
    cdef void _insert(self, uint16_t buffer_id, uint32_t element)