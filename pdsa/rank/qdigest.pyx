"""

Quantile Digest.

Quantile Digest, or q-digest, is a tree-based stream summary algorithm
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

from libc.math cimport ceil, floor, log, round
from libc.stdint cimport uint64_t, uint32_t, uint8_t, UINT32_MAX
from libc.stdlib cimport rand

cdef uint8_t ROOT_BUCKET = 1


cdef class QuantileDigest:
    """QuantileDigest is a realisation of q-digest algorithm.

    Example
    -------

    >>> from pdsa.rank.qdigest import QuantileDigest

    >>> qd = QuantileDigest(16, 5)
    >>> qd.add(42)
    >>> qd.compress()

    Attributes
    ----------
    range_in_bits : :obj:`int`
        The maximal supported input non-negative integer values in bits.
    compression_factor : :obj:`int`
        The level of the compression in q-digest.

    """

    def __cinit__(self, const uint8_t range_in_bits, const uint8_t compression_factor):
        """Create a q-digest with a requested compression factor.

        Parameters
        ----------
        range_in_bits : :obj:`int`
            The maximal supported input non-negative integer values in bits.
        compression_factor : :obj:`int`
            The level of the compression in q-digest.

        Raises
        ------
        ValueError
            If `compression_factor` is 0 or negative.
        ValueError
            If `range_in_bits` is bigger than 32.

        """
        if compression_factor < 1:
            raise ValueError("Compression factor is too small")

        if range_in_bits > 32:
            raise ValueError("Only ranges up to 2^{32} are supported")

        self.compression_factor = compression_factor
        self.range_in_bits = range_in_bits

        self._min_range = 0
        self._max_range = (<uint64_t>1 << self.range_in_bits) - 1

        self._tree_height = self.range_in_bits + 1
        self._max_number_of_nodes = (<uint64_t>1 << self._tree_height) - 1

        self._number_of_buckets = 0
        self._exact_boundary_value = 0

        self._qdigest = {}

    def _sortkey_buckets_by_range(self, tuple bucket):
        """Define sorting key for buckets for queries.

        Parameters
        ----------
        bucket : :obj:`int`
            The bucket (ID, counts) whose sorting key is to be computed.

        Note
        ----
            To perform quantile queries, buckets in the q-digest have
            to be sorted in increasing order of their max ranges, breaking
            the tie by putting smaller ranges (thus, bucket IDs) first.

        Returns
        -------
        tuple
            A tuple of values to sort by and break the tie.

        """
        cdef uint64_t bucket_id = bucket[0]
        cdef uint8_t level = self._bucket_level(bucket_id)
        return (level, -bucket_id)

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
            binary partition of a range [0 .. self._max_range]
            is the `value`-th value (from left) in the last level
            (that is equal to the tree's height).

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
            The bucket ID of the bucket whose parent is to be computed.

        Returns
        -------
        :obj:`int`
            The ID of the bucket's parent.

        Note
        ----
            In the full and complete binary tree, parent ID can be
            computed as integer division by 2 of the bucket's ID.

        """
        return bucket_id // 2

    cdef uint64_t _bucket_sibling_id(self, uint32_t bucket_id):
        """Compute the parent of the bucket.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket ID of the bucket whose sibling is to be computed.

        Note
        ----
            In the full and complete binary tree, every parent bucket
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
        cdef uint64_t bucket_ids_start = <uint64_t>1 << (level - 1)
        cdef uint64_t bucket_ids_end = 2 * bucket_ids_start - 1

        # NOTE: We iterate over q-digest (instead of the tree) since
        # it has fewer buckets than the average level of a full tree.
        # TODO: Does it make sense to iterate over all possible buckets'
        # ids if the level is small (e.g., if layer < 5)?

        cdef list buckets = []
        for bucket_id in self._qdigest:
            if bucket_ids_start <= bucket_id <= bucket_ids_end:
                buckets.append(bucket_id)
        return buckets

    cdef uint8_t _bucket_level(self, uint64_t bucket_id):
        """Compute level where the bucket is located.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket ID of the bucket whose level is to be computed.

        Note
        ----
            For full and complete binary tree built from a binary
            partition, the buckets from level `k` have
            indices 2^{k-1} .. 2^{k} - 1. Thus, finding the closest
            power of 2 bigger than the bucket ID give us the bucket's
            level.

        Returns
        -------
        :obj:`int`
            The level of the binary tree where the bucket is located.

        """
        return bucket_id.bit_length()

    @cython.cdivision(True)
    cdef tuple _bucket_range(self, uint64_t bucket_id):
        """Compute range in binary parition associated with the bucket.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket ID of the bucket whose sibling is computed.

        Note
        ----
            For full and complete binary tree built from a binary
            partition, every bucket is associated with a sub-range
            of the main range.

            The collection of buckets on each level is the complete
            partition of the initial range. Thus, number of buckets
            on level `k` is `2^{k-1}` and, because IDs of the buckets
            associated from left to right, the position of the bucket
            defined its interval of the partition.

        Returns
        -------
        tuple
            The interval [a, b] associated with the bucket.

        """
        cdef uint8_t level = self._bucket_level(bucket_id)
        cdef uint64_t buckets_on_level = <uint64_t>1 << (level - 1)
        cdef float delta = (self._max_range - self._min_range) / float(buckets_on_level)
        cdef uint32_t bucket_position = bucket_id % buckets_on_level
        return (
            self._min_range + <uint64_t>ceil(delta * bucket_position),
            self._min_range + <uint64_t>floor(delta * (bucket_position + 1))
        )

    @cython.cdivision(True)
    cpdef void add(self, uint32_t element, bint compress=False) except *:
        """Add element into the q-digest.

        Parameters
        ----------
        element : obj
            The input element.
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
            If the value of the element is out of range.

        """
        if element > self._max_range or element < self._min_range:
            raise ValueError("Value out of range")

        cdef uint64_t canonical_bucket_id = self._bucket_canonical_id(element)
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
        """Decide if the family of nodes is worth to be stored.

        Parameters
        ----------
        family_counts : :obj:`int`
            The total counts of the family of nodes: the parent and its
            two children.

        Note
        ----
            If total counts of the family of nodes (parent and 2 children)
            are satisfy the q-digest property, they are worth to be stored.

            Boundary value, used to estimate the significance of the counts
            in the q-digest property, is related to the ratio between
            the number of elements already in the q-digest and the
            current compression factor.

        Returns
        -------
        bool
            True if the family of nodes is worth to be kept in the q-digest,
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

    cdef bint _delete_bucket_if_exists(self, uint64_t bucket_id) except *:
        """Delete bucket from q-digest if it's exists.

        Parameters
        ----------
        bucket_id : :obj:`int`
            The bucket to delete.

        Note
        ----
            Everytime when a bucket is deleted, the number_of_buckets
            in the q-digest has to be decreased.

        Returns
        -------
        bool
            True if the deletion was performed, False otherwise.

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
            families of nodes (a parent and its children) and keep information
            about family counts at the parent node only.

        Returns
        -------
        bool
            True if the node merging was performed, False otherwise.

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

    cpdef void compress(self):
        """Compress q-digest.

        Note
        ----
            The compression of q-digest is made by merge procedure
            (bottom up) according to q-digest property.

        """
        if self._number_of_buckets < 2:
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
            "length: {}"
            ")>"
        ).format(
            self.compression_factor,
            self._min_range, self._max_range,
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
            The number of bytes allocated for the q-digest.

        Note
        ----
            Since we can't calculate exact size of a dict in Cython,
            this function return some estimation based on an ideal
            size of keys, values of each bucket.

        """
        cdef size_t size_of_bucket = sizeof(uint64_t) + sizeof(size_t)
        return self._number_of_buckets * size_of_bucket

    @cython.cdivision(True)
    cpdef uint32_t quantile_query(self, float quantile) except *:
        """Execute quantile query to find the quantile element.

        Parameters
        ----------
        quantile : :obj:`float`
            The fraction from [0, 1].

        Raises
        ------
        ValueError
            If `quantile` outside the expected interval of [0, 1].

        Note
        ----
            Given a fraction `quantile` [0, 1], the quantile query
            is about to find the value whose rank in sorted sequence
            of the `n` values is `quantile * n`.

            To calculate the quantile, the q-digest has to be compressed
            so its buckets have to be sorted in increasing their
            intervals' upper bounds, breaking ties by the putting smaller
            ranges (thus, smaller bucker IDs) first.

            Afterwards, we scan those sorted list and sum counts of
            buckets we have seen until we found some buckets on which
            those counts exceed the rank `quantile * n`. Such bucket
            is reported as the estimate for the requested quantile.

        Returns
        -------
        :obj:`int`
            The estimate of the quantile element from the q-digest.

        """
        if quantile < 0.0 or quantile > 1.0:
            raise ValueError("Quantile has to be in [0, 1] interval")

        cdef list ordered_qdigest = sorted(
            self._qdigest.items(),
            key=self._sortkey_buckets_by_range,
            reverse=True
        )

        cdef float boundary_rank = self.count() * quantile
        cdef size_t rank = 0

        for bucket_id, counts in ordered_qdigest:
            rank += counts
            if rank > boundary_rank:
                break

        cdef uint32_t start, end
        (start, end) = self._bucket_range(bucket_id)
        return end

    @cython.cdivision(True)
    cpdef size_t inverse_quantile_query(self, uint32_t element) except *:
        """Execute inverse quantile query to find the element's rank.

        Parameters
        ----------
        element : obj
            The element whose rank is to be computed.

        Raises
        ------
        ValueError
            If the value of the element is out of range.

        Note
        ----
            Given an element, the inverse quantile query
            is about to find its rank in a sorted sequence of values.

            To calculate the rank, the q-digest has to be compressed
            so its buckets have to be sorted in increasing their
            intervals' upper bounds, breaking ties by the putting smaller
            ranges (thus, smaller bucker IDs) first.

            Afterwards, we scan that sorted list from beginning to the end
            and sum counts of buckets whose interval's upper boundary
            is less than the requested element's value. That sum is reported
            as the estimate for the requested rank of the element.

        Returns
        -------
        :obj:`int`
            The estimate of the element's rank in the q-digest.

        """
        if element > self._max_range or element < self._min_range:
            raise ValueError("Value out of range")

        cdef list ordered_qdigest = sorted(
            self._qdigest.items(),
            key=self._sortkey_buckets_by_range,
            reverse=True
        )

        cdef uint32_t start, end
        cdef size_t rank = 0
        for bucket_id, counts in ordered_qdigest:
            (start, end) = self._bucket_range(bucket_id)
            if element > end:
                rank += counts

        return rank

    cpdef size_t interval_query(self, uint32_t start, uint32_t end) except *:
        """Execute interval query to find number of elements in it.

        Parameters
        ----------
        start : :obj:`int`
            The lower boundary of the interval [a, b].
        end : :obj:`int`
            The upper boundary of the interval [a, b].

        Raises
        ------
        ValueError
            If the upper boundary smaller or equal to the lower boundary.
        ValueError
            If the upper boundary is out of range.
        ValueError
            If the lower boundary is out of range.

        Note
        ----
            Given a value the interval (range) query
            is about to find the number of elements in the given range
            in the sequence of elements.

            To calculate the number of elements, we simply perform two
            inverse quantile queries for lower and upper boundaries
            and report their difference as the estimate for the number
            of elements in the requested interval.

        Returns
        -------
        :obj:`int`
            The number of elements in the given interval in the q-digest.

        """
        if start >= end:
            raise ValueError("Invalid interval")
        if start < self._min_range or start > self._max_range:
            raise ValueError("Interval lower boundary out of range")
        if end < self._min_range or end > self._max_range:
            raise ValueError("Interval upper boundary out of range")

        start_rank = self.inverse_quantile_query(start)
        end_rank = self.inverse_quantile_query(end)

        return end_rank - start_rank

    cpdef void merge(self, QuantileDigest other) except *:
        """Merge q-digest with another similar one.

        Parameters
        ----------
        other : QuantileDigest
            The q-digest to be merged with the current one.

        Raises
        ------
        ValueError
            If the compression factors differ.
        ValueError
            If the ranges differ.

        Note
        -----
            The merge is computing by taking the union of the two q-digest
            and adding the counts of their buckets with the same range.
            Then, the resulting q-digest has to be compressed.

        """
        if other.compression_factor != self.compression_factor:
            raise ValueError("Compression factors have to be equal")
        if other.range_in_bits != self.range_in_bits:
            raise ValueError("Ranges have to be equal")

        for bucket_id, counts in other._qdigest.items():
            if bucket_id in self._qdigest:
                self._qdigest[bucket_id] += counts
            else:
                self._qdigest[bucket_id] = counts

        self._number_of_buckets = len(self._qdigest)
        self._exact_boundary_value = float(self.count()) / self.compression_factor

        self.compress()




