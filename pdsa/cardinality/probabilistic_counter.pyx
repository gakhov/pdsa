"""Probabilistic Counter.

Probabilistic Counting algorithms were proposed by Philippe Flajolet
and G. Nigel Martin in 1985.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.

"""
import cython

from libc.math cimport floor
from libc.stdint cimport uint32_t
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
    num_of_hashes : :obj:`int`
        The number of hash functions.

    """

    def __cinit__(self, const uint32_t num_of_hashes):
        """Create counter using `num_of_hashes` hash functions.

        Parameters
        ----------
        num_of_hashes : :obj:`int`
            The number of hash functions.

        Note
        ----
            The length of the counter is defined by the size of
            hashes that produced by the used family of hash functions
            (in our case it's 32 bits functions)

        Note
        ----
            Memory for the internal array is allocated by blocks
            (or chunks), therefore the final `length` of the counter
            can be rounded up to use whole allocated space efficiently.

        Raises
        ------
        ValueError
            If `num_of_hashes` is 0 or negative.

        """
        if num_of_hashes < 1:
            raise ValueError("At least one hash function is required")

        self.num_of_hashes = num_of_hashes
        self.size = 32  # 32-bit hash functions produce 0..2^{32}-1 values

        self._seeds = array('I', range(self.num_of_hashes))

        cdef size_t length = self.num_of_hashes * self.size
        self._counter = BitVector(length)

        self.length = len(self._counter)

        cdef size_t index
        for index in xrange(self.length):
            self._counter[index] = 0

    cdef uint32_t _hash(self, object key, uint32_t seed):
        return mmh3_x86_32bit(key, seed)

    cdef uint32_t _rank(self, uint32_t value):
        """Calculate rank that is the least significant bit position."""
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
        cdef size_t index
        cdef uint32_t value_index
        cdef uint32_t counter_index
        for counter_index in xrange(self.num_of_hashes):
            seed = self._seeds[counter_index]
            value_index = self._rank(self._hash(element, seed))
            index = counter_index * self.size + value_index
            self._counter[index] = 1

    cpdef size_t sizeof(self):
        """Size of the counter in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the counter.

        """
        return self._counter.sizeof()

    def __repr__(self):
        return "<ProbabilisticCounter (length: {}, num_of_hashes: {})>".format(
            self.length,
            self.num_of_hashes)

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
    cdef size_t _count_by_counter(self, uint32_t counter_index):
        """Calculate cardinality estimiation by a single counter.

        The k-th bit in the counter correspods to the 0{k}1 pattern
        that is used to estimate number of unique elements known
        to the counter. The leftmost 0 in the counter is an indicator
        of log_{2}(n).

        The cardinality estimation can be calculated [1] as:

            n ≈ 2^{k} / 0.77351

        Note
        ----
            Since all counters are stored in a single vector,
            we get counter by its index and it's self.size bits long.
            In this case the index k is the relative index inside
            that single counter.

        References
        ----------
        [1] Flajolet, P., Martin, G.N.: Probabilistic Counting Algorithms
            for Data Base Applications. Journal of Computer and System Sciences.
            Vol. 31 (2), 182--209  (1985)

        """
        cdef size_t index
        cdef uint32_t k
        cdef bint found = False

        for index in xrange(self.size):
            if self._counter[counter_index * self.size + index] == 0:
                k = index
                found = True
                break

        if not found:
            k = self.size

        return <size_t>floor(pow(2, k) / 0.77351)


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
            by averaging estimations from each counter.

        References
        ----------
        [1] Flajolet, P., Martin, G.N.: Probabilistic Counting Algorithms
            for Data Base Applications. Journal of Computer and System Sciences.
            Vol. 31 (2), 182--209  (1985)

        """
        cdef uint32_t counter_index
        cdef float N = 0
        for counter_index in xrange(self.num_of_hashes):
            print(self._count_by_counter(self._counter[counter_index]))
            N += self._count_by_counter(self._counter[counter_index])/ float(self.num_of_hashes)

        return <size_t>(floor(N))
