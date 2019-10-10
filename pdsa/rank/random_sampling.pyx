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
from random import seed, sample, randint

from libc.math cimport ceil, floor, log2, sqrt
from libc.stdint cimport uint64_t, uint32_t, uint16_t, uint8_t
from libc.stdlib cimport rand


cdef class _MetaBuffer:
    def __cinit__(self, const uint8_t number_of_buffers,
                  const uint32_t elements_per_buffer):
        """MetaBuffer is a flatten array of buffers with required functionality.

        Parameters
        ----------
        number_of_buffers : :obj:`int`
            The number of buffers.
        elements_per_buffer : :obj:`int`
            The number of elements that can be stored in a buffer (capacity).

        Raises
        ------
        ValueError
            If `number_of_buffers` is 1 or negative.
        ValueError
            If `buffer_capacity` is 0 or negative.

        """
        if number_of_buffers < 2:
            raise ValueError("The number of buffers is too small")

        if elements_per_buffer < 1:
            raise ValueError("The per-buffer capacity is too small")

        self.elements_per_buffer = elements_per_buffer
        self.number_of_buffers = number_of_buffers

        self.length = number_of_buffers * elements_per_buffer

        self._array = array('L', [0] * self.length)
        self._mask = array('b', [0] * self.length)

    cdef size_t sizeof(self):
        """Size of the data structure in bytes.

        Returns
        -------
        :obj:`int`
            The number of bytes allocated for the data structure.

        """
        cdef size_t size = 0
        size += self.length * self._array.itemsize
        size += self.length * self._mask.itemsize

        return size

    cdef tuple location(self, uint8_t buffer_id):
        """Find location of the the corresponsing buffer in the array."""
        cdef uint32_t start_index, end_index

        start_index = self.elements_per_buffer * buffer_id
        end_index = start_index + self.elements_per_buffer
        return (start_index, end_index)

    cdef uint32_t num_of_elements(self, uint8_t buffer_id):
        """Return the number of elements in the corresponding buffer."""
        cdef uint32_t start_index, end_index

        start_index = self.elements_per_buffer * buffer_id
        end_index = start_index + self.elements_per_buffer
        return sum(self._mask[start_index:end_index])

    cdef uint32_t capacity(self, uint8_t buffer_id):
        """Return the available capacity for the corresponding buffer."""
        return self.elements_per_buffer - self.num_of_elements(buffer_id)

    cdef bint is_empty(self, uint8_t buffer_id):
        """Check if the corresponsing buffer is empty."""
        cdef uint32_t start_index, end_index

        start_index = self.elements_per_buffer * buffer_id
        end_index = start_index + self.elements_per_buffer
        return not any(self._mask[start_index:end_index])

    cdef list _retrive_elements(self, uint8_t buffer_id, bint pop=False):
        """Retrive elements from the buffer with/without removal."""
        cdef uint32_t start_index, end_index, index
        start_index, end_index = self.location(buffer_id)

        cdef list elements = []
        for index in xrange(start_index, end_index):
            if not self._mask[index]:
                continue

            elements.append(self._array[index])
            if pop:
                self._mask[index] = 0

        return elements

    cdef list get_elements(self, uint8_t buffer_id):
        """Return elements from the corresponding buffer."""
        return self._retrive_elements(buffer_id, pop=False)

    cdef list pop_elements(self, uint8_t buffer_id):
        """Return and remove elements from the corresponding buffer."""
        return self._retrive_elements(buffer_id, pop=True)

    cdef void populate(self, uint8_t buffer_id, list elements):
        """Add elements into the corresponding buffer."""
        capacity = self.capacity(buffer_id)
        if capacity < len(elements):
            raise ValueError()

        cdef uint32_t start_index, end_index, index
        start_index, end_index = self.location(buffer_id)
        for index in range(start_index, end_index):
            try:
                element = elements.pop()
            except IndexError:
                self._mask[index] = 0
            else:
                self._array[index] = element
                self._mask[index] = 1


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
        height : :obj:`int`
            The maximum height of the structure (maximum count of levels).

    """

    def __cinit__(self, const uint8_t number_of_buffers, const uint32_t buffer_capacity,
                  const uint8_t height):
        """Create a number of sample buffer data structures.

        Parameters
        ----------
        number_of_buffers : :obj:`int`
            The number of buffers.
        buffer_capacity : :obj:`int`
            The number of elements that can be stored in a buffer (capacity).
        height : :obj:`int`
            The maximum height of the structure (forces the max count of levels).

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

        if height < 1:
            raise ValueError("The height is expected bigger or equal to 1")

        self.height = height

        self._number_of_elements = 0
        self._queue = list()

        self._buffer = _MetaBuffer(number_of_buffers, buffer_capacity)
        self._levels = array('I', [0] * self._buffer.number_of_buffers)

        self._seed = <uint32_t>(rand())
        seed(self._seed)

    @classmethod
    def create_from_error(cls, const float error):
        """Create RandomSampling from expected error probability.

        Parameters
        ----------
        error : float
            The false positive probability (0 < error < 1).

        Note
        ----
            The required number of buffers, their capacity and data structure's
            height are calculated to support requested error probability.

        Raises
        ------
        ValueError
            If `error` not in range (0, 1).

        """
        if error <= 0.0000001 or error >= 1:
            raise ValueError("Error rate shell be in [0.0000001, 1)")

        cdef uint8_t param = <uint8_t>ceil(log2(1.0 / error))

        cdef uint8_t height = param
        cdef uint8_t number_of_buffers = height + 1
        cdef uint32_t buffer_capacity = <uint32_t>ceil(sqrt(param) / error)

        return cls(number_of_buffers, buffer_capacity, height)

    cdef uint16_t _active_level(self):
        """Calculate the active level.

        The size of the chunk is associated with a level parameter
        defines the probability that elements are drawn and
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

        cdef float level = ceil(
            log2(self._number_of_elements / self._buffer.elements_per_buffer) -
            self.height + 1
        )

        return <uint16_t>max(0, level)

    cdef uint8_t _find_empty_buffer(self):
        """Find an empty buffer or force the collapse."""
        cdef uint8_t buffer_id

        for buffer_id in xrange(self._buffer.number_of_buffers):
            if self._buffer.is_empty(buffer_id):
                return buffer_id

        self._collapse()
        return self._find_empty_buffer()

    cdef void _collapse(self):
        """Collapse two random non-empty buffers below active level."""
        cdef uint8_t buffer_id, buffer_id_1, buffer_id_2
        cdef uint16_t level, current_level = 0
        cdef bint start_pos = 0

        cdef list nonempty_buffer_ids = []
        cdef uint16_t max_level = max(self._levels)
        for level in xrange(max_level + 1):
            nonempty_buffer_ids = []
            for buffer_id in xrange(self._buffer.number_of_buffers):
                if self._levels[buffer_id] != level:
                    continue

                if self._buffer.is_empty(buffer_id):
                    continue

                nonempty_buffer_ids.append(buffer_id)

            if len(nonempty_buffer_ids) >= 2:
                current_level = level
                break

        assert len(nonempty_buffer_ids) >= 2
        [buffer_id_1, buffer_id_2] = sample(nonempty_buffer_ids, k=2)

        cdef list candidates = list()
        candidates += self._buffer.pop_elements(buffer_id_1)
        candidates += self._buffer.pop_elements(buffer_id_2)
        candidates.sort()

        cdef uint16_t capacity = self._buffer.capacity(buffer_id_1)
        if capacity < len(candidates):
            start_pos = <bint>randint(0, 1)
            candidates = candidates[start_pos::2][:capacity]

        self._buffer.populate(buffer_id_1, candidates)
        self._levels[buffer_id_1] = current_level + 1

    cpdef void add(self, uint32_t element):
        """Add element to the data structure.

        Note
        -----

        We do not add element by element, but instead we accumulate it
        in the queue and flush once it reaches buffer_capacity.

        Parameters
        ----------
        element : obj:`int`
            Element to add into data structure.

        """
        self._queue.append(element)
        self._commit(force=False)

    cdef void _commit(self, bint force=False):
        """Populate queued elements into the data structure.

        Parameters
        ----------
        force : obj:`bool`
            Force to process all queued elements regardless the queue size.

        """
        cdef uint16_t level = self._active_level()
        cdef uint32_t chunk_size = <uint32_t>1 << level

        cdef uint64_t autocommit_size = chunk_size * self._buffer.elements_per_buffer
        cdef uint64_t num_of_candidates = len(self._queue)

        if num_of_candidates < 1:
            return

        if num_of_candidates < autocommit_size and not force:
            return

        candidates = list(self._queue)
        candidates.reverse()

        self._queue = list()

        self._number_of_elements += num_of_candidates

        cdef uint8_t buffer_id = self._find_empty_buffer()
        cdef uint32_t capacity = self._buffer.capacity(buffer_id)

        if capacity < num_of_candidates:
            candidates = sample(candidates, k=capacity)

        self._buffer.populate(buffer_id, candidates)
        self._levels[buffer_id] = level


    def debug(self):
        """Return sample buffers for debug purposes."""
        buffer = []
        for buffer_id in range(self._buffer.number_of_buffers):
            buffer.append(self._buffer.get_elements(buffer_id))
        return list(zip(self._levels, buffer))

    def __repr__(self):
        return (
            "<RandomSampling ("
            "height: {}, "
            "buffers: {}, "
            "capacity: {}"
            ")>"
        ).format(
            self.height,
            self._buffer.number_of_buffers,
            self._buffer.elements_per_buffer
        )

    def __len__(self):
        """Get the number of buffers.

        Returns
        -------
        :obj:`int`
            The number of buffers in data structure.

        """
        return self._buffer.number_of_buffers

    cpdef size_t sizeof(self):
        """Size of the data structure in bytes.

        Returns
        -------
        :obj:`int`
            The number of bytes allocated for the data structure.

        """
        cdef size_t size = self._buffer.sizeof()
        size += self._buffer.number_of_buffers * self._levels.itemsize

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

            We compute rank for all unique elements in the sample buffers
            and report the elements with the closest rank to the boundary
            rank defined as `quantile * n`.

        Returns
        -------
        :obj:`int`
            The estimate of the quantile element.

        """
        if quantile < 0.0 or quantile > 1.0:
            raise ValueError("Quantile has to be in [0, 1] interval")

        if self._number_of_elements < 1:
            raise ValueError("Cannot estimate quantile from an empty structure")

        self._commit(force=True)

        cdef float boundary_rank = self._number_of_elements * quantile
        cdef size_t rank = 0

        cdef list elements = list()
        cdef list ranks = list()

        for buffer_id in xrange(self._buffer.number_of_buffers):
            elements += self._buffer.get_elements(buffer_id)

        elements = list(set(elements))

        cdef uint32_t element
        for element in elements:
            rank = self.inverse_quantile_query(element)
            ranks.append(abs(rank - boundary_rank))

        return elements[ranks.index(min(ranks))]

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

        cdef list elements
        cdef uint32_t num_of_smaller_elements
        cdef uint32_t stored_element
        cdef uint16_t level

        self._commit(force=True)

        for buffer_id in xrange(self._buffer.number_of_buffers):
            if self._buffer.is_empty(buffer_id):
                continue

            num_of_smaller_elements = 0
            elements = self._buffer.get_elements(buffer_id)
            level = self._levels[buffer_id]

            for stored_element in elements:
                if stored_element > element:
                    continue
                num_of_smaller_elements += 1

            rank += (<uint16_t>1 << level) * num_of_smaller_elements

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
            The number of elements in the given interval.

        """
        if start >= end:
            raise ValueError("Invalid interval")

        self._commit(force=True)

        start_rank = self.inverse_quantile_query(start)
        end_rank = self.inverse_quantile_query(end)

        return end_rank - start_rank