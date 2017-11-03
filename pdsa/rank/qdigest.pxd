from libc.stdint cimport uint64_t, uint32_t, uint8_t

cdef class QuantileDigest:
    cdef uint8_t compression_factor
    cdef uint8_t range_in_bits

    cdef uint32_t _min_range
    cdef uint32_t _max_range

    cdef uint8_t _tree_height
    cdef uint64_t _max_number_of_nodes

    cdef uint64_t _number_of_buckets
    cdef float _exact_boundary_value

    cdef dict _qdigest

    cpdef void add(self, uint32_t element, bint compress=*) except *
    cpdef void compress(self)

    cpdef uint32_t quantile_query(self, float quantile) except *
    cpdef size_t inverse_quantile_query(self, uint32_t element) except *
    cpdef size_t interval_query(self, uint32_t start, uint32_t end) except *

    cpdef size_t sizeof(self)
    cpdef size_t count(self)
    cpdef void merge(self, QuantileDigest other) except *

    cdef uint64_t _bucket_canonical_id(self, uint32_t value)
    cdef uint64_t _bucket_parent_id(self, uint32_t bucket_id)
    cdef uint64_t _bucket_sibling_id(self, uint32_t bucket_id)

    cdef uint8_t _bucket_level(self, uint64_t bucket_id)
    cdef tuple _bucket_range(self, uint64_t bucket_id)

    cdef list _buckets_on_level(self, uint8_t level)
    cdef bint _merge_if_needed(self, uint64_t bucket_id)
    cdef bint _delete_bucket_if_exists(self, uint64_t bucket_id) except *
    cdef bint _is_worth_to_store(self, size_t counts_sum)
