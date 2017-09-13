"""Probabilistic Counter.

Probabilistic Counting algorithms were proposed by Philippe Flajolet
and G. Nigel Martin in 1985.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.

"""
import cython

from libc.math cimport round
from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.stdlib cimport rand

from cpython.array cimport array
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class ProbabilisticCounter:
    """Probabilistic Counter is a realisation of Probabilistic Counting algorithm.

    Example
    -------

    >>> from pdsa.cardinality.probabilsitic_counter import ProbabilisticCounter

    >>> lc = ProbabilisticCounter(5)
    >>> lc.add("hello")
    >>> lc.count()


    Note
    -----
        This implementation uses MurmurHash3 family of hash functions
        which yields a 32-bit hash value that implies the maximal length
        of the counter.

    Attributes
    ----------
    num_of_counters : :obj:`int`
        The number of simple counters.

    """

    def __cinit__(self, const uint16_t num_of_counters):
        """Create probabilsistic counter using `num_of_counters` simple counters.

        Parameters
        ----------
        num_of_counters : :obj:`int`
            The number of simple counters.

        Note
        ----
            The length of the probabilsitic counter is defined by the size of
            hashe values that produced by the family of hash functions
            (in our case it's 32 bits functions)

        Note
        ----
            Memory for the internal array is allocated by blocks
            (or chunks), therefore the final `length` of the counter
            can be rounded up to use whole allocated space efficiently.

        Raises
        ------
        ValueError
            If `num_of_counters` is 0 or negative.

        """
        if num_of_counters < 1:
            raise ValueError("At least one simple counter is required")

        self.num_of_counters = num_of_counters
        self.size = 32  # 32-bit hash functions produce 0..2^{32}-1 values

        self._seeds = array('H', range(self.num_of_counters))
        self._counter = BitVector(self.num_of_counters * self.size)

        self.length = len(self._counter)

        cdef size_t index
        for index in xrange(self.length):
            self._counter[index] = 0

    cdef uint32_t _hash(self, object key, uint32_t seed):
        return mmh3_x86_32bit(key, seed)

    cdef uint8_t _rank(self, uint32_t value):
        """Calculate rank that is the least significant bit position.

        Parameters
        ----------
        value : int
            The unsinged integer to find the LSB in binary representation.

        Returns
        -------
        :obj:`int`
            The LSB or, if value is zero, the `self.size`.

        """
        if value == 0:
            return self.size
        return (value & -value).bit_length() - 1

    def __dealloc__(self):
        pass

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef void add(self, object element) except *:
        """Index element into the counter.

        Parameters
        ----------
        element : obj
            The element to be indexed into the counter.

        """
        cdef uint16_t counter_index
        cdef uint8_t value_index
        cdef uint8_t seed
        for counter_index in xrange(self.num_of_counters):
            seed = self._seeds[counter_index]
            value_index = self._rank(self._hash(element, seed))
            if value_index >= self.size:
                continue
            self._counter[counter_index * self.size + value_index] = 1

    cpdef size_t sizeof(self):
        """Size of the counter in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the counter.

        """
        return self._counter.sizeof()

    def __repr__(self):
        return "<ProbabilisticCounter (length: {}, num_of_counters: {})>".format(
            self.length,
            self.num_of_counters)

    def __len__(self):
        """Get length of the counter.

        Returns
        -------
        :obj:`int`
            The length of the counter.

        """
        return self.length

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef uint8_t _value_by_counter(self, uint16_t counter_index):
        """Get value from a single simple counter.

        The k-th bit in the counter correspods to the 0^{k}1 pattern
        that is used to estimate number of unique elements known
        to the counter. The leftmost 0 in the counter is an indicator
        of log_{2}(n) (in fact, with some correction factor).

        Parameters
        ----------
        counter_index : int
            The index of the counter.

        Returns
        -------
        :obj:`int`
            Relative index of the leftmost value 0 or, if all values
            are zero, the counter's size.

        Note
        ----
            Since all simple counters are stored in a single vector,
            we get counter by its index, and it is `self.size` bits long.
            In this case the returning value is the relative index
            inside that single counter.

        """
        cdef uint8_t value_index
        cdef bint found = False

        for value_index in xrange(self.size):
            if self._counter[counter_index * self.size + value_index] == 0:
                return value_index

        return self.size


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Approximately count number of unique elements indexed into counter.

        Returns
        -------
        :obj:`int`
            The number of unique elements already in the counter.

        Note
        ----
            According to [1], the estimation of cardinality can be computed
            by averaging estimations from each counter and converting
            the result value A into espected number of unique elements by
            formula:

                n ≈ 2^{A} / 0.77351

        References
        ----------
        [1] Flajolet, P., Martin, G.N.: Probabilistic Counting Algorithms
            for Data Base Applications. Journal of Computer and System Sciences.
            Vol. 31 (2), 182--209  (1985)

        The cardinality estimation can be calculated [1] as:


        """
        if self._counter.count() == 0:
            return 0

        cdef uint16_t counter_index
        cdef uint16_t N = 0
        for counter_index in xrange(self.num_of_counters):
            N += self._value_by_counter(counter_index)

        return <size_t>round(
            pow(
                2,
                <uint16_t>(round(float(N) / self.num_of_counters))
            ) / 0.77351
        )
