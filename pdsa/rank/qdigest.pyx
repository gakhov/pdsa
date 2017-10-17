import cython

from libc.math cimport log, round
from libc.stdint cimport uint32_t, uint8_t, UINT32_MAX
from libc.stdlib cimport rand

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class QuantileDigest:

    def __cinit__(self, const uint8_t compression_factor):
        """Create qdigest with requested compression factor.

        """
        if compression_factor < 1:
            raise ValueError("Compression factor")

        self._compression_factor = compression_factor
        self._min_range = 0
        self._max_range = 2**32 - 1  # UINT32_MAX since uint32 hash function
        
        self._tree_height = math.log(self._max_range + 1, 2) + 1  # 32+1=33
        self._number_of_nodes = 2**self._tree_height - 1 
        self._total = 0

        self._seed = <uint8_t>(rand())

        self._qdigest = list?
        # https://stackoverflow.com/questions/7403966

        # cdef size_t index
        # for index in xrange(self.length):
        #     self._counter[index] = 0


    cdef uint32_t _hash(self, object key, uint8_t seed):
        # self.algorithm = "mmh3_x86_32bit"
        return mmh3_x86_32bit(key, seed)

    cdef size_t _bucket_id(self, uint32_t value):
        # In the full and complete binary tree build for the
        # binary parition of a range [0 .. self._max_range]
        # is the value-th value (from left) in the last level (=height).
        # The index of the first node (from left to right)
        # at the last level is _number_of_nodes - self._max_range
        # (because exactly self._max_range nodes at the last level).
        return self._number_of_nodes - self._max_range + value

    cdef void add(self, object element, bint compress=False):
        hashed = self._hash(element, self._seed)
        if hashed > self._max_range or hashed < self._min_range:
            raise ValueError("Value out of range")

        canonical_bucket_id = self._bucket_id(hashed)

        path = []
        bucket_id = canonical_bucket_id
        while bucket_id > 0:
            path.append(bucket_id)
            bucket_id = bucket_id // 2

        closest_parent_id_in_digest = 0
        for ind, (bucket_id, _) in enumerate(Digest):
            if bucket_id in path and bucket_id > closest_parent_id_in_digest:
                closest_parent_id_in_digest = bucket_id
                bucket_index = ind

        if closest_parent_id_in_digest == canonical_bucket_id:
            Digest[ind][1] += 1  # update counts
        else:
            Digest.append((canonical_bucket_id, 1))
            for bucket_id in path[1:]:
                if bucket_id <= closest_parent_id_in_digest:
                    # break because path list is sorted on creation
                    break

                Digest.append((bucket_id, 0))

        self._total += 1

        if compress:
            self.compress()

    cdef void compress(self):

        while level > 0:

        - build full binary tree from the qdigest
        - compress it
        - save qdigest1 

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







