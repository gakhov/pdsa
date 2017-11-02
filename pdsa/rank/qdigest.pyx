"""

Quantile Digest.

Quantile Digest or q-digest is a tree-based stream summary algorithm
that was proposed by Nisheeth Shrivastava, Subhash Suri et al. in
2004 in the context of monitoring distributed data
from sensors.

References
----------
[1] Shrivastava, N., et al
    Medians and Beyond: New Aggregation Techniques for Sensor Networks.
    Proceedings of the 2nd International Conference on Embedded Networked Sensor Systems,
    Baltimore, MD, USA - November 03–05, 2004, pp. 58–66, ACM New York, NY (2004)
    https://www.inf.fu-berlin.de/lehre/WS11/Wireless/papers/AgrQdigest.pdf
"""

import cython

from libc.math cimport floor, log, round
from libc.stdint cimport uint64_t, uint32_t, uint8_t, UINT32_MAX
from libc.stdlib cimport rand

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit

cdef uint8_t ROOT_BUCKET = 1


cdef class QuantileDigest:
    """QuantileDigest is a realisation of q-digest algorithm.

    Example
    -------

    >>> from pdsa.rank.qdigest import QuantileDigest

    >>> qd = QuantileDigest(16, 5)
    >>> qd.add(42)
    >>> qd.merge()


    Note
    -----
        If requested, this implementation uses MurmurHash3 family of
        hash functions which yields a 32-bit hash value.

    Attributes
    ----------
    range_in_bits : :obj:`int`
        The maximal supported input non-negative integer values in bits.
    compression_factor : :obj:`int`
        The level of the compression in q-digest.

    """

    def __cinit__(self, const uint8_t range_in_bits, const uint8_t compression_factor,
                  const bint enable_hashing=False):
        """Create a q-digest with a requested compression factor.

        Parameters
        ----------
        range_in_bits : :obj:`int`
            The maximal supported input non-negative integer values in bits.
        compression_factor : :obj:`int`
            The level of the compression in q-digest.
        enable_hashing : bool
            A flag to enable hashing of input values (to support non-integers).

        Raises
        ------
        ValueError
            If `compression_factor` is 0 or negative.
        ValueError
            If hashing is required, but `range_in_bits` differs from 32.
        ValueError
            If `range_in_bits` is bigger than 32.

        """
        if compression_factor < 1:
            raise ValueError("Compression factor is too small")

        if enable_hashing and range_in_bits != 32:
            raise ValueError("Only 32-bit hashing is supported")

        if range_in_bits > 32:
            raise ValueError("Only ranges up to 2^{32} are supported")

        self.compression_factor = compression_factor
        self.range_in_bits = range_in_bits
        self.with_hashing = enable_hashing

        self._min_range = 0
        self._max_range = 2**self.range_in_bits - 1

        self._tree_height = self.range_in_bits + 1
        self._max_number_of_nodes = 2**self._tree_height - 1

        self._number_of_buckets = 0
        self._exact_boundary_value = 0

        self._seed = <uint8_t>(rand())
        self._qdigest = {}

    @classmethod
    def create_with_hashing(cls, const uint8_t compression_factor):
        """Create QuantileDigest that supports arbitrary types of inputs.

        Parameters
        ----------
        compression_factor : :obj:`int`
            The level of the compression in q-digest.

        Note
        ----
            Currently, we offer only 32-bit hash function that defines
            the range of the q-digest.

        """
        return cls(32, compression_factor, enable_hashing=True)

    cdef uint32_t _hash(self, object key, uint8_t seed):
        # self.algorithm = "mmh3_x86_32bit"
        # return mmh3_x86_32bit(key, seed)
        return <uint32_t>key

    cdef uint64_t _bucket_canonical_id(self, uint32_t value):
        """Compute the canonical bucket for the input value.

        Parameters
        ----------
        value : :obj:`int`
            The input value in the supported range.

        Returns
        -------
        :obj:`int`
            The ID of the canonical bucket.

        Note
        ----
            In the full and complete binary tree build for the
            binary parition of a range [0 .. self._max_range]
            is the value-th value (from left) in the last level (=height).

            The canonical bucket is a leaf bucket for the inserted value.

            The index of the first node (from left to right)
            at the last level is self._max_number_of_nodes - self._max_range
            (because exactly self._max_range nodes at the last level).\

        """
        return self._max_number_of_nodes - self._max_range + value

    @cython.cdivision(True)
    cdef uint64_t _bucket_parent_id(self, uint32_t bucket_id):
        """Compute the parent of the bucket.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket ID of the bucket whose parent is computed.

        Returns
        -------
        :obj:`int`
            The ID of the bucket's parent.

        Note
        ----
            In the full and complete binary tree build parent ID can be
            computed as integer division by 2 of the bucket's ID.

        """
        return bucket_id // 2

    cdef uint64_t _bucket_sibling_id(self, uint32_t bucket_id):
        """Compute the parent of the bucket.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket ID of the bucket whose sibling is computed.

        Note
        ----
            In the full and complete binary tree build every parent bucket
            has exactly 2 children. Suppose, the parent id is `i`, then
            children have ids `2 * i` and `2 * i + 1`. Thus, the id of the
            sibling can be computed by the XOR of binary shift of the
            current bucket ID.

        Returns
        -------
        :obj:`int`
            The ID of the bucket's sibling.

        """
        cdef uint64_t parent_bucket_id = self._bucket_parent_id(bucket_id)
        cdef uint8_t current_bucket_shift = bucket_id % 2

        return 2 * parent_bucket_id + current_bucket_shift ^ 1

    cdef list _buckets_on_level(self, uint8_t level):
        """Get all buckets from q-digest that exist on the level `level`.

        Parameters
        ----------
        level : :obj:`int`
            The `level` index.

        Returns
        -------
        list
            List of bucket IDs from level `level` that are included in
            q-digest data structure.

        Note
        ----
            For full and complete binary tree built from a binary
            partition, the buckets from level `k` have
            indices 2^{k-1} .. 2^{k} - 1.

        """
        cdef uint64_t bucket_ids_start = 2**(level - 1)
        cdef uint64_t bucket_ids_end = 2 * bucket_ids_start -  1

        # NOTE: We iterate over q-digest (instead of the tree)
        # since it has less buckets than the average level of full tree.
        # TODO: Does it make sense to iterate over all possible buckets'
        # ids if level is low (e.g., if layer < 5)

        cdef list buckets = []
        for bucket_id in self._qdigest:
            if bucket_ids_start <= bucket_id <= bucket_ids_end:
                buckets.append(bucket_id)
        return buckets

    @cython.cdivision(True)
    cpdef void add(self, object element, bint compress=False) except *:
        """Add element into the q-digest.

        Parameters
        ----------
        element : obj
            The input element. If hashing is not enabled the `element`
            will be automatically cast to uint32_t.
        compress : :obj:bint
            A flag to automatically compress q-digest structure after
            the addition is finished.

        Note
        ----
            By default, the q-digest isn't automatically compressed to
            optimize the complexity of the addition, especially in the
            cases when many elements are added sequentially without
            performing any rank queries to the data structure.

            We always insert a leaf bucket (canonical) for the input element
            and, if any, all missing parent nodes in the hierarchy (bottom up).

        Raises
        ------
        ValueError
            If value of the element is out of range.

        """
        cdef uint32_t value

        if not self.with_hashing:
            value = <uint32_t>element
        else:
            value = self._hash(element, self._seed)

        if value > self._max_range or value < self._min_range:
            raise ValueError("Value out of range")

        cdef uint64_t canonical_bucket_id = self._bucket_canonical_id(value)
        cdef uint64_t bucket_id = canonical_bucket_id
        cdef uint64_t closest_parent_id_in_digest = 0

        # NOTE: search for the closest existing parent
        while bucket_id > 0:
            if bucket_id in self._qdigest:
                closest_parent_id_in_digest = bucket_id
                break
            bucket_id = self._bucket_parent_id(bucket_id)

        # NOTE: Update counts for the canonical bucket
        # and create all missing parent nodes (with 0 counts)
        # in the hierarhy (bottom up).
        if closest_parent_id_in_digest == canonical_bucket_id:
            self._qdigest[canonical_bucket_id] += 1
        else:
            self._number_of_buckets += 1
            self._qdigest[canonical_bucket_id] = 1
            bucket_id = canonical_bucket_id
            while bucket_id > 0:
                bucket_id = self._bucket_parent_id(bucket_id)
                if bucket_id <= closest_parent_id_in_digest:
                    break
                self._qdigest[bucket_id] = 0
                self._number_of_buckets += 1

        self._exact_boundary_value += 1.0 / self.compression_factor

        if compress:
            self.compress()

    cdef bint _is_worth_to_store(self, size_t family_counts):
        """Decide if family of nodes with specified counts is worth to be stored.

        Parameters
        ----------
        family_counts : :obj:`int`
            The total counts of the family of nodes, parent and its 2
            children.

        Note
        ----
            If total counts of the family of nodes (parent and 2 children)
            are satisfy the q-digest property, they are worth to be stored.

            Boundary value for estimate significance of the counts in the
            q-digest propery is related on the ratio between number of elements
            already in the q-digest and current compression factor.

        Returns
        -------
        bool
            True if family of nodes is worth to be kept in the q-digest,
            False otherwise.

        """
        cdef size_t boundary_value = max(
            <uint8_t>1,
            <size_t>floor(self._exact_boundary_value)
        )
        return family_counts > boundary_value

    def debug(self):
        """Return q-digest for debug purposes."""
        return self._qdigest

    cdef bint _delete_bucket_if_exists(self, uint64_t bucket_id):
        """Delete bucket from q-digest if it's exists.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket to delete.

        Note
        ----
            Everytime when bucket if deleted, the number_of_buckets
            in the q-digest has to be decreased.

        Returns
        -------
        bool
            True if delete was performed, False otherwise.

        """
        try:
            del self._qdigest[bucket_id]
        except KeyError:
            return False

        self._number_of_buckets -= 1
        return True

    cdef bint _merge_if_needed(self, uint64_t current_bucket_id):
        """Merge family of nodes for the bucket to its parent.

        Parameters
        ----------
        current_bucket_id : :obj:`int`
            The bucket whose family if evaluated.

        Note
        ----
            To optimize q-digest, it's required to merge all non-significant
            families of nodes (parent and its children) and keep information
            about family counts at parent node only.

        Returns
        -------
        bool
            True if merge was performed, False otherwise.

        """
        # NOTE: Bucket might be already removed from the q-digest
        # after merging its family by evaluating the sibling
        if current_bucket_id not in self._qdigest:
            return False

        cdef size_t bucket_counts = self._qdigest[current_bucket_id]

        if current_bucket_id == ROOT_BUCKET:
            if bucket_counts <= 0:
                self._delete_bucket_if_exists(ROOT_BUCKET)
            return False

        cdef uint64_t parent_bucket_id = self._bucket_parent_id(current_bucket_id)
        cdef uint64_t sibling_bucket_id = self._bucket_sibling_id(current_bucket_id)

        cdef size_t bucket_parent_counts = self._qdigest.get(
            parent_bucket_id, 0)
        cdef size_t bucket_sibling_counts = self._qdigest.get(
            sibling_bucket_id, 0)

        cdef size_t family_counts = bucket_counts\
            + bucket_parent_counts\
            + bucket_sibling_counts

        if self._is_worth_to_store(family_counts):
            return False

        if parent_bucket_id not in self._qdigest:
            self._number_of_buckets += 1

        self._qdigest[parent_bucket_id] = family_counts
        self._delete_bucket_if_exists(current_bucket_id)
        self._delete_bucket_if_exists(sibling_bucket_id)

        return True

    cpdef void compress(self) except *:
        """Compress q-digest.

        Note
        ----
            The compression of q-digest is made by merge procedure
            (bottom up) according to q-digest property.

            If number of nodes in the digest is less than the
            required compression factor, there is no sense to merge.

        """
        if self._number_of_buckets <= self.compression_factor:
            return

        cdef uint8_t level =  self._tree_height
        while level > 0:
            buckets = self._buckets_on_level(level)
            for bucket_id in buckets:
                self._merge_if_needed(bucket_id)
            level -= 1

    def __repr__(self):
        return (
            "<QuantileDigest ("
            "compression: {}, "
            "range: [{}, {}], "
            "with_hashing: {}, "
            "length: {}"
            ")>"
        ).format(
            self.compression_factor,
            self._min_range, self._max_range,
            "on" if self.with_hashing else "off",
            self._number_of_buckets
        )

    def __len__(self):
        """Get number of buckets in q-digest.

        Returns
        -------
        :obj:`int`
            The number of buckets in q-digest.

        """
        return self._number_of_buckets

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Number of elements (incl. duplicates) in the q-digest.

        Returns
        -------
        :obj:`int`
            The number of unique elements already in the q-digest.

        Note
        ----
            While we can't say exactly which elements in the q-digest,
            (because the compression is a lossy operation), it's still
            possible to say how many in total elements were added.

        """
        return sum(self._qdigest.values())

    cpdef size_t sizeof(self):
        """Size of the q-digest in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the q-digest.

        """
        raise NotImplementedError
