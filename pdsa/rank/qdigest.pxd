from libc.stdint cimport uint32_t, uint8_t

cdef class QuantileDigest:
    cdef uint8_t _compression_factor
    cdef uint32_t _min_range
    cdef uint32_t _max_range
    cdef uint8_t _tree_height
    cdef uint32_t _number_of_nodes

    cdef uint8_t _seed

    cpdef void add(self, object element, bint compress=*) except *
    cpdef void compress(self) except *

    # cpdef void quantile_query(self, uint8_t quantile) except *
    # cpdef void inverse_quantile_query(self, object element) except *
    # cpdef void range_query(self, uint8_t r) except *
    
    # cpdef size_t sizeof(self)
    # cpdef size_t total(self)

    cdef uint32_t _hash(self, object element, uint8_t seed)
    # def get_all_on_level(self, uint8_t level)
    cdef bint merge_if_needed(self, uint32_t bucket_id)
    cdef bint qdigest_property(self, size_t counts_sum)
    cdef uint32_t _bucket_id(self, uint32_t value)
