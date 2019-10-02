"""Random Sampling.

The Random sampling algorithm, often referred to as MRL, was
published by Gurmeet Singh Manku, Sridhar Rajagopalan, and Bruce
Lindsay in 1999 [1] and addressed the problem of the correct
sampling and quantile estimation. It consists of the non-uniform
sampling technique and deterministic quantile finding algorithm.

This implementation of the simpler version of the MRL algorithm
that was proposed by Ge Luo, Lu Wang, Ke Yi, and Graham Cormode
in 2013 [2], [3], and denoted in the original articles as Random.

References
----------
[1] Manku, G., et al: Random sampling techniques for space efficient
    online computation of order statistics of large datasets. Proceedings
    of the 1999 ACM SIGMOD International conference on Management
    of data, Philadelphia, Pennsylvania, USA - May 31–June 03, 1999,
    pp. 251–262, ACM New York, NY (1999)
    http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.86.5750&rep=rep1&type=pdf
[2] Wang, L., et al: Quantiles over data streams: an experimental
    study. Proceedings of the 2013 ACM SIGMOD International
    conference on Management of data, New York, NY, USA - June
    22–27, 2013, 2013, pp. 737–748, ACM New York, NY (2013)
    http://dimacs.rutgers.edu/~graham/pubs/papers/nquantiles.pdf
[3] Luo, G., Wang, L., Yi, K. et al.: Quantiles over data streams:
    experimental comparisons, new analyses, and further improvements.
    The VLDB Journal. Vol. 25 (4), 449–472 (2016)
    http://dimacs.rutgers.edu/~graham/pubs/papers/nquantvldbj.pdf

"""

import cython

from cpython.array cimport array
from random import sample

from libc.math cimport ceil, floor, log, round
from libc.stdint cimport uint64_t, uint32_t, uint16_t, uint8_t, UINT32_MAX
from libc.stdlib cimport rand


