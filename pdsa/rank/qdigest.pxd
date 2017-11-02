from libc.stdint cimport uint64_t, uint32_t, uint8_t

cdef class QuantileDigest:
    cdef uint8_t compression_factor
    cdef uint8_t range_in_bits
    cdef bint with_hashing

    cdef uint32_t _min_range
    cdef uint32_t _max_range

    cdef uint8_t _tree_height
    cdef uint64_t _max_number_of_nodes

    cdef uint64_t _number_of_buckets
    cdef float _exact_boundary_value

    cdef dict _qdigest
    cdef uint8_t _seed

    cpdef void add(self, object element, bint compress=*) except *
    cpdef void compress(self) except *

    # cpdef void quantile_query(self, uint8_t quantile) except *
    # cpdef void inverse_quantile_query(self, object element) except *
    # cpdef void range_query(self, uint8_t r) except *

    cpdef size_t sizeof(self)
    cpdef size_t count(self)

    cdef uint32_t _hash(self, object element, uint8_t seed)
    cdef uint64_t _bucket_canonical_id(self, uint32_t value)
    cdef uint64_t _bucket_parent_id(self, uint32_t bucket_id)
    cdef uint64_t _bucket_sibling_id(self, uint32_t bucket_id)

    cdef list _buckets_on_level(self, uint8_t level)
    cdef bint _merge_if_needed(self, uint64_t bucket_id)
    cdef bint _delete_bucket_if_exists(self, uint64_t bucket_id)
    cdef bint _is_worth_to_store(self, size_t counts_sum)

