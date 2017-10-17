from libc.stdint cimport uint32_t, uint8_t

cdef class QuantileDigest:
    cdef uint8_t _compression factor
    cdef uint32_t _min_range
    cdef uint32_t _max_range

    cdef uint8_t _seed

    cpdef void add(self, object element, bint compress=*) except *
    cpdef void compress(self, object element) except *

    cpdef void quantile_query(self, uint8_t quantile) except *
    cpdef void inverse_quantile_query(self, object element) except *
    cpdef void range_query(self, uint8_t r) except *
    
    cpdef size_t sizeof(self)
    cpdef size_t total(self)

    cdef uint32_t _hash(self, object element, uint8_t seed)

