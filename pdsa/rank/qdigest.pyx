import cython

from libc.math cimport floor, log, round
from libc.stdint cimport uint64_t, uint32_t, uint8_t, UINT32_MAX
from libc.stdlib cimport rand

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class QuantileDigest:

    def __cinit__(self, const uint8_t range_in_bits, const uint8_t compression_factor):
        """Create qdigest with requested compression factor.

        """
        if compression_factor < 1:
            raise ValueError("Compression factor")

        self._compression_factor = compression_factor
        self._range_in_bits = range_in_bits
        self._min_range = 0
        self._max_range = 2**self._range_in_bits - 1

        self._tree_height = self._range_in_bits + 1
        self._number_of_nodes = 2**self._tree_height - 1
        self._total = 0

        # self._seed = <uint8_t>(rand())

        # print(UINT32_MAX, self._max_range)
        # print("_number_of_nodes", self._number_of_nodes)
        # print("height", self._tree_height)

        self._qdigest = {}

    # cdef uint32_t _hash(self, object key, uint8_t seed):
    #     # self.algorithm = "mmh3_x86_32bit"
    #     # return mmh3_x86_32bit(key, seed)
    #     return <uint32_t>key

    cdef uint64_t _bucket_id(self, uint32_t value):
        # In the full and complete binary tree build for the
        # binary parition of a range [0 .. self._max_range]
        # is the value-th value (from left) in the last level (=height).
        # The index of the first node (from left to right)
        # at the last level is _number_of_nodes - self._max_range
        # (because exactly self._max_range nodes at the last level).
        return self._number_of_nodes - self._max_range + value

    cpdef void add(self, uint32_t element, bint compress=False) except *:
        # cdef uint32_t hashed = self._hash(element, self._seed)
        # if hashed > self._max_range or hashed < self._min_range:
        #     raise ValueError("Value out of range")

        cdef uint64_t canonical_bucket_id = self._bucket_id(element)

        path = []
        cdef uint64_t bucket_id = canonical_bucket_id
        cdef uint64_t closest_parent_id_in_digest = 0
        while bucket_id > 0:
            if bucket_id in self._qdigest:
                closest_parent_id_in_digest = bucket_id
                break
            bucket_id = bucket_id // 2  # get parent

        # assert closest_parent_id_in_digest > 0

        if closest_parent_id_in_digest == canonical_bucket_id:
            self._qdigest[canonical_bucket_id] += 1  # update counts
        else:
            self._qdigest[canonical_bucket_id] = 1
            bucket_id = canonical_bucket_id
            while bucket_id > 0:
                bucket_id = bucket_id // 2
                if bucket_id <= closest_parent_id_in_digest:
                    break
                self._qdigest[bucket_id] = 0

        self._total += 1

        if compress:
            self.compress()

    cdef bint qdigest_property(self, size_t counts_sum):
        cdef size_t boundary_value = <size_t>(floor(self._total / float(self._compression_factor)))
        boundary_value = max(<uint8_t>1, boundary_value)
        if counts_sum <= boundary_value:
            return False
        return True

    def debug(self):
        return self._qdigest

    cdef bint merge_if_needed(self, uint64_t current_bucket_id):
        if current_bucket_id == 1:
            return False

        cdef uint64_t parent_bucket_id
        cdef uint64_t sibling_bucket_id
        cdef uint8_t current_bucket_shift

        # i // 2 -> [2*i//2 + 0, 2*i//2 +1]

        parent_bucket_id, current_bucket_shift = divmod(
            current_bucket_id, 2)

        sibling_bucket_id = 2 * parent_bucket_id + current_bucket_shift ^ 1

        if current_bucket_id not in self._qdigest:
            # NOTE: might be already removed from the QDigest
            # after merging because of its sibling
            return False

        cdef size_t bucket_counts = self._qdigest[current_bucket_id]
        cdef size_t bucket_parent_counts = self._qdigest.get(
            parent_bucket_id, 0)
        cdef size_t bucket_sibling_counts = self._qdigest.get(
            sibling_bucket_id, 0)

        cdef size_t counts = bucket_counts + bucket_parent_counts + bucket_sibling_counts
        if self.qdigest_property(counts):
            return False

        print("count", counts, "<<<", bucket_counts, bucket_sibling_counts, bucket_parent_counts)
        print("merge", parent_bucket_id, "<==", current_bucket_id, sibling_bucket_id)

        if parent_bucket_id not in self._qdigest:
            self._total += 1

        self._qdigest[parent_bucket_id] = counts

        try:
            del self._qdigest[current_bucket_id]
        except:
            pass
        else:
            self._total -= 1

        try:
            del self._qdigest[sibling_bucket_id]
        except:
            pass
        else:
            self._total -= 1

        return True

    cdef list buckets_on_level(self, uint8_t level):
        """Get all buckets from qdigest that are on the `level`.

        Parameters
        ----------
        level : `int`
            The level index.

        Returns
        -------
        :obj:list
            List of bucket ids from level `level` that are included in
            qdigest data structure.

        Note
        ----
            For full and complete binary tree built from a binary
            partition, the buckets from level `k` have
            indices 2^{k-1} .. 2^{k} - 1.

        """
        cdef uint64_t bucket_ids_start = 2**(level - 1)
        cdef uint64_t bucket_ids_end = 2 * bucket_ids_start -  1

        # we iterate over qdigest since it has less buckets,
        # then the average level (may be do that only if layer > X)
        cdef list buckets = []
        for bucket_id in self._qdigest:
            if bucket_ids_start <= bucket_id <= bucket_ids_end:
                buckets.append(bucket_id)
        return buckets

    cpdef void compress(self) except *:
        if self._total <= self._compression_factor:
            return

        cdef uint8_t level =  self._tree_height
        while level > 0:
            buckets = self.buckets_on_level(level)
            for bucket_id in buckets:
                self.merge_if_needed(bucket_id)
            print(self._qdigest)
            level -= 1


        # Parent of node i is node i / 2, unless i = 1.
        # Node 1 is the root and has no parent.

        # Left child of node i is node 2i, unless 2i > n,
        # where n is the number of nodes.
        # • If 2i > n, node i has no left child.

        # For efficiency,
        # the data can be stored in such a way that explicit pointers are not
        # necessary: for node data stored at index i, the two child nodes are at
        # index (2 * i + 1) and (2 * i + 2); the parent node is (i - 1) // 2
        # (where // indicates integer division).

        # Given a
        # specified leaf_size (the minimum number of points in any node), it is
        # possible to show that a balanced tree will have
        #
        #     n_levels = 1 + max(0, floor(log2((n_samples - 1) / leaf_size)))
        #
        # in order to satisfy
        #
        #     leaf_size <= min(n_points) <= 2 * leaf_size
        #
        # with the exception of the special case where n_samples < leaf_size.
        # for a given number of levels, the number of nodes in the tree is given by
        #
        #     n_nodes = 2 ** n_levels - 1







