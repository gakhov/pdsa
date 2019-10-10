from cpython.array cimport array
from libc.stdint cimport uint64_t, uint32_t, uint16_t, uint8_t


cdef class _MetaBuffer:
    cdef uint8_t number_of_buffers
    cdef uint32_t elements_per_buffer
    cdef uint64_t length

    cdef array _array
    cdef array _mask

    cdef size_t sizeof(self)
    cdef tuple location(self, uint8_t buffer_id)
    cdef uint32_t num_of_elements(self, uint8_t buffer_id)
    cdef uint32_t capacity(self, uint8_t buffer_id)
    cdef bint is_empty(self, uint8_t buffer_id)
    cdef list get_elements(self, uint8_t buffer_id)
    cdef list pop_elements(self, uint8_t buffer_id)
    cdef void populate(self, uint8_t buffer_id, list elements)

    cdef list _retrive_elements(self, uint8_t buffer_id, bint pop=*)


cdef class RandomSampling:
    cdef uint8_t height

    cdef size_t _number_of_elements

    cdef uint32_t _seed

    cdef list _queue
    cdef _MetaBuffer _buffer
    cdef array _levels

    cpdef uint32_t quantile_query(self, float quantile) except *
    cpdef size_t inverse_quantile_query(self, uint32_t element) except *
    cpdef size_t interval_query(self, uint32_t start, uint32_t end) except *

    cpdef size_t sizeof(self)
    cpdef size_t count(self)
    cpdef void add(self, uint32_t element)

    cdef uint16_t _active_level(self)
    cdef uint8_t _find_empty_buffer(self)
    cdef void _collapse(self)
    cdef void _commit(self, bint force=*)