cdef class RandomSampling:
    """RandomSampling is a realisation of the Random sampling algorithm.

    Example
    -------

    >>> from pdsa.rank.random_samlping import RandomSampling

    >>> rs = RandomSampling(16, 5, 3)
    >>> rs.add(42)
    >>> rs.inverse_quantile_query(42)

    Attributes
    ----------
    range_in_bits : :obj:`int`
        The maximal supported input non-negative integer values in bits.
    compression_factor : :obj:`int`
        The level of the compression in q-digest.

    """

    def __cinit__(self, const uint8_t number_of_buffers, const uint16_t buffer_capacity,
                  const uint8_t height):
        """Create a number of sample buffer data structures.

        Parameters
        ----------
        number_of_buffers : :obj:`int`
            The number of buffers.
        buffer_capacity : :obj:`int`
            The number of elements that can be stored in a buffer (capacity).
        height : :obj:`int`
            The maximum height of the structure (maximum count of levels).

        Raises
        ------
        ValueError
            If `number_of_buffers` is 1 or negative.
        ValueError
            If `buffer_capacity` is 0 or negative.
        ValueError
            If `height` is 0 or negative.


        Note
        ----
            The height of the data structure is related to the accurancy,
            but bigger values can make it less space-efficient.

        """
        if number_of_buffers < 2:
            raise ValueError("The number of buffers is too small")

        if buffer_capacity < 1:
            raise ValueError("The buffers' capacity is too small")

        self.height = height
        self.number_of_buffers = number_of_buffers
        self.buffer_capacity = buffer_capacity

        self._number_of_elements = 0

        self._length = self.number_of_buffers * self.buffer_capacity
        self._buffer = array('L', [0] * self._length)
        self._element_existance_mask = array('b', [0] * self._length)

        self._buffer_levels = array('I', [0] * self.number_of_buffers)
        self._buffer_emptiness_mask = array('b', [1] * self.number_of_buffers)


    cdef uint8_t _active_level(self):
        """Calculate the active level.

        The size of the chunk is associated with a level parameter
        that defines the probability that elements are drawn and
        depends on the required height and the number of
        processed elements.

        L = L(n, h) = max(0, log(n/(k * 2^{h-1}))), L(0, h) = 0

        Returns
        -------
        :obj:`int`
            The active level number.

        """
        if self._number_of_elements < 1:
            return 0

        cdef uint8_t level = <uint8_t> ceil(
            log(self._number_of_elements) -
            (self.height - 1) -
            log(self.buffer_capacity)
        )
        return max(0, level)

    cdef uint16_t _get_next_empty_buffer_id(self, uint8_t active_level):
        """Find empty buffer at the active level or force collapse."""
        cdef uint16_t index
        for index in xrange(self.number_of_buffers):
            if self._buffer_levels[index] != active_level:
                continue
            if self._buffer_emptiness_mask[index]:
                return index

        self._collapse(active_level)
        return self._get_next_empty_buffer_id(active_level)

    cdef void _collapse(self, uint8_t active_level):
        """Collapse two random non-empty buffers below active level."""
        cdef uint16_t buffer_id_1, buffer_id_2
        cdef uint8_t level

        cdef list indices_of_nonempty
        for level in xrange(active_level):
            indices_of_nonempty = []
            for buffer_id in xrange(self.number_of_buffers):
                if self._buffer_levels[index] != level:
                    continue

                if self._buffer_emptiness_mask[index]:
                    continue

                indices_of_nonempty.append(buffer_id)

            if len(indices_of_nonempty) >= 2:
                break

        try:
            [buffer_id_1, buffer_id_2] = sample(indices_of_nonempty, k=2)
        except ValueError:
            # XXX: number of full buffers is less than 2?
            return

        cdef list candidates
        cdef uint32_t start_index, end_index, index

        start_index = self.buffer_capacity * buffer_id_1
        end_index = start_index + self.buffer_capacity
        for index in xrange(start_index, end_index):
            if not self._element_existance_mask[index]:
                continue

            candidates.append(self._buffer[index])
            self._element_existance_mask[index] = 0

        start_index = self.buffer_capacity * buffer_id_2
        end_index = start_index + self.buffer_capacity
        for index in xrange(start_index, end_index):
            if not self._element_existance_mask[index]:
                continue

            candidates.append(self._buffer[index])
            self._element_existance_mask[index] = 0

        self._buffer_emptiness_mask[buffer_id_1] = 1
        self._buffer_emptiness_mask[buffer_id_2] = 1

        try:
            candidates = sample(candidates, self.buffer_capacity)
        except ValueError:
            # number of candidates is less than required capacity
            pass

        cdef uint32_t element
        for element in candidates:
            self._insert(buffer_id_1, element)

        self._buffer_levels[buffer_id_1] = level + 1

    cdef void _insert(self, uint16_t buffer_id, uint32_t element):
        """Insert element in the buffer."""
        cdef uint32_t start_index, end_index, index

        start_index = self.buffer_capacity * buffer_id
        end_index = start_index + self.buffer_capacity
        for index in range(start_index, end_index):
            if self._element_existance_mask[index]:
                continue

            self._element_existance_mask[index] = 1
            self._buffer[index] = element
            self._buffer_emptiness_mask[buffer_id] = 0
            break

    cpdef void consume(self, dataset):
        """Consume element from potentially unlimited dataset.

        Parameters
        ----------
        dataset : obj
            The data stream wrapped as a generator.

        """
        cdef uint8_t level = self._active_level()
        cdef uint32_t chunk = (<uint32_t>1 << level) - 1

        cdef uint16_t buffer_id = self._get_next_empty_buffer_id(level)

        candidates = []
        try:
            for index in xrange(chunk):
                candidates.append(next(dataset))
                self._number_of_elements += 1
        except StopIteration:
            pass

        if self.buffer_capacity < len(candidates):
            candidates = sample(candidates, k=self.buffer_capacity)

        map(lambda element: self._insert(buffer_id, element), candidates)

    def debug(self):
        """Return sample buffers for debug purposes."""
        return <PyObject*>self._buffers

    def __repr__(self):
        return (
            "<RandomSampling ("
            "height: {}, "
            "buffers: {}, "
            "capacity: {}"
            ")>"
        ).format(
            self.height,
            self.number_of_buffers,
            self.buffer_capacity
        )

    def __len__(self):
        """Get the number of buffers.

        Returns
        -------
        :obj:`int`
            The number of buffers in data structure.

        """
        return self.number_of_buffers

    cpdef size_t sizeof(self):
        """Size of the data structure in bytes.

        Returns
        -------
        :obj:`int`
            The number of bytes allocated for the data structure.

        """
        cdef size_t size = 0

        size += self._length * self._buffer.itemsize
        size += self._length * self._element_existance_mask
        size += self.number_of_buffers * self._buffer_emptiness_mask
        size += self.number_of_buffers * self._buffer_levels

        return size

    cpdef size_t count(self):
        """Get the number of processed elements."""
        return self._number_of_elements

    def __dealloc__(self):
        pass

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

        if self.count() < 1:
            raise ValueError("Cannot estimate quantile for the empty structure")

        cdef float boundary_rank = self.count() * quantile
        cdef size_t rank = 0

        cdef set elements = set()
        for index in xrange(self.number_of_buffers):
            elements |= set(self._buffers[index].elements())

        cdef uint32_t element
        for element in elements:
            rank = self.inverse_quantile_query(element)
            if rank > boundary_rank:
                return element

        return sorted(list(elements))[-1]

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

            To calculate the rank, it is required compute the weighted
            by the layer sum of counts of elements smaller than x for
            each non-empty buffer.

        Returns
        -------
        :obj:`int`
            The estimate of the element's rank in the sample buffers.

        """
        cdef size_t rank = 0
        cdef uint16_t index
        cdef uint8_t level
        cdef uint16_t num_of_smaller_elements = 0
        for index in xrange(self.number_of_buffers):
            if not self._buffers[index].is_full():
                continue

            level = self._buffers[index].get_level()
            num_of_smaller_elements = 0

            for x in list(<uint32_t*>self._buffers[index].elements()):
                if x >= element:
                    continue

                num_of_smaller_elements += 1

            rank += (<uint32_t>1 << level) * num_of_smaller_elements

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